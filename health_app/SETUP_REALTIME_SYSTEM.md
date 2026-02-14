# Setup Real-Time Arduino WebSocket System

## Quick Setup (5 Minutes)

### Step 1: Install Python Dependencies
Open terminal in `health_app/backend`:
```bash
pip install websockets pyserial
```
✅ Done!

### Step 2: Install Flutter Dependencies
Open terminal in `health_app/frontend`:
```bash
flutter pub get
```

### Step 3: Start All Services

#### Option A: Use Batch Script (Windows)
Double-click: `START_REALTIME_SYSTEM.bat`

This will automatically start:
- Backend Server
- WebSocket Bridge  
- Flutter App

#### Option B: Manual Start (3 Terminals)

**Terminal 1 - Backend:**
```bash
cd health_app\backend
python main.py
```

**Terminal 2 - WebSocket Bridge:**
```bash
cd health_app\backend
python rfid_websocket_bridge.py
```

**Terminal 3 - Flutter App:**
```bash
cd health_app\frontend
flutter run -d chrome
```

## What You'll See

### Terminal 1 (Backend):
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

### Terminal 2 (WebSocket Bridge):
```
============================================================
🏥 HEALTH APP - REAL-TIME RFID WEBSOCKET BRIDGE
============================================================

✅ Auto-detected Arduino on: COM9
✅ WebSocket server started
✅ Connected to Arduino on COM9

🎴 RFID READER ACTIVE - Waiting for cards...
```

### Browser (Flutter App):
- Opens automatically in Chrome
- Login as admin
- Go to RFID Scanner
- See green badge: "Arduino Connected - Real-time Active"

## Test It!

1. **Scan RFID card** with Arduino
2. **Watch Terminal 2**:
   ```
   📱 Card Scanned: 51E4B217
   📤 Broadcasted to 1 client(s)
   ```
3. **Watch Browser**:
   - Dialog appears instantly!
   - Patient info displayed
   - Click "View Medical History"

## System Architecture

```
┌─────────────────┐
│  Arduino RFID   │ Reads card
│   (COM9)        │
└────────┬────────┘
         │ USB Serial
         ↓
┌─────────────────┐
│  WebSocket      │ Broadcasts
│  Bridge         │ to clients
│  (Port 8765)    │
└────────┬────────┘
         │ WebSocket
         ↓
┌─────────────────┐
│  Flutter Web    │ Receives
│  App (Browser)  │ instantly
└────────┬────────┘
         │ HTTP API
         ↓
┌─────────────────┐
│  Backend API    │ Looks up
│  (Port 8000)    │ patient
└────────┬────────┘
         │ SQL
         ↓
┌─────────────────┐
│  SQLite DB      │ Returns
│  (health_app.db)│ data
└─────────────────┘
```

## Features

✅ **Real-Time**: Card appears in browser instantly
✅ **Multi-Client**: Multiple browsers can connect
✅ **Auto-Reconnect**: Handles disconnections gracefully
✅ **Duplicate Prevention**: Won't scan same card twice
✅ **Visual Feedback**: Green/orange status indicators
✅ **Fallback Mode**: Works manually if WebSocket fails

## Troubleshooting

### "COM9 Access Denied"
- Close Arduino IDE Serial Monitor
- Unplug and replug Arduino
- Try different USB port

### "WebSocket Won't Connect"
- Check if bridge is running (Terminal 2)
- Check firewall settings
- Restart browser

### "Manual Mode" in Browser
- WebSocket bridge not running
- Start: `python rfid_websocket_bridge.py`
- Check Terminal 2 for errors

## Test Cards

- `51E4B217` → Swathi H (Patient ID: 4)
- `CARD001` → John Doe (Patient ID: 3)

## Next Steps

1. Run the batch script or start services manually
2. Login as admin (admin@health.com / admin123)
3. Go to RFID Scanner page
4. Look for green "Arduino Connected" badge
5. Scan your RFID card
6. Watch it appear instantly! ✨

## Documentation

- `REALTIME_ARDUINO_WEBSOCKET_GUIDE.md` - Complete guide
- `START_RFID_HARDWARE.md` - Hardware setup
- `ARDUINO_KEYBOARD_SETUP.md` - Alternative methods

---

**Status**: ✅ System ready to use!
**Mode**: Real-time WebSocket communication
**Speed**: Instant (< 100ms latency)
