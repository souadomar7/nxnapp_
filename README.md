# NXN App Backend Server

This is the Node.js backend for the NXN App, handling payment processing via Fintx and authentication via Supabase.

## Setup

1.  **Install Dependencies**
    Since the environment prevented automatic installation, please run:
    ```bash
    cd server
    npm install
    ```

2.  **Environment Variables**
    Open `server/.env` and fill in your actual credentials:
    -   `SUPABASE_URL` & `SUPABASE_KEY`: From your Supabase project settings.
    -   `FINTX_API_URL`, `FINTX_API_KEY`, `FINTX_MERCHANT_ID`: From your Fintx dashboard.

3.  **Run Development Server**
    ```bash
    npm run dev
    ```

## API Endpoints

-   `GET /api/status`: Check server health.
-   `POST /api/payment/initiate`: Create a payment link. Requires Bearer Token.
-   `POST /api/payment/webhook`: Handle Fintx callbacks.

## Project Structure

-   `src/app.js`: Entry point.
-   `src/config`: Configuration files.
-   `src/services`: Business logic (Payment integration).
-   `src/controllers`: Request handlers.
-   `src/routes`: API route definitions.
-   `src/middlewares`: Auth middleware.
# nxnapp
# nxnapp
