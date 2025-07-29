from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from starlette import status
from models import User, QuestionTerm, NoteTerm, QuestionLesson, NoteLesson
from routers.auth import get_current_user, db_dependency

router = APIRouter(
    prefix="/term",
    tags=["Term"]
)

user_dependency = Annotated[dict, Depends(get_current_user)]

# ===== QUESTION TERM ENDPOINT'LERİ =====

@router.get("/QuestionTerms/{lesson_id}")
def get_question_terms(lesson_id: int, user: user_dependency, db: db_dependency):
    """Belirli bir lesson'a ait question term'lerini getirir"""
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")

    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")

    # Lesson'ın kullanıcıya ait olduğunu kontrol et
    lesson = db.query(QuestionLesson).filter(
        QuestionLesson.id == lesson_id,
        QuestionLesson.user_id == db_user.id
    ).first()
    
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson bulunamadı")

    return [{"id": term.id, "title": term.term_title} for term in lesson.q_terms]

@router.get("/NoteTerms/{lesson_id}")
def get_note_terms(lesson_id: int, user: user_dependency, db: db_dependency):
    """Belirli bir lesson'a ait note term'lerini getirir"""
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")

    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")

    # Lesson'ın kullanıcıya ait olduğunu kontrol et
    lesson = db.query(NoteLesson).filter(
        NoteLesson.id == lesson_id,
        NoteLesson.user_id == db_user.id
    ).first()
    
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson bulunamadı")

    return [{"id": term.id, "title": term.term_title} for term in lesson.n_terms]

# ===== REQUEST MODELLERİ =====

class TermRequest(BaseModel):
    term_title: str

class TermResponse(BaseModel):
    id: int
    term_title: str
    lesson_id: int



@router.post("/QuestionTerm/create/{lesson_id}")
def create_question_term(
    lesson_id: int, 
    term: TermRequest, 
    user: user_dependency, 
    db: db_dependency
):

    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")


    lesson = db.query(QuestionLesson).filter(
        QuestionLesson.id == lesson_id,
        QuestionLesson.user_id == db_user.id
    ).first()
    
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson bulunamadı")

    question_term = QuestionTerm(
        term_title=term.term_title,
        q_lesson_id=lesson.id
    )
    if question_term:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="QuestionTerm is already exist")
    db.add(question_term)
    db.commit()
    db.refresh(question_term)
    
    return TermResponse(
        id=question_term.id,
        term_title=question_term.term_title,
        lesson_id=lesson.id
    )

# ===== NOTE TERM OLUŞTURMA =====

@router.post("/NoteTerm/create/{lesson_id}")
def create_note_term(
    lesson_id: int, 
    term: TermRequest, 
    user: user_dependency, 
    db: db_dependency
):
    """Note term oluşturur"""
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")

    # Lesson'ın kullanıcıya ait olduğunu kontrol et
    lesson = db.query(NoteLesson).filter(
        NoteLesson.id == lesson_id,
        NoteLesson.user_id == db_user.id
    ).first()
    
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson bulunamadı")

    note_term = NoteTerm(
        term_title=term.term_title,
        n_lesson_id=lesson.id
    )
    if note_term:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="NoteTerm is already exist")
    db.add(note_term)
    db.commit()
    db.refresh(note_term)
    
    return TermResponse(
        id=note_term.id,
        term_title=note_term.term_title,
        lesson_id=lesson.id
    )

# ===== QUESTION TERM GÜNCELLEME =====

@router.put("/QuestionTerm/update/{term_id}")
def update_question_term(
    term_id: int,
    term: TermRequest,
    user: user_dependency,
    db: db_dependency
):
    """Question term günceller"""
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")

    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")

    # Term'i bul ve kullanıcının sahip olduğu lesson'a ait olduğunu kontrol et
    db_term = db.query(QuestionTerm).join(QuestionLesson).filter(
        QuestionTerm.id == term_id,
        QuestionLesson.user_id == db_user.id
    ).first()
    
    if db_term is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term bulunamadı")

    # Güncelle
    db_term.term_title = term.term_title
    db.commit()
    db.refresh(db_term)
    
    return TermResponse(
        id=db_term.id,
        term_title=db_term.term_title,
        lesson_id=db_term.q_lesson_id
    )

# ===== NOTE TERM GÜNCELLEME =====

@router.put("/NoteTerm/update/{term_id}")
def update_note_term(
    term_id: int,
    term: TermRequest,
    user: user_dependency,
    db: db_dependency
):
    """Note term günceller"""
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")

    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")

    # Term'i bul ve kullanıcının sahip olduğu lesson'a ait olduğunu kontrol et
    db_term = db.query(NoteTerm).join(NoteLesson).filter(
        NoteTerm.id == term_id,
        NoteLesson.user_id == db_user.id
    ).first()
    
    if db_term is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term bulunamadı")

    # Güncelle
    db_term.term_title = term.term_title
    db.commit()
    db.refresh(db_term)
    
    return TermResponse(
        id=db_term.id,
        term_title=db_term.term_title,
        lesson_id=db_term.n_lesson_id
    )


@router.delete("/QuestionTerm/delete/{term_id}")
def delete_question_term(term_id: int, user: user_dependency, db: db_dependency):
    """Question term siler"""
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")


    term = db.query(QuestionTerm).join(QuestionLesson).filter(
        QuestionTerm.id == term_id,
        QuestionLesson.user_id == db_user.id
    ).first()
    
    if term is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term bulunamadı")
    
    db.delete(term)
    db.commit()
    return {"message": "Question term başarıyla silindi"}



@router.delete("/NoteTerm/delete/{term_id}")
def delete_note_term(term_id: int, user: user_dependency, db: db_dependency):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")

    # Term'i bul ve kullanıcının sahip olduğu lesson'a ait olduğunu kontrol et
    term = db.query(NoteTerm).join(NoteLesson).filter(
        NoteTerm.id == term_id,
        NoteLesson.user_id == db_user.id
    ).first()
    
    if term is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term bulunamadı")
    
    db.delete(term)
    db.commit()
    return {"message": "Note term başarıyla silindi"}



@router.get("/QuestionTerm/{term_id}")
def get_question_term_by_id(term_id: int, user: user_dependency, db: db_dependency):

    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")

    # Term'i bul ve kullanıcının sahip olduğu lesson'a ait olduğunu kontrol et
    term = db.query(QuestionTerm).join(QuestionLesson).filter(
        QuestionTerm.id == term_id,
        QuestionLesson.user_id == db_user.id
    ).first()
    
    if term is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term bulunamadı")
    
    return TermResponse(
        id=term.id,
        term_title=term.term_title,
        lesson_id=term.q_lesson_id
    )

@router.get("/NoteTerm/{term_id}")
def get_note_term_by_id(term_id: int, user: user_dependency, db: db_dependency):
    """Belirli bir note term'i getirir"""
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    db_user = db.query(User).filter(User.id == user.get("id")).first()
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")

    # Term'i bul ve kullanıcının sahip olduğu lesson'a ait olduğunu kontrol et
    term = db.query(NoteTerm).join(NoteLesson).filter(
        NoteTerm.id == term_id,
        NoteLesson.user_id == db_user.id
    ).first()
    
    if term is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term bulunamadı")
    
    return TermResponse(
        id=term.id,
        term_title=term.term_title,
        lesson_id=term.n_lesson_id
    )

