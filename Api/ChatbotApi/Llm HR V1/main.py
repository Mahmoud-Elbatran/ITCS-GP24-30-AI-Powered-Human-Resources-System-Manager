from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from langchain_ollama import OllamaEmbeddings, OllamaLLM
from langchain_chroma import Chroma
from langchain.chains import RetrievalQA
from langchain.document_loaders import PyPDFLoader
from langchain.text_splitter import CharacterTextSplitter

app = FastAPI()

# CORS for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to your frontend URL if needed
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Globals
PERSIST_DIRECTORY = "chroma_store"
PDF_PATH = "hrppm_printable_042715.pdf"

@app.on_event("startup")
async def startup_event():
    print("📄 Loading PDF...")
    loader = PyPDFLoader(PDF_PATH)
    documents = loader.load()
    print("✂️ Splitting text...")
    splitter = CharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
    docs = splitter.split_documents(documents)

    print("🔎 Creating embeddings...")
    embeddings = OllamaEmbeddings(model="nomic-embed-text")

    print("🗂️ Creating Chroma vectorstore...")
    global qa_chain
    vectorstore = Chroma.from_documents(
        documents=docs,
        embedding=embeddings,
        persist_directory=PERSIST_DIRECTORY
    )

    llm = OllamaLLM(model="llama3")
    qa_chain = RetrievalQA.from_chain_type(
        llm=llm,
        retriever=vectorstore.as_retriever()
    )
    print("✅ QA system initialized.")

@app.post("/ask")
async def ask_question(request: Request):
    data = await request.json()
    question = data.get("query")
    if not question:
        return {"error": "No query provided."}
    print(f"❓ Received question: {question}")
    result = qa_chain.run(question)
    print(f"✅ Answer: {result}")
    return {"query": question, "result": result}
