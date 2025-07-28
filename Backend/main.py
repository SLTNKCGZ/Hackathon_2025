from fastapi import FastAPI

from database import Base, engine
from routers import auth, lesson

app = FastAPI()
app.include_router(auth.router)
app.include_router(lesson.router)
Base.metadata.create_all(bind=engine)
