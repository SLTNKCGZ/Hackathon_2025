from fastapi import FastAPI,APIRouter,HTTPException

from database import Base, engine
from routers import auth

app = FastAPI()
app.include_router(auth.router)
Base.metadata.create_all(bind=engine)
