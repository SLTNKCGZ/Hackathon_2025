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
    q_terms=relationship("QuestionTerm",back_populates="q_lesson",cascade="all, delete-orphan")


class NoteLesson(Base):
    __tablename__ = 'note_lessons'
    id = Column(Integer, primary_key=True)
    lesson_title=Column(String)
    user_id = Column(Integer, ForeignKey('users.id'))
    user=relationship("User",back_populates="n_lessons")
    n_terms = relationship("NoteTerm", back_populates="n_lesson", cascade="all, delete-orphan")

class QuestionTerm(Base):
    __tablename__ = 'question_terms'
    id = Column(Integer, primary_key=True)
    term_title=Column(String)
    q_lesson_id = Column(Integer, ForeignKey('question_lessons.id'))
    q_lesson=relationship("QuestionLesson",back_populates="q_terms")
    questions=relationship("Question",back_populates="term",cascade="all, delete-orphan")

class NoteTerm(Base):
    __tablename__ = 'note_terms'
    id = Column(Integer, primary_key=True)
    term_title=Column(String)
    n_lesson_id = Column(Integer, ForeignKey('note_lessons.id'))
    n_lesson=relationship("NoteLesson",back_populates="n_terms")
    notes=relationship("Note",back_populates="term",cascade="all, delete-orphan")

class Question(Base):
    __tablename__ = 'questions'
    id = Column(Integer, primary_key=True)
    image_path = Column(String, nullable=False)
    note = Column(String, nullable=True)
    difficulty_category = Column(Integer, nullable=False)
    term_id = Column(Integer, ForeignKey('question_terms.id'))
    term = relationship("QuestionTerm",back_populates="questions")

class Note(Base):
    __tablename__ = 'notes'
    id = Column(Integer, primary_key=True)
    content = Column(String)
    term_id = Column(Integer, ForeignKey('note_terms.id'))
    term=relationship("NoteTerm",back_populates="notes")