from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv

from database import Base, engine
from routers import auth, lesson, question, term, note

# Load environment variables
load_dotenv()

app = FastAPI()

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Upload klasörü oluştur
UPLOAD_DIR = "uploads"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

# Static dosya servisi
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Google AI API Key
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

app.include_router(auth.router)
app.include_router(lesson.router)
app.include_router(question.router)
app.include_router(term.router)
app.include_router(note.router)

Base.metadata.create_all(bind=engine)
