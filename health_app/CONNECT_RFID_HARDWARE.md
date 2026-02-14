# Quick Guide: Connect RFID Hardware

## 🎯 Simple 3-Step Process

### Step 1: Upload Arduino Code (5 minutes)

1. Open Arduino IDE
2. Install MFRC522 library:
   - Sketch → Include Library → Manage Libraries
   - Search "MFRC522"
   - Install "MFRC522 by GithubCommunity"

3. Copy this code and upload to Arduino:

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
  Serial.println("RFID Reader Ready");
}

void loop() {
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  String cardUID = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    if (mfrc522.uid.uidByte[i] < 0x10) cardUID += "0";
    cardUID += String(mfrc522.uid.uidByte[i], HEX);
  }
  cardUID.toUpperCase();
  
  Serial.println(cardUID);
  mfrc522.PICC_HaltA();
  delay(1000);
}
```

4. Click Upload button
5. Wait for "Done uploading"

### Step 2: Install Python Library (1 minute)

```bash
pip install pyserial
```

### Step 3: Run the Bridge (1 command)

```bash
cd health_app/backend
python rfid_reader.py
```

That's it! The bridge will:
- ✅ Auto-detect your Arduino
- ✅ Auto-login as admin
- ✅ Start reading cards
- ✅ Display patient info automatically

## 📱 Test It

1. Run the bridge: `python rfid_reader.py`
2. Scan Swathi's card (UID: 51E4B217)
3. See patient info appear instantly!

## 🎴 Your Registered Cards

| Card UID  | Patient Name | Status |
|-----------|--------------|--------|
| 51E4B217  | Swathi H     | ✅ Active |
| CARD001   | John Doe     | ✅ Active |

## 🔧 Troubleshooting

**"No serial ports found"**
- Plug in Arduino via USB
- Install Arduino drivers

**"Serial port error"**
- Close Arduino IDE Serial Monitor
- Try different USB port
- Check COM port in Device Manager

**"Card not registered"**
- Card UID not in database
- Run: `python assign_rfid_test.py` to add test cards

## 📖 Full Documentation

See `RFID_HARDWARE_CONNECTION.md` for:
- Detailed wiring diagram
- Alternative connection methods
- Advanced configuration
- Keyboard emulation setup

## 🎉 Quick Test Without Hardware

Don't have hardware connected? Test manually:

1. Login as admin in web app
2. Go to "RFID Scanner" page
3. Type: `51E4B217`
4. Press Enter
5. See Swathi's info!

The software is ready - hardware is optional for testing!
