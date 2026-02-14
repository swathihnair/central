# RFID Scanner Feature Guide

## Overview
The RFID Scanner feature allows administrators to quickly identify patients by scanning their RFID cards and instantly access their medical history.

## Hardware Setup

### Required Components
- **RFID Reader**: RFID-RC522 module (as shown in your image)
- **Arduino/Microcontroller**: Arduino Uno or similar
- **RFID Cards**: MIFARE Classic 1K cards or compatible

### Wiring (RFID-RC522 to Arduino)
```
RFID-RC522    Arduino
---------     -------
SDA/SS    ->  Pin 10
SCK       ->  Pin 13
MOSI      ->  Pin 11
MISO      ->  Pin 12
IRQ       ->  Not connected
GND       ->  GND
RST       ->  Pin 9
3.3V      ->  3.3V
```

### Arduino Code
Upload this code to your Arduino to make it act as a USB keyboard:

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

  // Get card UID
  String cardUID = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    cardUID += String(mfrc522.uid.uidByte[i], HEX);
  }
  cardUID.toUpperCase();

  // Send UID via Serial (acts as keyboard input)
  Serial.println(cardUID);

  // Halt PICC
  mfrc522.PICC_HaltA();
  
  delay(1000); // Prevent multiple reads
}
```

## Software Setup

### 1. Backend Setup (Already Configured)
The backend includes:
- RFID card assignment endpoint
- Card scanning endpoint
- Patient lookup by card UID

### 2. Assign RFID Cards to Patients

Run the test script to assign cards:
```bash
cd health_app/backend
python assign_rfid_test.py
```

This will assign test card UIDs to existing patients:
- CARD001 → First patient
- CARD002 → Second patient
- CARD003 → Third patient
- etc.

### 3. Manual Card Assignment (via API)

You can also assign cards manually through the API:

```bash
curl -X POST http://127.0.0.1:8000/api/rfid/assign \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "card_uid": "A1B2C3D4",
    "patient_id": 1
  }'
```

## Using the RFID Scanner

### For Administrators:

1. **Login as Admin**
   - Email: admin@health.com
   - Password: admin123

2. **Navigate to RFID Scanner**
   - Click on "RFID Scanner" in the left navigation menu
   - You'll see the scanner interface

3. **Scan a Card**
   - Make sure the input field is focused (click on it)
   - Place the RFID card near the reader
   - The card UID will be automatically entered
   - Press Enter or click "Manual Scan"

4. **View Patient Information**
   - Patient details will appear in a dialog
   - Click "View Medical History" to see full patient records
   - You'll be redirected to the patient details page with all reports

### Alternative: Manual Entry
If the RFID reader is not connected, you can manually enter the card UID:
1. Type the card UID in the input field
2. Press Enter or click "Manual Scan"

## Testing Without Hardware

### Test Card UIDs
Use these test UIDs to simulate card scanning:
- `CARD001` - Patient 1
- `CARD002` - Patient 2  
- `CARD003` - Patient 3
- `A1B2C3D4` - Additional test card
- `12345678` - Additional test card

### Testing Steps:
1. Login as admin
2. Go to RFID Scanner page
3. Type `CARD001` in the input field
4. Press Enter
5. Patient information should appear
6. Click "View Medical History"

## API Endpoints

### Assign RFID Card
```
POST /api/rfid/assign
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "card_uid": "A1B2C3D4",
  "patient_id": 1
}
```

### Scan RFID Card
```
POST /api/rfid/scan
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "card_uid": "A1B2C3D4"
}

Response:
{
  "patient_id": 1,
  "full_name": "John Doe",
  "email": "patient@health.com",
  "phone": "1234567890",
  "age": 30
}
```

### Get Patient's RFID Card
```
GET /api/rfid/patient/{patient_id}
Authorization: Bearer {admin_token}

Response:
{
  "card_uid": "A1B2C3D4",
  "assigned_at": "2026-02-14T10:30:00"
}
```

### Unassign RFID Card
```
DELETE /api/rfid/unassign/{card_uid}
Authorization: Bearer {admin_token}
```

## Features

### ✅ Implemented
- RFID card assignment to patients
- Card scanning with patient lookup
- Automatic redirect to patient medical history
- Manual card UID entry option
- Card activation/deactivation
- Admin-only access control

### 🔄 How It Works
1. Admin scans patient's RFID card
2. System looks up card UID in database
3. Retrieves associated patient information
4. Displays patient details in dialog
5. Redirects to patient details page with full medical history
6. Shows all reports, vitals, and appointments

## Security Features
- Admin-only access to RFID functionality
- Card UIDs are unique and indexed
- Cards can be deactivated without deletion
- All operations require authentication

## Troubleshooting

### Card Not Recognized
- Ensure the card is assigned in the database
- Check if the card is active (not deactivated)
- Verify the card UID matches exactly

### Scanner Not Working
- Check Arduino connection (USB)
- Verify Serial port is correct
- Ensure input field is focused
- Try manual entry to test backend

### Patient Not Found
- Verify patient exists in database
- Check card assignment is correct
- Ensure patient role is "patient"

## Future Enhancements
- [ ] Real-time card scanning without Enter key
- [ ] Card assignment UI in admin dashboard
- [ ] Bulk card assignment
- [ ] Card usage history/audit log
- [ ] Support for multiple card types
- [ ] Card printing integration

## Support
For issues or questions, refer to the main documentation or check the backend logs.
