import os
import ollama
import shutil
import time
import streamlit as st
from langchain_ollama import ChatOllama
from langchain_community.vectorstores import Chroma
from langchain.schema import Document
from langchain.prompts import ChatPromptTemplate, PromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain.retrievers.multi_query import MultiQueryRetriever
from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import OllamaEmbeddings

# Source directory and model configuration
sourceDirectory = "C:\Users\Dell\Downloads\chatbot\chatbot\Llm HR V1\test3.py"
embedModel = 'nomic-embed-text:latest'
llmModel = 'llama3.2:latest'

# Specify the directory to store the Chroma database
db_path = './chroma_db'
if os.path.exists(db_path):
    shutil.rmtree(db_path)  # Remove the directory to start fresh

# Retry logic for Ollama API with backoff
def retry_request(prompt, model, retries=3, delay=5):
    for attempt in range(retries):
        try:
            embedding = ollama.embeddings(model=model, prompt=prompt)
            return embedding
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(delay)  # Wait before retrying
            else:
                st.error(f"Error generating embedding after {retries} attempts: {str(e)}")
                return None

# Function to load documents with error handling
def load_documents():
    pageList = []
    fileNames = os.listdir(sourceDirectory)
    for file in fileNames:
        filePath = os.path.join(sourceDirectory, file)

        # Process PDF files
        if file.endswith('.pdf'):
            try:
                loader = PyPDFLoader(file_path=filePath)
                pages = loader.load()
                pageList.extend(pages)
            except Exception as e:
                st.error(f"Error processing PDF file {file}: {str(e)}")

        # Process TXT files
        elif file.endswith('.txt'):
            try:
                with open(filePath, 'r', encoding='utf-8') as txt_file:
                    text = txt_file.read()
                    pageList.append(Document(page_content=text, metadata={"source": file}))
            except Exception as e:
                st.error(f"Error processing TXT file {file}: {str(e)}")
    return pageList

# Initialize text splitter
textSplitter = RecursiveCharacterTextSplitter(chunk_size=200, chunk_overlap=20, add_start_index=True)

# Function to safely delete Chroma database folder with retries
def safe_delete_chroma_db(db_path, retries=3, delay=5):
    for attempt in range(retries):
        try:
            shutil.rmtree(db_path)  # Delete the existing database folder
            print(f"Deleted existing Chroma database at {db_path}")
            return True
        except PermissionError as e:
            if attempt < retries - 1:
                print(f"Attempt {attempt + 1}: Permission error - waiting to retry...")
                time.sleep(delay)  # Wait before retrying
            else:
                st.error(f"Error deleting Chroma database after {retries} attempts: {str(e)}")
                return False
    return False

# Function to split and create embeddings with retry logic
def process_documents(pageList):
    textSplits = []
    textSplitsMetaData = []
    
    for page in pageList:
        split = textSplitter.split_text(page.page_content)
        textSplits.extend(split)
        PM = page.metadata
        for i in range(len(split)):
            textSplitsMetaData.append(PM)
    
    # Use retry_request for generating embeddings
    embeddings = []
    for split in textSplits:
        embedding = retry_request(prompt=split, model=embedModel)
        if embedding:
            embeddings.append(embedding)
    
    DocumentObjectList = [Document(page_content=split, metadata=metadata) for split, metadata in zip(textSplits, textSplitsMetaData)]
    
    # Clear any existing Chroma database before reinitializing
    if os.path.exists(db_path):
        safe_delete_chroma_db(db_path)  # Safe deletion with retries
    
    # Reinitialize Chroma with the new documents and embeddings
    vectorDataBase = Chroma.from_documents(
        documents=DocumentObjectList,
        embedding=OllamaEmbeddings(model=embedModel, show_progress=True),
        persist_directory=db_path  # Specify the directory for the Chroma DB
    )
    
    return vectorDataBase

# Function to get responses from the model
def get_response(question, retriever):
    model = ChatOllama(model=llmModel)
    
    queryPrompt = PromptTemplate(
        input_variables=['question'],
        template="""You are an AI language model assistant. Your task is to generate different versions of the given user question to retrieve relevant documents from a vector database. By generating multiple perspectives on the user question, your goal is to help the user overcome some of the limitations of the distance-based similarity search. Provide these alternative questions separated by newlines.
        Original question: {question}"""
    )
    
    retriever = MultiQueryRetriever.from_llm(
        llm=model,
        retriever=retriever.as_retriever(),
        prompt=queryPrompt
    )

    templateRAG = """First try to answer the question based ONLY on the following context:
    {context} 
    Question: {question} 
    If you cannot answer, then use LLM knowledge to help."""
    
    prompt = ChatPromptTemplate.from_template(templateRAG)
    
    # Create a processing chain with the retriever and model
    chain = (
        {'context': retriever, 'question': RunnablePassthrough() }
        | prompt
        | model
    )
    
    # Execute the chain to generate the response
    try:
        response = chain.invoke(question)
        return response.content
    except Exception as e:
        st.error(f"Error generating response: {str(e)}")
        return None

# Streamlit UI
st.title("Rebota")

# Load documents
pageList = load_documents()
vectorDataBase = process_documents(pageList)

# User query input
question = st.text_input("Ask a question:")

if question:
    response = get_response(question, vectorDataBase)
    if response:
        st.write(response)
