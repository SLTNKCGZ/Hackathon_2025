from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from starlette import status
from models import User, QuestionLesson, NoteLesson
from routers.auth import get_current_user, db_dependency

router = APIRouter(
    prefix="/lesson",
    tags=["Lesson"]
)
user_dependency = Annotated[dict, Depends(get_current_user)]


class LessonResponse(BaseModel):
    id: int
    lesson_title: str
    user_id: int


@router.get("/QuestionLessons")
def get_question_lessons(user: user_dependency, db: db_dependency):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    lessons = db.query(QuestionLesson).filter(QuestionLesson.user_id == db_user.id).order_by(QuestionLesson.id).all()
    return [
        LessonResponse(
            id=l.id,
            user_id=db_user.id,
            lesson_title=l.lesson_title
        ) for l in lessons
    ]


@router.get("/NoteLessons")
def get_note_lessons(user: user_dependency, db: db_dependency):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    return [n_lesson.lesson_title for n_lesson in db_user.n_lessons]


class LessonRequest(BaseModel):
    lesson_title: str


@router.post("/QuestionLesson/create")
def create_question_lesson(lesson: LessonRequest, user: user_dependency, db: db_dependency):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    existing_lesson = db.query(QuestionLesson).filter(
        QuestionLesson.lesson_title == lesson.lesson_title,
        QuestionLesson.user_id == db_user.id
    ).first()

    if existing_lesson:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="QLesson already exists")

    question_lesson = QuestionLesson(lesson_title=lesson.lesson_title, user_id=db_user.id)
    db.add(question_lesson)
    db.commit()
    db.refresh(question_lesson)
    return question_lesson


@router.post("/NoteLesson/create")
def create_note_lesson(lesson: LessonRequest, user: user_dependency, db: db_dependency):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    existing_note_lesson = db.query(NoteLesson).filter(
        NoteLesson.lesson_title == lesson.lesson_title,
        NoteLesson.user_id == db_user.id
    ).first()

    if existing_note_lesson:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="NoteLesson already exists")

    note_lesson = NoteLesson(lesson_title=lesson.lesson_title, user_id=db_user.id)
    db.add(note_lesson)
    db.commit()
    db.refresh(note_lesson)
    return note_lesson


@router.put("/QuestionLesson/update/{q_id}")
def update_question_lesson(db: db_dependency, user: user_dependency, lesson: LessonRequest, q_id: int):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    db_lesson = db.query(QuestionLesson).filter(QuestionLesson.id == q_id).first()
    if db_lesson is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Question not found")

    db.delete(db_lesson)
    new_lesson = QuestionLesson(
        lesson_title=lesson.lesson_title,
        user_id=db_user.id
    )
    db.add(new_lesson)
    db.commit()
    db.refresh(new_lesson)
    return new_lesson


@router.put("/NoteLesson/update/{n_id}")
def update_note_lesson(db: db_dependency, user: user_dependency, lesson: LessonRequest, n_id: int):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    db_lesson = db.query(NoteLesson).filter(NoteLesson.id == n_id).first()
    if db_lesson is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Question not found")

    db.delete(db_lesson)
    new_lesson = NoteLesson(
        lesson_title=lesson.lesson_title,
        user_id=db_user.id
    )
    db.add(new_lesson)
    db.commit()
    db.refresh(new_lesson)
    return new_lesson


@router.delete("/QuestionLesson/delete/{q_id}")
def delete_question_lesson(db: db_dependency, user: user_dependency, q_id: int):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    lesson = db.query(QuestionLesson).filter(QuestionLesson.id == q_id).first()
    if lesson is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Question not found")
    db.delete(lesson)
    db.commit()
    return {"detail": "Lesson deleted"}


@router.delete("/NoteLesson/delete/{n_id}")
def delete_note_lesson(db: db_dependency, user: user_dependency, n_id: int):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    lesson = db.query(NoteLesson).filter(NoteLesson.id == n_id).first()

    if lesson is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Question not found")
    db.delete(lesson)
    db.commit()
    return {"detail": "Lesson deleted"}
