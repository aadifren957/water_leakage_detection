# 💧 WaterWatch — Smart City IoT Water Leakage Detection & Monitoring System

**WaterWatch** is a production-grade, end-to-end Smart City Water Leakage Detection and Monitoring System. It connects physical **ESP8266 NodeMCU** IoT hardware, a **Node.js/TypeScript/Prisma** cloud backend on Render, a **Supabase PostgreSQL** database, and a **Flutter/Riverpod** mobile application with **User Registration, Email OTP Verification, and Role-Based Access Control**.

---

## 🏗️ System Architecture

```
┌──────────────────────────────────────┐       ┌──────────────────────────────────────┐
│       ESP8266 IoT Hardware Node      │       │          Flutter Mobile App          │
│  - YF-S201 Hall Flow Sensor (D5)     │       │  - Riverpod State Management         │
│  - LM393 Water Leak Detector (D6)    │       │  - GoRouter Role Guards              │
│  - Active Pump Control Relay (D1)    │       │  - Municipal Officer Dashboard       │
│  - HTTPS Telemetry Ingestion         │       │  - Field Worker Task Resolution      │
└──────────────────┬───────────────────┘       └──────────────────┬───────────────────┘
                   │ HTTPS POST /api/iot/readings                 │ REST API / JWT
                   ▼                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                       Express.js + TypeScript Backend (Render)                      │
│  - Rate Limiting (express-rate-limit) & Helmet Security                             │
│  - Zod Request Validation & BCrypt Password Hashing                                 │
│  - Multi-Provider Email Service (Resend / SMTP / Console)                           │
│  - Cryptographic 6-Digit OTP Engine with SHA-256 Hashing                            │
└──────────────────────────────────────────┬──────────────────────────────────────────┘
                                           │ Prisma ORM
                                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           Supabase PostgreSQL Cloud Database                        │
│  - users, verification_tokens, incidents, incident_histories, notifications         │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔑 Authentication & User Roles

WaterWatch supports two distinct user roles with strict security policies:

### 1. Field Worker (`WORKER`)
- **Self-Registration**: Publicly available on the mobile application signup screen.
- **Email OTP Verification**: Upon registration, an unverified account (`PENDING_VERIFICATION`) is created, and a cryptographically secure 6-digit OTP is delivered to the registered email address.
- **Account Activation**: Entering the valid OTP marks the email verified (`emailVerifiedAt = now()`), activates the account (`accountStatus = ACTIVE`), issues a JWT session, and directly logs the worker in.
- **Worker Capabilities**: Views assigned tasks, inspects sensor flow telemetry at incident locations, marks repairs resolved with notes, and updates workload availability.

### 2. Municipal Officer (`OFFICER`)
- **Protected Provisioning**: Public registration as Municipal Officer is **strictly prohibited**. The backend rejects any attempt to pass `role: OFFICER` during public signup.
- **Provisioning Method**: Officer accounts are created directly by system administration via environment configuration (`INITIAL_OFFICER_*`) or secure administrative scripts.
- **Officer Capabilities**: Real-time pipeline monitoring, live telemetry charts, incident acknowledgment, worker dispatch with capacity checks, and complete audit history.

---

## 📧 Email Provider Setup (OTP & Password Recovery)

The backend features a multi-provider email delivery engine configured via `.env`:

### Option A: Resend (Recommended Cloud Provider)
1. Sign up at [Resend.com](https://resend.com).
2. Generate an API Key (e.g. `re_123456789_abcdefg`).
3. Set in your `.env` (or Render Dashboard):
   ```env
   EMAIL_PROVIDER=resend
   RESEND_API_KEY=re_your_api_key_here
   EMAIL_FROM="WaterWatch Support <onboarding@resend.dev>"
   ```

### Option B: Custom SMTP (Gmail, Brevo, SendGrid, Amazon SES)
1. For Gmail: Generate an **App Password** from Google Account Security.
2. Set in `.env`:
   ```env
   EMAIL_PROVIDER=smtp
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=your-16-char-app-password
   SMTP_SECURE=false
   EMAIL_FROM="WaterWatch Support <your-email@gmail.com>"
   ```

### Option C: Console / Dev Mode (Local Testing)
If `EMAIL_PROVIDER=console`, OTPs are safely logged to the server console for instantaneous testing without needing an external email API.

---

## 📡 REST API Reference

### 🔐 Authentication Endpoints (`/api/auth`)

| Method | Endpoint | Description | Request Body |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Register new Field Worker (sends OTP) | `{ fullName, email, password, phoneNumber?, workerId?, zone? }` |
| `POST` | `/api/auth/verify-email` | Verify 6-digit OTP and activate user | `{ email, otp }` |
| `POST` | `/api/auth/resend-otp` | Resend fresh OTP (60s cooldown) | `{ email }` |
| `POST` | `/api/auth/login` | Sign in with email & password | `{ email, password }` |
| `POST` | `/api/auth/forgot-password` | Request password reset OTP | `{ email }` |
| `POST` | `/api/auth/reset-password` | Reset password using 6-digit OTP | `{ email, otp, newPassword }` |
| `GET` | `/api/auth/me` | Get authenticated user profile | *(Bearer Token required)* |
| `POST` | `/api/auth/logout` | Terminate session | *(Bearer Token required)* |

### 🚨 Incident Lifecycle Endpoints (`/api/incidents`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/incidents` | List incidents (filter by status, severity, zone) |
| `GET` | `/api/incidents/:id` | Get incident details, timeline & live sensor feed |
| `POST` | `/api/incidents` | Manually report incident (Officer only) |
| `PATCH` | `/api/incidents/:id/acknowledge` | Acknowledge incident (`IDENTIFIED` ➔ `ACKNOWLEDGED`) |
| `PATCH` | `/api/incidents/:id/assign` | Assign field technician (`ACKNOWLEDGED` ➔ `ASSIGNED`) |
| `PATCH` | `/api/incidents/:id/resolve` | Resolve incident (`ASSIGNED` ➔ `RESOLVED`) |

### 📟 IoT Telemetry Ingestion (`/api/iot`)

| Method | Endpoint | Headers | Request Body |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/iot/readings` | `X-API-Key: <IOT_API_KEY>` | `{ deviceId, flowRate, totalLiters, leakageDetected, pumpStatus }` |

---

## 🗄️ Database Schema & Migrations

The database schema is managed with **Prisma ORM** targeting **Supabase PostgreSQL**:

### Applying Database Updates
```bash
cd backend
npx prisma generate
npx prisma db push
```

### Models Overview
- **`User`**: User profile, hashed password, role (`OFFICER`, `WORKER`), account status (`PENDING_VERIFICATION`, `ACTIVE`, `PENDING_APPROVAL`, `SUSPENDED`), and verification timestamp (`emailVerifiedAt`).
- **`VerificationToken`**: Hashed 6-digit OTP (`tokenHash`), purpose (`EMAIL_VERIFICATION`, `PASSWORD_RESET`), expiration (`expiresAt`), and attempt counter (`attempts`).
- **`Incident`**: Pipeline leakage incident with status state machine (`IDENTIFIED`, `ACKNOWLEDGED`, `ASSIGNED`, `RESOLVED`).
- **`IncidentHistory`**: Immutable chronological audit trail.
- **`Notification`**: Targeted user alerts with read states.
- **`SensorReading`**: Historical flow rate and volume telemetry.

---

## 🚀 Environment Variables (Render & Local)

Add these environment variables in your Render Web Service dashboard:

```env
PORT=5001
NODE_ENV=production
DATABASE_URL="postgresql://postgres:[PASSWORD]@[REF].supabase.co:5432/postgres?sslmode=require"
DIRECT_URL="postgresql://postgres:[PASSWORD]@[REF].supabase.co:5432/postgres?sslmode=require"
JWT_SECRET="waterwatch_super_secure_jwt_secret_32_characters_long"
JWT_EXPIRES_IN="7d"
IOT_API_KEY="waterwatch_iot_esp8266_node_ingest_key_2026"
CORS_ORIGIN="*"

# Email Service
EMAIL_PROVIDER="resend" # or "smtp"
RESEND_API_KEY="re_your_api_key_here"
EMAIL_FROM="WaterWatch Support <onboarding@resend.dev>"

# OTP Rules
OTP_EXPIRY_MINUTES=10
OTP_RESEND_COOLDOWN_SECONDS=60
OTP_MAX_ATTEMPTS=5

# Initial Municipal Officer
INITIAL_OFFICER_NAME="Rajesh Varma"
INITIAL_OFFICER_EMAIL="officer@demo.com"
INITIAL_OFFICER_PASSWORD="Officer@123"
```

---

## 🧪 Testing

### Backend Automated Test Suite
Run the backend tests with Jest:
```bash
cd backend
npm test
```
*Coverage includes: Worker registration, duplicate email rejection, weak password rejection, role security, 6-digit OTP generation, SHA-256 hash validation, OTP attempt limits & expiration, login activation checks, password reset with OTP, and incident lifecycle transitions.*

### Flutter Static Analysis
```bash
flutter analyze
```

---

## 📱 Building the Android APK

Build the standalone Android release APK:
```bash
flutter build apk --release
```
The output APK is located at:
`build/app/outputs/flutter-apk/app-release.apk`
