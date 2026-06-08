"""
password_reset.py  — Drop this into your FastAPI routers folder and include it.

Requirements:
    pip install fastapi python-multipart

Email is sent via Gmail SMTP (App Password).
For other providers, change SMTP_HOST / SMTP_PORT.

Setup:
    1.  Enable "2-Step Verification" on your Gmail account.
    2.  Go to  https://myaccount.google.com/apppasswords
    3.  Create an App Password → copy it.
    4.  Set these env vars  (or a .env file):
            SMTP_FROM       =  your.address@gmail.com
            SMTP_PASSWORD   =  xxxx xxxx xxxx xxxx   (16-char app password)

    The reset codes live in memory (dict).
    For production, store them in your DB or Redis with an index.
"""

import os
import random
import smtplib
import string
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr

router = APIRouter(prefix="/auth", tags=["auth"])

# ─── Config ───────────────────────────────────────────────────────────────────

SMTP_HOST     = "smtp.gmail.com"
SMTP_PORT     = 587            # STARTTLS
SMTP_FROM     = os.getenv("SMTP_FROM", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
CODE_TTL_MINS = 15

# ─── In-memory code store  { email: (code, expires_at) } ─────────────────────
# Replace with Redis or DB for production.

_reset_store: dict[str, tuple[str, datetime]] = {}

# ─── Models ───────────────────────────────────────────────────────────────────

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str

# ─── Email sender ─────────────────────────────────────────────────────────────

def _send_reset_email(to_email: str, code: str) -> None:
    """Send the reset code email via Gmail SMTP."""
    if not SMTP_FROM or not SMTP_PASSWORD:
        # Running without credentials — print to console for dev testing
        print(f"\n[DEV MODE]  Reset code for {to_email}:  {code}\n")
        return

    html_body = f"""
    <html>
    <body style="font-family: Arial, sans-serif; background: #F0EBE6; padding: 30px;">
      <div style="max-width: 480px; margin: 0 auto; background: #fff;
                  border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px #0002;">
        <div style="background: linear-gradient(135deg,#2A1A32,#52305C);
                    padding: 32px; text-align: center;">
          <p style="font-size: 40px; margin:0;">🔑</p>
          <h2 style="color:#fff; margin:12px 0 0; font-size:22px;">Password Reset</h2>
        </div>
        <div style="padding: 32px; text-align: center;">
          <p style="color:#5E5555; font-size:15px; margin-bottom:24px;">
            Use the code below to reset your SSHA password.<br>
            It expires in <strong>{CODE_TTL_MINS} minutes</strong>.
          </p>
          <div style="background:#F0E6F4; border:2px dashed #DEC8E4;
                      border-radius:12px; padding:24px; margin:0 auto 24px;
                      display:inline-block; min-width:200px;">
            <span style="font-size:38px; font-weight:800; letter-spacing:10px;
                         color:#52305C;">{code}</span>
          </div>
          <p style="color:#9E9292; font-size:12px;">
            If you didn't request a password reset, ignore this email.
          </p>
        </div>
        <div style="background:#F0EBE6; padding:16px; text-align:center;">
          <p style="color:#9E9292; font-size:11px; margin:0;">
            SSHA · Smart Student Health Assistant
          </p>
        </div>
      </div>
    </body>
    </html>
    """

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"Your SSHA Reset Code: {code}"
    msg["From"]    = SMTP_FROM
    msg["To"]      = to_email
    msg.attach(MIMEText(html_body, "html"))

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as s:
        s.starttls()
        s.login(SMTP_FROM, SMTP_PASSWORD)
        s.sendmail(SMTP_FROM, [to_email], msg.as_string())

# ─── Routes ───────────────────────────────────────────────────────────────────

@router.post("/forgot-password", status_code=200)
async def forgot_password(body: ForgotPasswordRequest, db=None):
    """
    Step 1 — generate a 6-digit code, store it, and email it.

    Tip: inject your DB session via Depends() instead of the
    placeholder `db=None`.  Use it to verify the email exists in
    your users table before sending.
    """
    # --- Optional: verify email exists ---
    # user = db.query(User).filter(User.email == body.email).first()
    # if not user:
    #     raise HTTPException(status_code=404, detail="No account with that email.")

    code = "".join(random.choices(string.digits, k=6))
    expires_at = datetime.utcnow() + timedelta(minutes=CODE_TTL_MINS)
    _reset_store[body.email] = (code, expires_at)

    try:
        _send_reset_email(body.email, code)
    except Exception as e:
        # Don't leak SMTP errors to the client
        print(f"[SMTP ERROR]  {e}")
        raise HTTPException(status_code=500,
                            detail="Could not send email. Check server SMTP config.")

    return {"message": "Reset code sent to your email."}


@router.post("/reset-password", status_code=200)
async def reset_password(body: ResetPasswordRequest, db=None):
    """
    Step 2 — validate the code and update the password.
    """
    entry = _reset_store.get(body.email)
    if not entry:
        raise HTTPException(status_code=400,
                            detail="No reset request found. Request a new code.")

    stored_code, expires_at = entry

    if datetime.utcnow() > expires_at:
        _reset_store.pop(body.email, None)
        raise HTTPException(status_code=400,
                            detail="Reset code has expired. Please request a new one.")

    if body.code != stored_code:
        raise HTTPException(status_code=400, detail="Incorrect reset code.")

    # --- Update password in your DB ---
    # from passlib.context import CryptContext
    # pwd_context = CryptContext(schemes=["bcrypt"])
    # hashed = pwd_context.hash(body.new_password)
    # user = db.query(User).filter(User.email == body.email).first()
    # user.hashed_password = hashed
    # db.commit()

    _reset_store.pop(body.email, None)

    return {"message": "Password reset successfully."}
