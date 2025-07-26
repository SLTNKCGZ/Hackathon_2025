import smtplib
import string
from datetime import timedelta, datetime, timezone
import random
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Annotated, Optional
from passlib.context import CryptContext
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy.orm import Session
from jose import JWTError,jwt
from starlette import status

from database import SessionLocal
from models import User

router = APIRouter(
    prefix="/auth",
    tags=["Auth"]
)

def get_db():
    db=SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency=Annotated[Session,Depends(get_db)]
bcrypt_context=CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_bearer=OAuth2PasswordBearer(tokenUrl="/auth/login")

class UserRequest(BaseModel):
    username:str
    firstName:str
    lastName:str
    email:str
    password:str


async def get_current_user(token: Annotated[str, Depends(oauth2_bearer)]):
    print(f"Received token: {token}")  # Debug için

    if not token or token == "undefined":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token is missing or invalid")

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get('sub')
        user_id = payload.get('id')
        print(f"Decoded payload: username={username}, user_id={user_id}")  # Debug için

        if username is None or user_id is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")
        return {"username": username, "id": user_id}
    except JWTError as e:
        print(f"JWT Error: {e}")  # Debug için
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

@router.post("/create")
def create_user(user: UserRequest, db:db_dependency):
    db_user=User(
        username=user.username,
        firstName=user.firstName,
        lastName=user.lastName,
        email=user.email,
        hashed_password=bcrypt_context.hash(user.password))
    db.add(db_user)
    db.commit()



def authenticate(username, password,db):
    user=db.query(User).filter(User.username==username).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect username or password")
    if not bcrypt_context.verify(password,user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    return user


SECRET_KEY="dv1hyoGQsV09jMF1htLibVWGG4sSPLGZTEgeaVRZCZG26OikBUyQLEHxi9gY6CTV"
ALGORITHM="HS256"


def create_access_token(username:str, user_id:int, expires_delta:timedelta):
    to_encode={"sub":username,"id":user_id}
    expire= datetime.now(timezone.utc) + expires_delta
    to_encode.update({"exp":expire})
    encoded_jwt=jwt.encode(to_encode,SECRET_KEY,algorithm=ALGORITHM)
    return encoded_jwt

@router.post("/login")
def login(form_data: Annotated[OAuth2PasswordRequestForm, Depends()], db: db_dependency):
    user = authenticate(form_data.username, form_data.password, db)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect username or password")
    token = create_access_token(user.username, user.id, timedelta(days=365*100))
    return {"access_token": token, "token_type": "bearer"}

class UpdateUserRequest(BaseModel):
    username: Optional[str] = None
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None


@router.put("/update")
def update_user(
        user: Annotated[dict, Depends(get_current_user)],
        updateUser: UpdateUserRequest,
        db: db_dependency
):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    update = db.query(User).filter(User.username == user.get("username")).first()
    if update is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")


    if updateUser.firstName is not None:
        update.first_name = updateUser.firstName

    if updateUser.lastName is not None:
        update.last_name = updateUser.lastName

    if updateUser.email is not None:
        update.email = updateUser.email


    if updateUser.username is not None:
        if update.username != updateUser.username:
            existing_user = db.query(User).filter(User.username == updateUser.username).first()
            if existing_user:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists")
            update.username = updateUser.username

    if updateUser.password is not None:
        update.hashed_password = bcrypt_context.hash(updateUser.password)

    try:
        db.commit()
        return {"message": "User updated successfully"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@router.delete("/delete")
def delete_user(user: Annotated[dict, Depends(get_current_user)], db: db_dependency):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)
    user_obj = db.query(User).filter(User.username == user.get("username")).first()
    if user_obj is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    db.delete(user_obj)
    db.commit()
    return {"message": "User deleted successfully"}

@router.get("/me")
def get_me(db: db_dependency, user: Annotated[dict, Depends(get_current_user)]):
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)
    user_obj = db.query(User).filter(User.id == user.get("id")).first()
    if user_obj is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return {
        "username": user_obj.username,
        "email": user_obj.email,
        "firstName": user_obj.firstName,
        "lastName": user_obj.lastName,
    }



class PasswordResetRequest(BaseModel):
    email: str

class PasswordResetVerifyRequest(BaseModel):
    email: str
    new_password: str

reset_codes = {}

class PasswordResetCodeVerifyRequest(BaseModel):
    email: str
    code: str

@router.post("/forgot-password-verify-code")
def forgot_password_verify_code(request: PasswordResetCodeVerifyRequest):
    code = reset_codes.get(request.email)
    if not code or code != request.code:
        raise HTTPException(status_code=400, detail="Invalid or expired code")
    return {"message": "Code is valid"}

# E-posta gönderme fonksiyonu (Gmail SMTP örneği)
SMTP_EMAIL = "sultankocagoz.448@gmail.com"  # Buraya kendi e-posta adresini yaz
SMTP_PASSWORD = "yeoi logp qpfe dohf"         # Gmail için uygulama şifresi kullanmalısın
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

def send_reset_code_email(to_email: str, code: str):
    subject = "Şifre Sıfırlama Kodu"
    body = f"Şifre sıfırlama kodunuz: {code}"
    msg = MIMEMultipart()
    msg["From"] = SMTP_EMAIL
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))
    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SMTP_EMAIL, SMTP_PASSWORD)
        server.sendmail(SMTP_EMAIL, to_email, msg.as_string())
        server.quit()
    except Exception as e:
        print(f"E-posta gönderilemedi: {e}")
        raise HTTPException(status_code=500, detail="E-posta gönderilemedi")

@router.post("/forgot-password-send-code")
def forgot_password_send_code(request: PasswordResetRequest, db: db_dependency):
    print(request.email)
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    # 6 haneli kod üret
    code = ''.join(random.choices(string.digits, k=6))
    reset_codes[request.email] = code
    # Gerçek e-posta gönderimi
    send_reset_code_email(request.email, code)
    return {"message": "Password reset code sent to email"}

@router.post("/forgot-password-verify")
def forgot_password_verify(request: PasswordResetVerifyRequest, db: db_dependency):
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.hashed_password = bcrypt_context.hash(request.new_password)
    db.commit()
    del reset_codes[request.email]
    return {"message": "Password reset successful"}



