# Dealance - Where Startups Meet Capital 🚀

**Dealance** is a premium, professional platform designed to bridge the gap between visionary entrepreneurs and sophisticated investors. It streamlines the fundraising process through structured pitch workflows, AI-driven analysis, and secure communication.

## 🌟 Key Features

### For Entrepreneurs
- **Structured Pitch Workflow**: A professional 5-step process to upload problems, solutions, video pitches, and financial data.
- **AI Viability Report**: Get instant feedback on your startup idea using state-of-the-art AI (Groq/Gemini).
- **Privacy Controls**: Choose between Public, Invite Only, or NDA-protected visibility for your pitches.
- **Investor Discovery**: Find and connect with investors focused on your specific industry.

### For Investors
- **Curated Deal Flow**: A high-performance feed featuring vetted startup opportunities.
- **AI Quick-Summaries**: Instant, investor-focused summaries and risk assessments for every deal.
- **Secure Document Access**: Integrated NDA signing workflow to protect sensitive information.
- **Direct Messaging**: Real-time chat (Socket.IO) to communicate directly with founders.

## 🛠 Tech Stack

- **Frontend**: Flutter (Cross-platform support for iOS, Android, and Web)
- **Backend**: Node.js with Express & TypeScript
- **Database**: PostgreSQL with Prisma ORM
- **Real-time**: Socket.IO for instant messaging
- **AI Integration**: Groq (Llama 3.3 70B) & Google Gemini
- **Storage**: AWS S3 for pitch decks and media
- **Security**: JWT-based authentication with robust OTP (One-Time Password) verification

## 🏗 Architecture

The project is structured into two main components:
- `/lib`: The Flutter application containing the UI, providers, and services.
- `/backend`: The Node.js API service with Prisma schema and AI integrations.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Node.js v20+
- Docker & Docker Compose (optional, for local development)

### Backend Setup
1. `cd backend`
2. `npm install`
3. Configure your `.env` file (Database, SMTP, Groq/Gemini keys).
4. `npx prisma db push`
5. `npm run dev`

### Frontend Setup
1. `flutter pub get`
2. Configure `lib/services/api_service.dart` with your local/production API URL.
3. `flutter run`

---

## 🔒 Security & Robustness
The platform features a **Robust OTP System** that handles email delivery asynchronously, ensuring that SMTP timeouts never block the user experience. It also includes automatic IPv4 routing for cloud environments like Render to ensure maximum uptime.

---
*Built with ❤️ for the next generation of founders.*