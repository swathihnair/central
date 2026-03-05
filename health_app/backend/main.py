from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import uvicorn
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(title="Health App API")

# Allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount uploads directory
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Create database tables
from database import engine, Base
import sql_models
Base.metadata.create_all(bind=engine)

@app.get("/")
async def root():
    return {"message": "Health App API is running. Welcome!"}

# Import routers
from routers import auth, ai, reports, appointments, users, rfid, rfid_websocket, availability

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(ai.router, prefix="/api/ai", tags=["AI"])
app.include_router(reports.router, prefix="/api/reports", tags=["Reports"])
app.include_router(appointments.router, prefix="/api/appointments", tags=["Appointments"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(rfid.router, prefix="/api/rfid", tags=["RFID"])
app.include_router(rfid_websocket.router, prefix="/api", tags=["RFID WebSocket"])
app.include_router(availability.router, prefix="/api/availability", tags=["Doctor Availability"])

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
