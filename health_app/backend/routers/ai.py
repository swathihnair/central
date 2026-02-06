
from fastapi import APIRouter, HTTPException
import google.generativeai as genai
import os
from pydantic import BaseModel

router = APIRouter()

# Configure Gemini (Mock key for safety if not provided, but code assumes Env Var)
# In a real scenario, the user MUST provide their API key in .env or I can't call it.
# I will add a safe check.

class ChatRequest(BaseModel):
    message: str
    history: list = []

@router.post("/chat")
async def chat_with_doctor_ai(request: ChatRequest):
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return {
            "response": "I'm sorry, but my brain (API Key) is missing. Please contact the administrator to set up the Gemini API Key."
        }
    
    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-pro')
        
        # Simple context prompt
        system_prompt = "You are a helpful and empathetic AI medical assistant. You answer health-related questions concisely. You are not a real doctor, so advise seeing a professional for serious issues."
        
        # Prepare valid history for Gemini if needed, or just send the prompt
        # For simplicity in this demo, we'll just send the current message with system context
        full_prompt = f"{system_prompt}\n\nUser: {request.message}\nAI:"
        
        response = model.generate_content(full_prompt)
        return {"response": response.text}
    except Exception as e:
        print(f"Gemini Error: {e}")
        return {"response": "I'm having trouble connecting to my medical database right now. Please try again later."}
