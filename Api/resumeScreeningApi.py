import os
import re
import tempfile
from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse
from typing import List
from sklearn.metrics.pairwise import cosine_similarity
from langchain_ollama import ChatOllama
from langchain_community.embeddings import OllamaEmbeddings
from PyPDF2 import PdfReader
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Resume Matcher API")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all origins, or put your Flutter app origin here
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Models
EMBED_MODEL = 'nomic-embed-text:latest'
LLM_MODEL = 'llama3.2:latest'

llm = ChatOllama(model=LLM_MODEL)
embed = OllamaEmbeddings(model=EMBED_MODEL)

# --- Utility Functions ---
def extract_text(file: UploadFile) -> str:
    if file.content_type == 'application/pdf':
        pdf = PdfReader(file.file)
        return "\n".join(page.extract_text() or "" for page in pdf.pages)
    elif file.content_type == 'text/plain':
        return file.file.read().decode('utf-8')
    return ""

def extract_job_requirements(job_text: str) -> str:
    prompt = f"""
    Analyze the following job description and extract the key requirements in structured bullet points.

    Job Description:
    {job_text}
    """
    response = llm.invoke(prompt)
    return response.content

def generate_resume_feedback(resume_text: str, job_requirements: str) -> str:
    prompt = f"""
    Compare the following resume to the job requirements and give a detailed assessment of how well it matches.

    Job Requirements:
    {job_requirements}

    Resume:
    {resume_text}

    Provide:
    - A short summary of the candidate's fit
    - Match highlights (skills, experience)
    - Missing qualifications (if any)
    - Suggested improvements
    - A score out of 100 for match quality
    """
    response = llm.invoke(prompt)
    return response.content

def extract_score(feedback: str) -> float:
    match = re.search(r"score.*?(\d{1,3})", feedback, re.IGNORECASE)
    return float(match.group(1)) if match else 50.0

# --- API Endpoint ---
@app.post("/match-resumes/")
async def match_resumes(
    job_file: UploadFile = File(...),
    resumes: List[UploadFile] = File(...)
):
    job_text = extract_text(job_file)
    resume_texts = [extract_text(resume) for resume in resumes]
    resume_names = [resume.filename for resume in resumes]

    # Get embeddings
    job_embed = embed.embed_query(job_text)
    resume_embeds = [embed.embed_query(text) for text in resume_texts]
    embedding_scores = [cosine_similarity([job_embed], [res])[0][0] for res in resume_embeds]
    embedding_percentages = [score * 100 for score in embedding_scores]

    # Extract requirements
    job_requirements = extract_job_requirements(job_text)

    feedbacks = []
    llm_scores = []
    final_scores = []

    for i, resume_text in enumerate(resume_texts):
        feedback = generate_resume_feedback(resume_text, job_requirements)
        feedbacks.append(feedback)

        llm_score = extract_score(feedback)
        llm_scores.append(llm_score)

        combined_score = 0.7 * embedding_percentages[i] + 0.3 * llm_score
        final_scores.append(combined_score)

    ranked_results = sorted(
        zip(resume_names, final_scores, feedbacks),
        key=lambda x: x[1],
        reverse=True
    )

    results = [
        {
            "rank": i + 1,
            "resume_name": name,
            "match_score": round(score, 2),
            "feedback": feedback
        }
        for i, (name, score, feedback) in enumerate(ranked_results)
    ]

    return JSONResponse(content={
        "job_requirements": job_requirements,
        "results": results
    })
