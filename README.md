# Solis — museum & auction app

```
backend/   Node + Express + MongoDB API (auth, collection, auctions, events)
app/       Flutter client (Solis UI from /artimages)
```

## 1. Backend
```bash
cd backend
# put your MongoDB URL in .env  ->  MONGODB_URI=mongodb+srv://...
npm run seed      # loads artworks, auctions, events
npm run dev       # http://localhost:4000  (health: /health)
```
`.env` already has random JWT secrets generated. Never commit `.env`.

## 2. App
```bash
cd app
flutter run                                   # Android emulator uses 10.0.2.2:4000 automatically
flutter run --dart-define=API_URL=http://<your-LAN-IP>:4000   # physical device
```
> On Windows, enable Developer Mode (`start ms-settings:developers`) so Flutter plugins can build.

## Auth
- bcrypt (12 rounds) password hashing, password policy (8+ chars, letter + number)
- Short-lived JWT access token (15 min) + opaque refresh token (30 days), stored hashed in MongoDB
- Refresh-token rotation with reuse detection (a replayed token revokes the whole session family)
- Tokens stored in Keychain/Keystore via `flutter_secure_storage`; client auto-refreshes on 401 (single-flight)
- Rate-limited auth endpoints, helmet, input validation (zod), change password revokes all sessions

## Features
Discover (featured live lot + auction carousel) · Collection bento (series, exhibition, live lot, saved filter, search) ·
Lot detail with atomic bidding (+$100/250/500, race-safe) & bid history · Events week strip, booking with capacity ·
Profile: my bids (leading/outbid/won), bookings, saved works, edit name / password.
