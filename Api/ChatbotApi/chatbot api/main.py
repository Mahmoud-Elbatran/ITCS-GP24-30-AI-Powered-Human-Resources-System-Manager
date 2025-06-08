from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
# import firebase_admin
# from firebase_admin import credentials, firestore
from chatbot import get_chat_response

# # Firebase initialization
# cred = credentials.Certificate("firebase_config.json")
# firebase_admin.initialize_app(cred)
# db = firestore.client()

app = FastAPI()

class ChatRequest(BaseModel):
    user_id: str
    question: str

class ChatResponse(BaseModel):
    answer: str
    timestamp: str

@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    try:
        answer = get_chat_response(req.question)

        # # Store in Firestore (commented out)
        # doc_ref = db.collection('users').document(req.user_id).collection('chats').document()
        timestamp = datetime.utcnow()
        # doc_ref.set({
        #     'question': req.question,
        #     'answer': answer,
        #     'timestamp': timestamp
        # })

        return ChatResponse(answer=answer, timestamp=timestamp.isoformat())

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

from typing import List

class ChatHistoryItem(BaseModel):
    question: str
    answer: str
    timestamp: str

@app.get("/history/{user_id}", response_model=List[ChatHistoryItem])
async def get_chat_history(user_id: str):
    try:
        # # Firestore fetching commented out
        # chat_ref = db.collection('users').document(user_id).collection('chats')
        # docs = chat_ref.order_by('timestamp', direction=firestore.Query.DESCENDING).stream()

        # Mocked empty chat history for testing
        docs = []

        history = []
        for doc in docs:
            data = doc.to_dict()
            history.append(ChatHistoryItem(
                question=data.get('question', ''),
                answer=data.get('answer', ''),
                timestamp=data.get('timestamp').isoformat() if data.get('timestamp') else ''
            ))

        return history
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
