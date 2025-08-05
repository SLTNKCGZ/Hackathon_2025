from typing import List, Optional, Annotated
import json
from fastapi import HTTPException, APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from starlette import status
import pytesseract
from PIL import Image
import os
import requests
from database import SessionLocal
from models import User, QuestionLesson, QuestionTerm, NoteLesson, NoteTerm
from routers.auth import get_current_user

router = APIRouter(
    prefix="/api",
    tags=["API"]
)

def get_db():
    db=SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency=Annotated[Session,Depends(get_db)]
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

class CulturalQuestion(BaseModel):
    question: str
    answer: str

class CulturalResponse(BaseModel):
    questions: List[CulturalQuestion]


class TesseractResponse(BaseModel):
    status: str
    tesseract_found: bool
    version: Optional[str] = None
    path: Optional[str] = None
    error: Optional[str] = None

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

        except json.JSONDecodeError:
            # JSON parse edilemezse basit sorular oluştur
            quiz_questions = []
            for i in range(count):
                if quiz_type == "note":
                    question_text = f"Bu notlardan öğrenilen konular hakkında { i +1}. soru"
                else:
                    question_text = f"Mevcut sorulara benzer { i +1}. soru"

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


def get_infos():
    api_key = os.getenv("GOOGLE_API_KEY_3")
    if not api_key:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="AI API key bulunamadı")

    prompt="""Genel kültür sorularından oluşan 4 ile 10 adet arasında açık uçlu soru istiyorum.Bu soruların konuları eşit dağılımlı olsun yani hepsi aynı konu hakkında olmasın.
    Ayrıca kişinin ufkunu genişletecek sorulardan oluşsun.
    Her soru için:
        - Soru metni 
        - Doğru cevap
        
        KURALLAR:
        1. SADECE JSON formatında yanıt ver
        2. Başka hiçbir açıklama ekleme
        3. JSON dışında hiçbir metin yazma
        4. Yanıtın tamamen geçerli JSON olması gerekiyor


        YANIT FORMATI:
        {{
            "questions": [
            {{
                "question": "Açık uçlu soru metni",
                "answer": "Nedeni ile birlikte sorunun cevabının açıklanması",
            }}
            ]

        }}
    """
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
            f"{url}?key={api_key}",
            headers=headers,
            json=data,
            timeout=30
        )

        if response.status_code != 200:
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
            quiz_data = json.loads(ai_response)
            questions = quiz_data.get("questions", [])

            # CulturalQuestion objelerine dönüştür
            cultural_questions = []
            for q in questions:
                cultural_questions.append(CulturalQuestion(
                    question=q.get("question", ""),
                    answer=q.get("answer", "")
                ))

            return CulturalResponse(
                questions=cultural_questions
            )
        except json.JSONDecodeError:
            # JSON parse edilemezse basit sorular oluştur
            cultural_questions = []
            for i in range(5):  # 5 adet fallback soru
                cultural_questions.append(CulturalQuestion(
                    question=f"Genel kültür sorusu {i+1}",
                    answer="Bu soru için cevap mevcut değil."
                ))

            return CulturalResponse(
                questions=cultural_questions
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Beklenmeyen hata: {str(e)}"
        )



@router.get("/getCulturalInformations")
def get_cultural_informations(db: db_dependency, user: user_dependency):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    user_obj = db.query(User).filter(User.id == user.get("id")).first()
    if not user_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    try:
        cultural_response = get_infos()
        return cultural_response
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Kültürel bilgiler alınırken hata oluştu: {str(e)}"
        )