# 🚀 Real-Time Arduino ↔ WebApp Communication

## System Architecture

```
Arduino RFID Reader (COM9)
         ↓ Serial USB
WebSocket Bridge (Python)
         ↓ WebSocket (Port 8765)
Web Browser (Flutter App)
         ↓ HTTP API
Backend Server (FastAPI)
         ↓ Database
SQLite (health_app.db)
```

## How It Works

1. **Arduino** reads RFID card → Sends UID via serial
2. **WebSocket Bridge** receives UID → Broadcasts to all web clients
3. **Flutter App** receives UID instantly → Calls API
4. **Backend API** looks up patient → Returns data
5. **Flutter App** shows patient dialog → Navigate to details

## Setup Instructions

### Step 1: Install Python Dependencies
```bash
cd health_app\backend
pip install websockets pyserial
```

### Step 2: Start Backend Server
```bash
cd health_app\backend
python main.py
```
✅ Backend running on http://127.0.0.1:8000

### Step 3: Start WebSocket Bridge
Open a NEW terminal:
```bash
cd health_app\backend
python rfid_websocket_bridge.py
```

You should see:
```
============================================================
🏥 HEALTH APP - REAL-TIME RFID WEBSOCKET BRIDGE
============================================================

📡 Available Serial Ports:
--------------------------------------------------
  COM9 - USB Serial Device (COM9)
--------------------------------------------------

✅ Auto-detected Arduino on: COM9

🌐 Starting WebSocket server on ws://0.0.0.0:8765
✅ WebSocket server started
✅ Connected to Arduino on COM9

============================================================
🎴 RFID READER ACTIVE - Waiting for cards...
============================================================

WebSocket clients can connect to:
ws://0.0.0.0:8765

Place an RFID card near the reader to scan.
Press Ctrl+C to stop.
```

### Step 4: Install Flutter Dependencies
Open a NEW terminal:
```bash
cd health_app\frontend
flutter pub get
```

### Step 5: Start Flutter App
```bash
cd health_app\frontend
flutter run -d chrome
```

### Step 6: Test Real-Time Scanning

1. **Login** as admin (admin@health.com / admin123)
2. **Go to RFID Scanner** (6th menu item)
3. **Look for green badge**: "Arduino Connected - Real-time Active"
4. **Scan RFID card** with Arduino
5. **Watch it appear instantly** in the browser! ✨

## What Happens When You Scan

### Terminal 1 (Backend):
```
INFO: 127.0.0.1:xxxxx - "POST /api/rfid/scan HTTP/1.1" 200 OK
```

### Terminal 2 (WebSocket Bridge):
```
📱 Card Scanned: 51E4B217
------------------------------------------------------------
📤 Broadcasted to 1 client(s)
✅ Sent to web clients
============================================================
```

### Browser (Flutter App):
```
🔌 Connecting to RFID WebSocket...
✅ WebSocket connected
📨 WebSocket message received: {type: rfid_scan, card_uid: 51E4B217}
🎴 Arduino scanned card: 51E4B217
🎴 Scanning card UID: 51E4B217
📡 Calling API with card UID: 51E4B217
✅ RFID Scan Success: {patient_id: 4, full_name: Swathi H, ...}
🔔 Showing dialog...
```

## Features

### ✅ Real-Time Communication
- Arduino → WebSocket → Browser (instant!)
- No polling, no delays
- True push notifications

### ✅ Multiple Clients
- Multiple browsers can connect
- All receive card scans simultaneously
- Perfect for multiple admin stations

### ✅ Auto-Reconnect
- WebSocket reconnects automatically
- Handles network interruptions
- Graceful fallback to manual mode

### ✅ Duplicate Prevention
- Won't scan same card twice in 2 seconds
- Prevents accidental double-scans
- Clean user experience

### ✅ Visual Feedback
- Green badge: "Arduino Connected"
- Orange badge: "Manual Mode" (if WebSocket fails)
- Real-time status updates
- Loading indicators

## Testing Without Arduino

You can test the WebSocket system without Arduino:

### Option 1: Simulate Card Scan (Python)
```python
import asyncio
import websockets
import json

async def simulate_scan():
    uri = "ws://localhost:8765"
    async with websockets.connect(uri) as websocket:
        # Simulate scanning Swathi's card
        message = {
            'type': 'rfid_scan',
            'card_uid': '51E4B217',
            'timestamp': '2024-01-01T12:00:00'
        }
        await websocket.send(json.dumps(message))
        print("Sent simulated scan!")

asyncio.run(simulate_scan())
```

### Option 2: Manual Entry
- Just type the card UID in the input field
- Real-time detection still works
- No Arduino needed for testing

## Troubleshooting

### WebSocket Won't Connect

**Check if bridge is running:**
```bash
# Should see WebSocket bridge terminal
```

**Check port 8765:**
```bash
netstat -an | findstr 8765
```

**Firewall blocking?**
- Allow Python through Windows Firewall
- Or use localhost only (already configured)

### Arduino Not Detected

**Close Arduino IDE Serial Monitor:**
- COM port can only be used by one program
- Close Serial Monitor before running bridge

**Check COM port:**
```bash
# In Device Manager, look for Arduino
# Update SERIAL_PORT in rfid_websocket_bridge.py if needed
```

**Unplug and replug:**
- Sometimes helps reset the connection

### Browser Shows "Manual Mode"

**WebSocket bridge not running:**
- Start: `python rfid_websocket_bridge.py`

**Wrong WebSocket URL:**
- Check: `ws://127.0.0.1:8765`
- Update in `rfid_websocket_service.dart` if needed

**Network issue:**
- Check firewall
- Try restarting browser

### Card Scans But Nothing Happens

**Check browser console (F12):**
- Look for WebSocket messages
- Look for API call results

**Check backend is running:**
- http://127.0.0.1:8000 should respond

**Check card is registered:**
- Use test cards: 51E4B217 or CARD001

## Running All Services

You need 3 terminals:

### Terminal 1: Backend
```bash
cd health_app\backend
python main.py
```

### Terminal 2: WebSocket Bridge
```bash
cd health_app\backend
python rfid_websocket_bridge.py
```

### Terminal 3: Frontend
```bash
cd health_app\frontend
flutter run -d chrome
```

## Production Deployment

For a real clinic/hospital:

### Option A: Single Server
- Run all services on one computer
- Arduino connected via USB
- Multiple browsers connect via network

### Option B: Distributed
- Arduino + Bridge on reception desk
- Backend on server
- Browsers on any computer in network

### Option C: Cloud
- Backend on cloud server (AWS, Azure, etc.)
- Arduino + Bridge on local computer
- WebSocket over internet (use WSS for security)

## Security Considerations

### For Production:

1. **Use WSS (Secure WebSocket)**
   ```python
   # Add SSL certificate
   ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
   ssl_context.load_cert_chain('cert.pem', 'key.pem')
   ```

2. **Add Authentication**
   ```python
   # Verify admin token before accepting WebSocket
   ```

3. **Rate Limiting**
   ```python
   # Prevent spam/abuse
   ```

4. **Firewall Rules**
   - Only allow internal network
   - Or use VPN for remote access

## Benefits Over Previous System

### Before (Python Bridge Only):
- ❌ Terminal-only output
- ❌ No browser integration
- ❌ Manual copy-paste patient ID
- ❌ Separate workflow

### Now (WebSocket Real-Time):
- ✅ Instant browser updates
- ✅ Automatic patient lookup
- ✅ Dialog appears immediately
- ✅ Seamless workflow
- ✅ Multiple clients supported
- ✅ Professional user experience

## Test Cards

- `51E4B217` → Swathi H (Patient ID: 4)
- `CARD001` → John Doe (Patient ID: 3)

## Next Steps

1. Start all 3 services (backend, bridge, frontend)
2. Login as admin
3. Go to RFID Scanner page
4. Look for green "Arduino Connected" badge
5. Scan your RFID card
6. Watch the magic happen! ✨

The card UID will appear instantly in the browser, trigger the API call, and show the patient dialog - all in real-time!

## Advanced: Custom WebSocket Messages

You can extend the system to send custom messages:

### From Arduino to Browser:
```python
# In rfid_websocket_bridge.py
message = {
    'type': 'custom_event',
    'data': 'your_data',
    'timestamp': datetime.now().isoformat()
}
await broadcast_to_clients(message)
```

### From Browser to Arduino:
```dart
// In Flutter
_wsService.sendMessage({
  'type': 'command',
  'action': 'beep',
});
```

The system is fully extensible for future features! 🚀
