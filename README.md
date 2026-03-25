# 🌍 UbuntuX: Redefining Communal Finance (Adashi/Ajo)

**UbuntuX** is a decentralized, AI-driven Rotating Savings and Credit Association (ROSCA) platform designed to bridge the trust gap in communal finance. By integrating **Interswitch's robust payment infrastructure** with an **AI Trust Engine**, we enable safe, transparent, and cross-border "Adashi" circles.

---

## 🏆 Hackathon MVP Features

### 1. 🛡️ Secure Identity (KYC)
- **Integration**: [Interswitch Identity API (BVN Full Details)](https://docs.interswitchgroup.com/docs/bvn-full-details).
- **Function**: Users verify their identity via BVN. Our system automatically synchronizes their official bank name with their UbuntuX profile, eliminating impersonation.
- **Impact**: Verified users receive a **+35 boost** to their AI Trust Score.

### 2. 💳 Smart Collections (Payments)
- **Integration**: [Interswitch Web Pay-Direct](https://docs.interswitchgroup.com/docs/web-pay-direct).
- **Function**: Members pay their monthly "shares" through a secure, mobile-optimized checkout.
- **UX**: Real-time pot updates and automated contribution tracking.

### 3. 💸 Verified Payouts (Disbursements)
- **Integration**: [Interswitch Transfer (Payout) API](https://docs.interswitchgroup.com/docs/payouts) & **Name Enquiry**.
- **Function**: Circle creators disburse the communal pot with confidence. The system performs a real-time **Name Enquiry** to ensure funds reach the correct member.
- **Innovation**: Supports **Cross-Border Payouts** (GBP/NGN) with live exchange rate conversion.

### 4. 🧠 AI Trust Engine
- **Logic**: A custom algorithm that calculates user reliability based on KYC status, contribution history, and circle participation.
- **Dynamic Scoring**: Trust scores update in real-time, influencing a user's ability to join high-value circles.

---

## 🛠️ Tech Stack
- **Mobile**: Flutter (Material 3, WebView, Dio).
- **Backend**: FastAPI (Python), SQLAlchemy, SQLite.
- **Security**: JWT Authentication, Bcrypt Password Hashing.
- **APIs**: Interswitch Passport (OAuth2), Collections, Identity, and Payouts.

---

## 👥 Team & Contributions

| Name | Role | Contributions |
| :--- | :--- | :--- |
| **Abdulshaheed Abdullahi** | **Team Lead / Fullstack** | Architected the Adashi logic, implemented Interswitch API integrations (OAuth2, BVN, Checkout), and developed the Flutter UI. |
| **Orjiakor David Cosmas** | **Product Designer** | [Description of contribution:  UI Design, Research, Testing] |

---

## 🚀 How to Run (Development)

### Backend
1. Navigate to `/backend`.
2. Install dependencies: `pip install fastapi uvicorn sqlalchemy bcrypt httpx`.
3. Run server: `py -m uvicorn main:app --reload`.

### Mobile
1. Navigate to `/mobile`.
2. Run app: `flutter run`.

---

## 📈 Future Roadmap
- [ ] PWA version for broader accessibility.
- [ ] Tiered savings yields via Interswitch investment APIs.
- [ ] Automated direct-debit shares via Interswitch Tokens.

---

**Built with ❤️ for the Enyata Hackathon 2026.**
