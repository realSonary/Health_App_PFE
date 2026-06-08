# Backend Email Setup — Password Reset

## Files
- `password_reset.py` — FastAPI router with `/auth/forgot-password` and `/auth/reset-password`

## Quick Setup (Gmail)

1. Enable **2-Step Verification** on your Gmail account
2. Go to https://myaccount.google.com/apppasswords
3. Generate an App Password (select "Mail" + "Windows Computer")
4. Copy the 16-character password

5. Create a `.env` file at your project root:
```
SMTP_FROM=your.address@gmail.com
SMTP_PASSWORD=xxxx xxxx xxxx xxxx
```

6. In your FastAPI `main.py`, include the router:
```python
from password_reset import router as reset_router
app.include_router(reset_router)
```

## Dev Mode (no email credentials)
If `SMTP_FROM` / `SMTP_PASSWORD` are empty, the reset code is printed
to the console instead of emailed — useful for local testing.

## What the email looks like
- Subject: `Your SSHA Reset Code: 123456`
- Styled HTML email with the plum/purple SSHA branding
- Shows the 6-digit code in large bold text
- Expires-in notice (15 minutes)
