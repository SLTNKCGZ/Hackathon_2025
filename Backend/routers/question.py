import os
import uuid
import json
from typing import Annotated, Optional, List

import requests
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from starlette import status
from models import Question, QuestionTerm, QuestionLesson, User, NoteLesson, NoteTerm
from routers.auth import get_current_user,db_dependency
import pytesseract
from PIL import Image

# Tesseract path'ini ayarla
import os
tesseract_paths = [
    r"C:\Program Files\Tesseract-OCR\tesseract.exe",
    r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
    r"C:\Users\USER\AppData\Local\Programs\Tesseract-OCR\tesseract.exe"
]

tesseract_found = False
for path in tesseract_paths:
    if os.path.exists(path):
        pytesseract.pytesseract.tesseract_cmd = path
        tesseract_found = True
        print(f"Tesseract found at: {path}")
        break

if not tesseract_found:
    print("Tesseract not found in common paths. Please install Tesseract OCR.")
    print("Download from: https://github.com/UB-Mannheim/tesseract/wiki")



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


def createQuiz(contents, difficulty, count, quiz_type):
    google_api_key = os.getenv("GOOGLE_API_KEY")
    if not google_api_key:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="AI API key bulunamadı")
    
    # İçerikleri birleştir
    content_text = "\n\n".join(contents)
    
    if quiz_type == "note":
        # Notlar için özel prompt
        prompt = f"""Sen bir quiz oluşturma uzmanısın. Aşağıdaki not içeriklerine dayalı olarak {count} adet çoktan seçmeli soru oluştur.

        NOT İÇERİKLERİ:
        {content_text}

        Zorluk seviyesi: {difficulty} ({'Kolay' if difficulty == 1 else 'Orta' if difficulty == 2 else 'Zor'})
        Bu notlardan öğrenilen konular hakkında sorular oluştur. Her soru için:
        - Soru metni (notlardaki bilgilere dayalı)
        - 4 seçenek (A, B, C, D)
        - Doğru cevap
        - Kısa açıklama (neden doğru olduğu)
        - İpucu (öğrencinin doğru cevabı bulmasına yardımcı olacak kısa bir ipucu)

        KURALLAR:
        1. SADECE JSON formatında yanıt ver
        2. Başka hiçbir açıklama ekleme
        3. JSON dışında hiçbir metin yazma
        4. Yanıtın tamamen geçerli JSON olması gerekiyor
        YANIT FORMATI:
        {{
        "questions": [
            {{
                "question": "Soru metni",
                "options": ["A) Seçenek 1", "B) Seçenek 2", "C) Seçenek 3", "D) Seçenek 4"],
                "correct_answer": "A) Seçenek 1",
                "explanation": "Açıklama",
                "hint": "İpucu metni"
            }}
            ]
        }}"""
        

    else:  # question type
        # Sorular için özel prompt
        prompt = f"""Sen bir quiz oluşturma uzmanısın. Aşağıdaki mevcut sorulara benzer {count} adet çoktan seçmeli soru oluştur.
        MEVCUT SORULAR:
        {content_text}

        Zorluk seviyesi: {difficulty} ({'Kolay' if difficulty == 1 else 'Orta' if difficulty == 2 else 'Zor'})

        Bu sorulara benzer tarzda, aynı konu alanında ve aynı zorluk seviyesinde {count} adet yeni sorular oluştur. Her soru için:
        - Soru metni (mevcut sorulara benzer tarzda)
        - 4 seçenek (A, B, C, D)
        - Doğru cevap
        - Kısa açıklama
        - İpucu (öğrencinin doğru cevabı bulmasına yardımcı olacak kısa bir ipucu)

        KURALLAR:
        1. SADECE JSON formatında yanıt ver
        2. Başka hiçbir açıklama ekleme
        3. JSON dışında hiçbir metin yazma
        4. Yanıtın tamamen geçerli JSON olması gerekiyor
       

        YANIT FORMATI:
        {{
            "questions": [
            {{
                "question": "Soru metni",
                "options": ["A) Seçenek 1", "B) Seçenek 2", "C) Seçenek 3", "D) Seçenek 4"],
                "correct_answer": "A) Seçenek 1",
                "explanation": "Açıklama",
                "hint": "İpucu metni"
            }}
            ]
             
        }}"""


    try:
        # Google AI API'ye istek gönder
        url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

        headers = {
            "Content-Type": "application/json"
        }

        data = {
            "contents": [
                {
                    "parts": [
                        {
                            "text": prompt
                        }
                    ]
                }
            ]
        }

        response = requests.post(
            f"{url}?key={google_api_key}",
            headers=headers,
            json=data,
            timeout=30
        )

        if response.status_code != 200:
            print("AI API hata kodu:", response.status_code, response.text)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="AI servisi ile iletişim kurulamadı"
            )

        # AI yanıtını parse et
        response_data = response.json()
        ai_response = response_data.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        
        # Debug için AI yanıtını logla
        print(f"AI Response Length: {len(ai_response)}")
        print(f"AI Response: {ai_response}")
        print(f"AI Response Type: {type(ai_response)}")
        
        # AI yanıtını temizle (```json ve ``` işaretlerini kaldır)
        ai_response = ai_response.strip()
        if ai_response.startswith("```json"):
            ai_response = ai_response[7:]  # ```json kısmını kaldır
        if ai_response.startswith("```"):
            ai_response = ai_response[3:]  # ``` kısmını kaldır
        if ai_response.endswith("```"):
            ai_response = ai_response[:-3]  # Sondaki ``` kısmını kaldır
        
        ai_response = ai_response.strip()
        print(f"Cleaned AI Response: {ai_response[:200]}...")
        
        try:
            # JSON parse etmeyi dene
            quiz_data = json.loads(ai_response)
            questions = quiz_data.get("questions", [])
            
            # QuizQuestion objelerine dönüştür
            quiz_questions = []
            for q in questions:
                quiz_questions.append(QuizQuestion(
                    question=q.get("question", ""),
                    options=q.get("options", []),
                    correct_answer=q.get("correct_answer", ""),
                    explanation=q.get("explanation"),
                    hint=q.get("hint")
                ))
            
            return QuizResponse(
                questions=quiz_questions,
                total_time=count * 2,  # Her soru için 2 dakika
                difficulty=difficulty,
                type=quiz_type
            )
            
        except json.JSONDecodeError as e:
            print("JSON parse error:", e)
            print("AI response that failed to parse:", repr(ai_response))
            # JSON parse edilemezse basit sorular oluştur
            quiz_questions = []
            for i in range(count):
                if quiz_type == "note":
                    question_text = f"Bu notlardan öğrenilen konular hakkında {i+1}. soru"
                else:
                    question_text = f"Mevcut sorulara benzer {i+1}. soru"
                
                quiz_questions.append(QuizQuestion(
                    question=question_text,
                    options=[
                        "A) Birinci seçenek",
                        "B) İkinci seçenek", 
                        "C) Üçüncü seçenek",
                        "D) Dördüncü seçenek"
                    ],
                    correct_answer="A) Birinci seçenek",
                    explanation="AI yanıtı parse edilemedi, bu bir fallback sorudur.",
                    hint="Bu soru için ipucu mevcut değil."
                ))
            
            return QuizResponse(
                questions=quiz_questions,
                total_time=count * 2,
                difficulty=difficulty,
                type=quiz_type
            )

    except requests.exceptions.RequestException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI servisi hatası: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Beklenmeyen hata: {str(e)}"
        )


@router.get("/createNoteQuiz/{lesson_id}/{term_id}/{difficulty}/{count}")
def create_note_quiz(lesson_id: int, term_id: int, difficulty: int, count: int, user: user_dependency, db: db_dependency):
    """Notlardan quiz oluşturur"""
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    user_obj = db.query(User).filter(User.id == user.get("id")).first()
    if not user_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    noteLesson = db.query(NoteLesson).filter(NoteLesson.id == lesson_id, NoteLesson.user_id == user_obj.id).first()
    noteTerm = db.query(NoteTerm).filter(NoteTerm.id == term_id, NoteTerm.n_lesson_id == lesson_id).first()
    
    if not noteLesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")
    if not noteTerm:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term not found")
    if difficulty not in [1, 2, 3]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Difficulty must be 1, 2, or 3")
    
    notes = [note.content for note in noteTerm.notes]
    if not notes:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No notes found for this term")
    
    return createQuiz(notes, difficulty, count, "note")


def parse_questions(questions):
    """Soru resimlerinden metin çıkarır - OCR ile"""
    if not tesseract_found:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Tesseract OCR bulunamadı. Lütfen Tesseract'ı kurun."
        )
    
    try:
        print(f"Tesseract version: {pytesseract.get_tesseract_version()}")
    except Exception as e:
        print(f"Tesseract version check failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Tesseract OCR çalışmıyor. Lütfen kurulumu kontrol edin."
        )
    
    parsed_texts = []
    
    for image_path in questions:
        try:
            # Resim dosyasını oku
            file_path = image_path.replace("/uploads/", "uploads/")
            if not os.path.exists(file_path):
                continue
                
            # PIL ile resmi aç
            image = Image.open(file_path)
            
            # OCR ile metin çıkar
            extracted_text = pytesseract.image_to_string(image, lang='tur')
            
            if extracted_text.strip():
                parsed_texts.append(extracted_text.strip())
            else:
                parsed_texts.append("Metin çıkarılamadı")
                
        except Exception as e:
            parsed_texts.append(f"İşlem hatası: {str(e)}")
    
    return parsed_texts

@router.get("/check-tesseract", response_model=TesseractResponse)
def check_tesseract():
    """Tesseract OCR kurulumunu kontrol eder"""
    try:
        version = pytesseract.get_tesseract_version()
        return TesseractResponse(
            status="success",
            tesseract_found=tesseract_found,
            version=str(version),
            path=pytesseract.pytesseract.tesseract_cmd
        )
    except Exception as e:
        return TesseractResponse(
            status="error",
            tesseract_found=tesseract_found,
            error=str(e),
            path=pytesseract.pytesseract.tesseract_cmd
        )

@router.get("/createQuestionQuiz/{lesson_id}/{term_id}/{difficulty}/{count}")
def create_question_quiz(lesson_id: int, term_id: int, difficulty: int, count: int, user: user_dependency, db: db_dependency):
    """Soru resimlerinden quiz oluşturur"""
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    user_obj = db.query(User).filter(User.id == user.get("id")).first()
    if not user_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    questionLesson = db.query(QuestionLesson).filter(QuestionLesson.id == lesson_id, QuestionLesson.user_id == user_obj.id).first()
    questionTerm = db.query(QuestionTerm).filter(QuestionTerm.id == term_id, QuestionTerm.q_lesson_id == lesson_id).first()
    
    if not questionLesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")
    if not questionTerm:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Term not found")
    if difficulty not in [1, 2, 3]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Difficulty must be 1, 2, or 3")
    
    questions = [question.image_path for question in questionTerm.questions]
    if not questions:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No questions found for this term")
    
    parsed_questions = parse_questions(questions)
    return createQuiz(parsed_questions, difficulty, count, "question")