import os
import uuid
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from pydantic import BaseModel
from starlette import status

from database import SessionLocal
from models import Note, NoteTerm, NoteLesson, User
from routers.auth import get_current_user, db_dependency

router = APIRouter(
    prefix="/notes",
    tags=["Notes"]
)

user_dependency = Annotated[dict, Depends(get_current_user)]

# Response modeli
class NoteResponse(BaseModel):
    id: int
    content: str
    term_id: int
    lesson_id: int


@router.post("/create")
async def create_note(
    user: user_dependency,
    db: db_dependency,
    content: str = Form(..., description="Note içeriği (zorunlu)"),
    lesson_id: int = Form(..., description="Lesson ID (zorunlu)"),
    term_id: int = Form(..., description="Term ID (zorunlu)"),
):

    
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    user_obj=db.query(User).filter(User.id==user.get("id")).first()
    if user_obj is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="User not found")

    # Lesson kontrolü
    lesson = db.query(NoteLesson).filter(
        NoteLesson.id == lesson_id,
        NoteLesson.user_id == user_obj.id
    ).first()

    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")

    # Term kontrolü
    term = db.query(NoteTerm).filter(
        NoteTerm.id == term_id,
        NoteTerm.n_lesson_id == lesson.id
    ).first()

    if term is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term not found")

    # Note oluştur
    note = Note(
        content=content,
        term_id=term_id
    )
    
    db.add(note)
    db.commit()
    db.refresh(note)
    
    return NoteResponse(
        id=note.id,
        content=note.content,
        term_id=note.term_id,
        lesson_id=lesson.id
    )


@router.get("/{lesson_id}/{term_id}")
async def get_notes_by_lesson_term(
    lesson_id: int,
    term_id: int,
    user: Annotated[dict, Depends(get_current_user)] = None,
    db: db_dependency = None
):
    """Belirli lesson ve term'e ait note'ları getirir"""
    
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    # Lesson kontrolü
    lesson = db.query(NoteLesson).filter(
        NoteLesson.id == lesson_id,
        NoteLesson.user_id == user.get("id")
    ).first()
    
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson bulunamadı")
    
    # Term kontrolü
    term = db.query(NoteTerm).filter(
        NoteTerm.id == term_id,
        NoteTerm.n_lesson_id == lesson.id
    ).first()
    
    if not term:
        raise HTTPException(status_code=404, detail="Term bulunamadı")
    
    # Note'ları getir ve sırala
    notes = db.query(Note).filter(Note.term_id == term_id).order_by(Note.id).all()
    
    return [
        NoteResponse(
            id=n.id,
            content=n.content,
            term_id=n.term_id,
            lesson_id=lesson.id
        ) for n in notes
    ]


@router.put("/{note_id}")
async def update_note(
    note_id: int,
    user: user_dependency,
    db: db_dependency,
    content: str = Form(..., description="Yeni note içeriği"),
):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    db_user=db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    note = db.query(Note).join(NoteTerm).join(NoteLesson).filter(
        Note.id == note_id,
        NoteLesson.user_id == db_user.id
    ).first()
    
    if not note:
        raise HTTPException(status_code=404, detail="Note bulunamadı")
    

    note.content = content
    
    db.commit()
    db.refresh(note)
    
    return NoteResponse(
        id=note.id,
        content=note.content,
        term_id=note.term_id,
        lesson_id=note.term.n_lesson_id
    )

@router.delete("/{note_id}")
async def delete_note(
    note_id: int,
    user: Annotated[dict, Depends(get_current_user)] = None,
    db: db_dependency = None
):

    
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    

    note = db.query(Note).join(NoteTerm).join(NoteLesson).filter(
        Note.id == note_id,
        NoteLesson.user_id == user.get("id")
    ).first()
    
    if not note:
        raise HTTPException(status_code=404, detail="Note bulunamadı")
    
    db.delete(note)
    db.commit()
    
    return {"message": "Note başarıyla silindi"}

@router.get("/statistics")
async def get_note_statistics(
    user: Annotated[dict, Depends(get_current_user)] = None,
    db: db_dependency = None
):
    """Kullanıcının note istatistiklerini döndürür"""
    
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    # Kullanıcının lesson'larını al
    user_lessons = db.query(NoteLesson).filter(
        NoteLesson.user_id == user.get("id")
    ).all()
    
    lesson_ids = [lesson.id for lesson in user_lessons]
    
    # Bu lesson'lara ait term'leri al
    terms = db.query(NoteTerm).filter(NoteTerm.n_lesson_id.in_(lesson_ids)).all()
    term_ids = [term.id for term in terms]
    
    # İstatistikleri hesapla
    total_notes = db.query(Note).filter(Note.term_id.in_(term_ids)).count()
    
    return {
        "total_notes": total_notes,
        "total_lessons": len(user_lessons),
        "total_terms": len(terms)
    }
