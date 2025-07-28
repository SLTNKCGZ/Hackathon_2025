from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from database import Base


class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True)
    hashed_password = Column(String)
    email = Column(String,unique=True)
    firstName = Column(String)
    lastName = Column(String)
    q_lessons=relationship("QuestionLesson",back_populates="user",cascade="all, delete-orphan")
    n_lessons=relationship("NoteLesson",back_populates="user",cascade="all, delete-orphan")

class QuestionLesson(Base):
    __tablename__ = 'question_lessons'
    id = Column(Integer, primary_key=True)
    lesson_title=Column(String)
    user_id = Column(Integer, ForeignKey('users.id'))
    user=relationship("User",back_populates="q_lessons")

class NoteLesson(Base):
    __tablename__ = 'note_lessons'
    id = Column(Integer, primary_key=True)
    lesson_title=Column(String)
    user_id = Column(Integer, ForeignKey('users.id'))
    user=relationship("User",back_populates="n_lessons")

