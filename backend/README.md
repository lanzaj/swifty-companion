# Swifty Companion Backend

This is a Python FastAPI backend for the Swifty Companion Flutter app. It handles OAuth 2.0 authentication with the 42 API.

## Setup

1.  **Create a Virtual Environment (Optional but recommended):**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

2.  **Install Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Configure Environment Variables:**
    -   Copy `.env.example` to `.env`:
        ```bash
        cp .env.example .env
        ```
    -   Edit `.env` and fill in your **42 API UID** and **SECRET**.
    -   Set `REDIRECT_URI` to match what you registered in the 42 API settings (e.g., `swiftycompanion://auth`).

## Running the Server

```bash
uvicorn main:app --reload
```

The server will start at `http://127.0.0.1:8000`.

## Makefile Commands

The backend includes a `Makefile` to simplify common tasks:

-   `make run`: Checks for `.env` file and starts the server with hot reload.
-   `make install`: Creates a virtual environment and installs dependencies.
-   `make clean`: Removes `__pycache__` and `venv`.

## API Endpoints

-   `GET /`: Health check.
-   `GET /auth/login`: Redirects to 42 API authorization page.
-   `GET /auth/callback`: Callback URL for 42 API. Exchanges code for token and redirects to the app via deep link.
-   `POST /auth/token`: Exchanges an authorization code for an access token. Required JSON body: `{"code": "...", "redirect_uri": "..."}`.
-   `POST /auth/refresh`: Refreshes an expired access token. Required JSON body: `{"refresh_token": "..."}`.

## Deep Linking

The backend redirects to `swiftycompanion://auth?token=<ACCESS_TOKEN>`.
Ensure your Flutter app is configured to handle the `swiftycompanion` scheme.
