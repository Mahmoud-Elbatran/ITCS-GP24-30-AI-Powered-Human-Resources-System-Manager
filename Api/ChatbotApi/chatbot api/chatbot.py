from langchain_ollama import ChatOllama
from langchain_core.runnables import RunnablePassthrough
from langchain.prompts import ChatPromptTemplate
from langchain.retrievers.multi_query import MultiQueryRetriever
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import OllamaEmbeddings

# Load your existing vector DB and model
embedModel = 'nomic-embed-text:latest'
llmModel = 'llama3.2:latest'
persist_directory = "E:\\NU CS\Spring- 2025 Courses\\CSCI496 Senior Project Il\\chatbot\\LLM HR V1\\chroma_db"

model = ChatOllama(model=llmModel)
vectorDB = Chroma(
    persist_directory=persist_directory,
    embedding_function=OllamaEmbeddings(model=embedModel)
)

prompt_template = """First try to answer the question based ONLY on the following context:
{context} 
Question: {question} 
If you cannot answer, then use LLM knowledge to help."""

prompt = ChatPromptTemplate.from_template(prompt_template)

retriever = MultiQueryRetriever.from_llm(
    llm=model,
    retriever=vectorDB.as_retriever(),
    prompt=prompt
)

chain = (
    {'context': retriever, 'question': RunnablePassthrough()}
    | prompt
    | model
)

def get_chat_response(question: str) -> str:
    return chain.invoke({"question": question}).content

