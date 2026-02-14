# Arduino RFID → Browser Keyboard Input Setup

## Problem
Your Arduino is reading RFID cards correctly, but the card UID isn't appearing in the browser input field automatically.

## Solution Options

### Option 1: Arduino Leonardo/Micro (Keyboard Emulation) ⭐ RECOMMENDED
If you have Arduino Leonardo, Micro, or Due, you can make it act as a USB keyboard.

### Option 2: Arduino Uno (Serial Bridge)
If you have Arduino Uno, you'll need to use the Python bridge script.

---

## Option 1: Arduino Leonardo/Micro Setup

### Step 1: Upload Keyboard Code
1. Open `arduino_keyboard_rfid.ino` in Arduino IDE
2. Select your board: Tools → Board → Arduino Leonardo/Micro
3. Select your port: Tools → Port → COM9 (or your port)
4. Click Upload

### Step 2: Test
1. Open Notepad or any text editor
2. Scan an RFID card
3. The UID should appear automatically followed by Enter!

### Step 3: Use with Health App
1. Login to health app as admin
2. Go to RFID Scanner page
3. Click in the input field
4. Scan your RFID card
5. UID appears automatically and scans! ✨

### How It Works
- Arduino acts as USB keyboard
- When card is scanned, it types the UID
- Automatically presses Enter
- Browser receives it as keyboard input
- Real-time scanning triggers automatically

---

## Option 2: Arduino Uno Setup (Python Bridge)

Since Arduino Uno doesn't support Keyboard library, use the Python bridge:

### Step 1: Keep Current Arduino Code
Your current Arduino code is fine - it sends UID via Serial.

### Step 2: Run Python Bridge
```bash
cd health_app/backend
python rfid_reader.py
```

### Step 3: Scan Cards
- Python script reads from Arduino serial port
- Automatically calls the API
- Shows patient info in terminal
- No browser needed!

### Output Example
```
📱 Card Scanned: 51E4B217
------------------------------------------------------------

✅ PATIENT FOUND!
============================================================
Name:     Swathi H
ID:       4
Email:    swathi@example.com
Phone:    1234567890
Age:      25
============================================================

🏥 Open patient page: http://localhost/admin/patient/4
```

---

## Option 3: Manual Keyboard Emulator (Any Arduino)

If you want browser integration with Arduino Uno, you can use a software solution:

### Install AutoHotkey (Windows)
1. Download: https://www.autohotkey.com/
2. Create script to read serial and type to browser
3. More complex but works with any Arduino

---

## Which Option Should You Use?

### ✅ You Have Arduino Leonardo/Micro
→ Use **Option 1** (Keyboard Emulation)
- Upload `arduino_keyboard_rfid.ino`
- Works directly with browser
- No Python script needed
- Real-time scanning in browser

### ✅ You Have Arduino Uno
→ Use **Option 2** (Python Bridge)
- Keep current Arduino code
- Run `python rfid_reader.py`
- Works great for testing
- Shows patient info in terminal

### ✅ You Want Browser Integration with Uno
→ Use **Option 3** (AutoHotkey)
- More setup required
- Works with any Arduino
- Full browser integration

---

## Quick Test: Which Arduino Do You Have?

### Check Your Board
Look at your Arduino board:
- **Leonardo/Micro**: Has ATmega32u4 chip (native USB)
- **Uno**: Has ATmega328P chip + separate USB chip

### Test Keyboard Support
1. Upload this simple code:
```cpp
#include <Keyboard.h>

void setup() {
  Keyboard.begin();
}

void loop() {
  // Empty
}
```

2. If it compiles → You have Leonardo/Micro (use Option 1)
3. If error "Keyboard.h not found" → You have Uno (use Option 2)

---

## Recommended Setup for Your Hardware

Based on your image, you have an **Arduino Uno**, so:

### Best Solution: Python Bridge (Option 2)

1. **Keep your current Arduino code** (it's working!)

2. **Run the Python bridge**:
```bash
cd health_app/backend
python rfid_reader.py
```

3. **Scan cards**:
   - Place card near RC522 reader
   - Python script reads UID from serial
   - Automatically calls API
   - Shows patient info in terminal

4. **View in browser** (optional):
   - Copy the patient URL from terminal
   - Open in browser to see full details

### Why This Works Best
- ✅ No Arduino code changes needed
- ✅ Works with Arduino Uno
- ✅ Automatic API calls
- ✅ Shows patient info immediately
- ✅ No additional hardware needed

---

## Alternative: Upgrade to Leonardo/Micro

If you want true browser integration:
- Buy Arduino Leonardo or Micro (~$20)
- Upload `arduino_keyboard_rfid.ino`
- Works as USB keyboard
- Types directly into browser
- Perfect for production use

---

## Current Status

Your setup is working! The Arduino is reading cards correctly. You just need to choose how to send the data to the browser:

1. **Python Bridge** (works now with Uno)
2. **Keyboard Emulation** (needs Leonardo/Micro)
3. **AutoHotkey** (complex but works with Uno)

I recommend starting with the **Python Bridge** since your hardware is already working!

---

## Next Steps

1. Open a new terminal
2. Run: `cd health_app/backend`
3. Run: `python rfid_reader.py`
4. Scan your RFID card
5. See patient info appear automatically!

The Python script will:
- Auto-detect your Arduino port (COM9)
- Login as admin
- Read card UIDs
- Call the API
- Display patient information

Try it now! 🚀
