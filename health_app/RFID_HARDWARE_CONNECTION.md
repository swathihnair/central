# How to Connect RFID Hardware to Software

## Overview
Your RFID reader (RC522) connects to Arduino, which then connects to your computer via USB. The Arduino acts as a **USB keyboard**, automatically typing the card UID into the focused input field.

## 🔌 Hardware Connection

### Step 1: Wire the RFID-RC522 to Arduino

Based on your image, connect:

```
RFID-RC522 Pin    →    Arduino Pin
─────────────────────────────────
SDA (SS)          →    Pin 10
SCK               →    Pin 13
MOSI              →    Pin 11
MISO              →    Pin 12
IRQ               →    Not connected
GND               →    GND
RST               →    Pin 9
3.3V              →    3.3V (NOT 5V!)
```

⚠️ **Important**: Use 3.3V, not 5V! The RC522 module can be damaged by 5V.

### Step 2: Upload Arduino Code

Install required library first:
1. Open Arduino IDE
2. Go to: Sketch → Include Library → Manage Libraries
3. Search for "MFRC522"
4. Install "MFRC522 by GithubCommunity"

Upload this code to your Arduino:

```cpp
#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 10
#define RST_PIN 9

MFRC522 mfrc522(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(9600);
  SPI.begin();
  mfrc522.PCD_Init();
  Serial.println("RFID Reader Ready. Scan a card...");
}

void loop() {
  // Look for new cards
  if (!mfrc522.PICC_IsNewCardPresent()) {
    return;
  }

  // Select one of the cards
  if (!mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  // Build card UID string
  String cardUID = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    if (mfrc522.uid.uidByte[i] < 0x10) {
      cardUID += "0";  // Add leading zero
    }
    cardUID += String(mfrc522.uid.uidByte[i], HEX);
  }
  cardUID.toUpperCase();

  // Print UID to Serial (will be sent to computer)
  Serial.println(cardUID);

  // Halt PICC
  mfrc522.PICC_HaltA();
  
  delay(1000); // Prevent multiple reads
}
```

### Step 3: Test Arduino Connection

1. Open Arduino IDE Serial Monitor (Tools → Serial Monitor)
2. Set baud rate to 9600
3. Scan a card
4. You should see the UID printed (e.g., `51E4B217`)

## 💻 Software Connection Methods

### Method 1: Serial Port Reading (Recommended for Production)

This method reads directly from the Arduino's serial port.

#### Option A: Python Script Bridge

Create `health_app/backend/rfid_reader.py`:

```python
import serial
import requests
import time

# Configuration
SERIAL_PORT = 'COM3'  # Change to your Arduino port (COM3, COM4, etc.)
BAUD_RATE = 9600
API_URL = 'http://127.0.0.1:8000/api/rfid/scan'
ADMIN_TOKEN = 'your_admin_token_here'  # Get from login

def read_rfid():
    try:
        # Open serial connection
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        print(f"Connected to {SERIAL_PORT}")
        print("Waiting for RFID cards...")
        
        while True:
            if ser.in_waiting > 0:
                # Read card UID
                card_uid = ser.readline().decode('utf-8').strip()
                
                if card_uid and len(card_uid) > 0:
                    print(f"\n📱 Card scanned: {card_uid}")
                    
                    # Send to API
                    try:
                        response = requests.post(
                            API_URL,
                            json={'card_uid': card_uid},
                            headers={'Authorization': f'Bearer {ADMIN_TOKEN}'}
                        )
                        
                        if response.status_code == 200:
                            patient = response.json()
                            print(f"✅ Patient found: {patient['full_name']}")
                            print(f"   ID: {patient['patient_id']}")
                            print(f"   Email: {patient['email']}")
                        else:
                            print(f"❌ Card not registered")
                    except Exception as e:
                        print(f"❌ API Error: {e}")
                    
                    print("\nWaiting for next card...")
            
            time.sleep(0.1)
    
    except serial.SerialException as e:
        print(f"❌ Serial port error: {e}")
        print(f"Make sure Arduino is connected to {SERIAL_PORT}")
    except KeyboardInterrupt:
        print("\n\nStopping RFID reader...")
        ser.close()

if __name__ == "__main__":
    # Install required: pip install pyserial requests
    read_rfid()
```

Run it:
```bash
cd health_app/backend
pip install pyserial requests
python rfid_reader.py
```

#### Option B: Node.js Bridge (Alternative)

```javascript
const SerialPort = require('serialport');
const Readline = require('@serialport/parser-readline');
const axios = require('axios');

const port = new SerialPort('COM3', { baudRate: 9600 });
const parser = port.pipe(new Readline({ delimiter: '\n' }));

const API_URL = 'http://127.0.0.1:8000/api/rfid/scan';
const ADMIN_TOKEN = 'your_admin_token_here';

parser.on('data', async (cardUID) => {
  cardUID = cardUID.trim();
  console.log(`📱 Card scanned: ${cardUID}`);
  
  try {
    const response = await axios.post(API_URL, 
      { card_uid: cardUID },
      { headers: { 'Authorization': `Bearer ${ADMIN_TOKEN}` }}
    );
    
    console.log(`✅ Patient: ${response.data.full_name}`);
  } catch (error) {
    console.log('❌ Card not registered');
  }
});
```

### Method 2: USB Keyboard Emulation (Current Implementation)

This is what your app currently uses - Arduino acts as a keyboard.

#### How It Works:
1. Arduino sends card UID via Serial
2. You manually copy the UID from Serial Monitor
3. Paste it into the RFID Scanner input field
4. Press Enter

#### For Automatic Keyboard Input:

You need an Arduino board with native USB support (Leonardo, Micro, or Due):

```cpp
#include <SPI.h>
#include <MFRC522.h>
#include <Keyboard.h>  // Only works on Leonardo/Micro/Due

#define SS_PIN 10
#define RST_PIN 9

MFRC522 mfrc522(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(9600);
  SPI.begin();
  mfrc522.PCD_Init();
  Keyboard.begin();  // Initialize keyboard emulation
  Serial.println("RFID Reader Ready");
}

void loop() {
  if (!mfrc522.PICC_IsNewCardPresent()) {
    return;
  }

  if (!mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  String cardUID = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    if (mfrc522.uid.uidByte[i] < 0x10) {
      cardUID += "0";
    }
    cardUID += String(mfrc522.uid.uidByte[i], HEX);
  }
  cardUID.toUpperCase();

  // Type the UID as keyboard input
  Keyboard.print(cardUID);
  Keyboard.press(KEY_RETURN);  // Press Enter
  Keyboard.release(KEY_RETURN);

  Serial.println(cardUID);
  mfrc522.PICC_HaltA();
  delay(1000);
}
```

## 🎯 Recommended Setup for Your System

Since you have Arduino Uno (based on your image), use **Method 1 - Python Script Bridge**:

### Quick Setup:

1. **Upload Arduino code** (first code example above)
2. **Find your COM port**:
   - Windows: Device Manager → Ports (COM & LPT)
   - Look for "Arduino Uno (COMx)"
3. **Install Python dependencies**:
   ```bash
   pip install pyserial requests
   ```
4. **Get admin token**:
   - Login to app as admin
   - Open browser DevTools (F12)
   - Go to Application → Local Storage
   - Copy the "token" value
5. **Update rfid_reader.py**:
   - Set `SERIAL_PORT = 'COM3'` (your port)
   - Set `ADMIN_TOKEN = 'your_token'`
6. **Run the bridge**:
   ```bash
   python rfid_reader.py
   ```

Now when you scan a card, it will automatically:
- Read the UID from Arduino
- Send it to your API
- Display patient information
- You can then open the patient's page in the web app

## 🔍 Finding Your COM Port

### Windows:
```bash
# PowerShell
Get-WmiObject Win32_SerialPort | Select-Object Name, DeviceID

# Or check Device Manager
devmgmt.msc
```

### Linux/Mac:
```bash
ls /dev/tty*
# Look for /dev/ttyUSB0 or /dev/ttyACM0
```

## 🐛 Troubleshooting

### Arduino not detected:
- Install Arduino drivers
- Try different USB cable
- Check Device Manager

### Serial port access denied:
- Close Arduino IDE Serial Monitor
- Close any other serial programs
- Run Python script as administrator

### Card not reading:
- Check 3.3V connection (not 5V!)
- Verify wiring matches diagram
- Test with Arduino Serial Monitor first
- Card must be close to reader (< 3cm)

### Wrong UID format:
- Make sure code includes leading zeros
- Use `.toUpperCase()` for consistency
- Check that spaces are removed

## 📱 Integration with Web App

Once the Python bridge is running:

1. **Automatic Mode**: Bridge sends card data to API automatically
2. **Manual Mode**: Open RFID Scanner page in web app, type UID manually
3. **Hybrid Mode**: Bridge prints UID, you copy/paste into web app

The web app is already configured to accept card UIDs in the RFID Scanner page!

## 🎉 You're All Set!

Your hardware setup is complete. The software is ready to receive card UIDs either:
- Via the Python bridge (automatic)
- Via manual entry in the RFID Scanner page
- Via keyboard emulation (if using Leonardo/Micro)

Test with Swathi's card: `51E4B217`
