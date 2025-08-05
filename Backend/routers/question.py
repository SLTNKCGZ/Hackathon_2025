import uuid
from typing import Annotated, Optional, List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from starlette import status
from models import Question, QuestionTerm, QuestionLesson, User
from routers.auth import get_current_user,db_dependency
import os


router = APIRouter(
    prefix="/questions",
    tags=["Questions"]
)

user_dependency=Annotated[dict,Depends(get_current_user)]

# Response modeli
class QuestionResponse(BaseModel):
    id: int
    image_path: str
    note: Optional[str] = None
    difficulty_category: int
    lesson_id:int
    term_id: int

# Quiz response models
class QuizQuestion(BaseModel):
    question: str
    options: List[str]
    correct_answer: str
    explanation: Optional[str] = None
    hint: Optional[str] = None

class QuizResponse(BaseModel):
    questions: List[QuizQuestion]
    total_time: int
    difficulty: int
    type: str

class TesseractResponse(BaseModel):
    status: str
    tesseract_found: bool
    version: Optional[str] = None
    path: Optional[str] = None
    error: Optional[str] = None

# ===== QUESTION OLUŞTURMA =====
@router.post("/create")
async def create_question(
    user: user_dependency,
    db: db_dependency,
    image: UploadFile = File(..., description="Question fotoğrafı (zorunlu)"),
    difficulty_category: int = Form(..., description="Zorluk kategorisi: 1=Kolay, 2=Orta, 3=Zor"),
    note: Optional[str] = Form(None, description="Kullanıcının notu (opsiyonel)"),
    lesson_id: int = Form(..., description="Lesson ID (opsiyonel)"),
    term_id: int = Form(..., description="Term ID (opsiyonel)"),
):
    

    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    

    if difficulty_category not in [1, 2, 3]:
        raise HTTPException(
            status_code=400, 
            detail="Kategori 1 (Kolay), 2 (Orta) veya 3 (Zor) olmalıdır"
        )
    

    lesson = db.query(QuestionLesson).filter(
        QuestionLesson.id == lesson_id,
        QuestionLesson.user_id == user.get("id")
    ).first()

    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson bulunamadı")

    term = db.query(QuestionTerm).filter(
        QuestionTerm.id == term_id,
        QuestionTerm.q_lesson_id == lesson.id
    ).first()

    if term is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term not found")


    image_path = await save_uploaded_image(image)

    question = Question(
        image_path=image_path,
        note=note,
        difficulty_category=difficulty_category,
        term_id=term_id
    )
    
    db.add(question)
    db.commit()
    db.refresh(question)
    
    return QuestionResponse(
        id=question.id,
        image_path=question.image_path,
        note=question.note,
        difficulty_category=question.difficulty_category,
        term_id=question.term_id,
        lesson_id=term.q_lesson_id,
    )

@router.get("/{lesson_id}/{difficulty_id}/{term_id}")
async def get_questions_by_term(
    term_id: int,
    lesson_id: int,
    difficulty_id: int,
    user: Annotated[dict, Depends(get_current_user)] = None,
    db: db_dependency = None
):

    
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    
    user_obj = db.query(User).filter(User.id == user.get("id")).first()
    if user_obj is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    lesson = db.query(QuestionLesson).filter(QuestionLesson.id == lesson_id,QuestionLesson.user_id==user_obj.id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")

    term = db.query(QuestionTerm).filter(
        QuestionTerm.id == term_id,
        QuestionTerm.q_lesson_id == lesson.id
    ).first()
    
    if not term:
        raise HTTPException(status_code=404, detail="Term bulunamadı")

    questions = db.query(Question).filter(
        Question.term_id == term_id,
        Question.difficulty_category == difficulty_id
    ).order_by(Question.id).all()

    return [
        QuestionResponse(
            id=q.id,
            image_path=q.image_path,
            note=q.note,
            difficulty_category=q.difficulty_category,
            term_id=q.term_id,
            lesson_id=lesson.id
        ) for q in questions
    ]

@router.put("/{question_id}/{difficulty_category}")
async def update_question(
user: user_dependency,
    db: db_dependency,
    question_id: int,
    difficulty_category: int,
    note: Optional[str] = Form(None, description="Yeni not"),
):

    
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    # Question'ı bul ve kullanıcının sahip olduğu term'e ait olduğunu kontrol et
    question = db.query(Question).join(QuestionTerm).join(QuestionLesson).filter(
        Question.id == question_id,
        QuestionLesson.user_id == user.get("id")
    ).first()
    
    if not question:
        raise HTTPException(status_code=404, detail="Question bulunamadı")
    
    # Kategori kontrolü
    if difficulty_category is not None and difficulty_category not in [1, 2, 3]:
        raise HTTPException(
            status_code=400, 
            detail="Kategori 1 (Kolay), 2 (Orta) veya 3 (Zor) olmalıdır"
        )
    
    # Güncelle
    if note is not None:
        question.note = note
    if difficulty_category is not None:
        question.difficulty_category = difficulty_category
    
    db.commit()
    db.refresh(question)
    
    return QuestionResponse(
        id=question.id,
        image_path=question.image_path,
        note=question.note,
        difficulty_category=question.difficulty_category,
        term_id=question.term_id,
        lesson_id=question.term.q_lesson_id,
    )


@router.delete("/{question_id}")
async def delete_question(
    question_id: int,
    user: Annotated[dict, Depends(get_current_user)] = None,
    db: db_dependency = None
):

    
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    

    question = db.query(Question).join(QuestionTerm).join(QuestionLesson).filter(
        Question.id == question_id,
        QuestionLesson.user_id == user.get("id")
    ).first()
    
    if not question:
        raise HTTPException(status_code=404, detail="Question bulunamadı")
    
    # Fotoğrafı sil
    delete_image_file(question.image_path)
    
    db.delete(question)
    db.commit()
    
    return {"message": "Question başarıyla silindi"}

@router.get("/statistics")
async def get_question_statistics(
    user: user_dependency,
    db: db_dependency
):
    """Kullanıcının question istatistiklerini döndürür"""
    
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Giriş yapmanız gerekiyor")
    
    # Kullanıcının lesson'larını al
    user_lessons = db.query(QuestionLesson).filter(
        QuestionLesson.user_id == user.get("id")
    ).all()
    
    lesson_ids = [lesson.id for lesson in user_lessons]
    
    # Bu lesson'lara ait term'leri al
    terms = db.query(QuestionTerm).filter(QuestionTerm.q_lesson_id.in_(lesson_ids)).all()
    term_ids = [term.id for term in terms]
    
    # İstatistikleri hesapla
    total_questions = db.query(Question).filter(Question.term_id.in_(term_ids)).count()
    easy_questions = db.query(Question).filter(
        Question.term_id.in_(term_ids),
        Question.difficulty_category == 1
    ).count()
    medium_questions = db.query(Question).filter(
        Question.term_id.in_(term_ids),
        Question.difficulty_category == 2
    ).count()
    hard_questions = db.query(Question).filter(
        Question.term_id.in_(term_ids),
        Question.difficulty_category == 3
    ).count()
    
    return {
        "total_questions": total_questions,
        "by_difficulty": {
            "easy": easy_questions,
            "medium": medium_questions,
            "hard": hard_questions
        },
        "total_lessons": len(user_lessons),
        "total_terms": len(terms)
    }

async def save_uploaded_image(image: UploadFile) -> str:

    allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
    file_extension = os.path.splitext(image.filename)[1].lower()
    
    if file_extension not in allowed_extensions:
        raise HTTPException(
            status_code=400, 
            detail="Sadece jpg, jpeg, png, gif, webp formatları desteklenir"
        )

    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join("uploads", unique_filename)
    

    try:
        with open(file_path, "wb") as buffer:
            content = await image.read()
            buffer.write(content)
        return f"/uploads/{unique_filename}"
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dosya yüklenemedi: {str(e)}")

def delete_image_file(image_path: str):

    try:
        file_path = image_path.replace("/uploads/", "uploads/")
        if os.path.exists(file_path):
            os.remove(file_path)
    except Exception as e:
        print(f"Fotoğraf silinemedi: {e}")

