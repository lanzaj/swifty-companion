import os
import logging
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import RedirectResponse
import httpx
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = FastAPI()

UID_42 = os.getenv("UID_42")
SECRET_42 = os.getenv("SECRET_42")
# Default to custom scheme for mobile app flow
REDIRECT_URI = os.getenv("REDIRECT_URI", "swiftycompanion://auth")

# 42 API endpoints
AUTHORIZE_URL = "https://api.intra.42.fr/oauth/authorize"
TOKEN_URL = "https://api.intra.42.fr/oauth/token"

@app.on_event("startup")
async def startup_event():
    logger.info("Backend started. Waiting for requests...")

@app.get("/")
def read_root():
    logger.info("Root endpoint access")
    return {"message": "Swifty Companion Backend is running!"}

@app.get("/auth/login")
def login():
    if not UID_42:
        raise HTTPException(status_code=500, detail="UID_42 not set in environment")
    
    # Construct the authorization URL
    # response_type=code is standard for Authorization Code flow
    # scope=public is a common default, check API docs if more are needed
    url = (
        f"{AUTHORIZE_URL}?client_id={UID_42}&redirect_uri={REDIRECT_URI}"
        f"&response_type=code&scope=public"
    )
    logger.info(f"Redirecting to: {url}")
    return RedirectResponse(url)

@app.get("/auth/callback")
async def callback(code: str):
    if not UID_42 or not SECRET_42:
        raise HTTPException(status_code=500, detail="API credentials not set")

    async with httpx.AsyncClient() as client:
        # Exchange authorization code for access token
        response = await client.post(
            TOKEN_URL,
            data={
                "grant_type": "authorization_code",
                "client_id": UID_42,
                "client_secret": SECRET_42,
                "code": code,
                "redirect_uri": REDIRECT_URI,
            },
        )
        
        if response.status_code != 200:
            logger.error(f"Failed to retrieve access token: {response.text}")
            raise HTTPException(status_code=400, detail="Failed to retrieve access token")
        
        token_data = response.json()
        access_token = token_data.get("access_token")
        
        app_redirect_url = f"swiftycompanion://auth?token={access_token}"
    
        logger.info(f"Callback successful. Redirecting app to: {app_redirect_url}")
        return RedirectResponse(app_redirect_url)

@app.post("/auth/token")
async def exchange_token(request: Request):
    if not UID_42 or not SECRET_42:
        raise HTTPException(status_code=500, detail="API credentials not set")
    
    try:
        body = await request.json()
        code = body.get("code")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")

    if not code:
        raise HTTPException(status_code=400, detail="Code is required")

    redirect_uri = body.get("redirect_uri", "swiftycompanion://auth")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            TOKEN_URL,
            data={
                "grant_type": "authorization_code",
                "client_id": UID_42,
                "client_secret": SECRET_42,
                "code": code,
                "redirect_uri": redirect_uri,
            },
        )
        
        logger.info(f"Swap Code Response: {response.json()}")
        
        if response.status_code != 200:
            return response.json()
        
        return response.json()

@app.post("/auth/refresh")
async def refresh_token(request: Request):
    if not UID_42 or not SECRET_42:
        raise HTTPException(status_code=500, detail="API credentials not set")

    try:
        body = await request.json()
        refresh_token = body.get("refresh_token")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")

    if not refresh_token:
        raise HTTPException(status_code=400, detail="Refresh token is required")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            TOKEN_URL,
            data={
                "grant_type": "refresh_token",
                "client_id": UID_42,
                "client_secret": SECRET_42,
                "refresh_token": refresh_token,
            },
        )
        
        logger.info(f"Refresh Token Response: {response.json()}")
        
        if response.status_code != 200:
            return response.json()

        return response.json()
