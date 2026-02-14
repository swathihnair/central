/*
 * RFID Reader with Keyboard Emulation
 * Reads RFID cards and sends UID as keyboard input to computer
 * 
 * Hardware: Arduino Leonardo/Micro + RC522 RFID Module
 * Note: Only Leonardo/Micro/Due support Keyboard library
 * 
 * Wiring:
 * RC522 -> Arduino
 * SDA  -> Pin 10
 * SCK  -> Pin 13
 * MOSI -> Pin 11
 * MISO -> Pin 12
 * IRQ  -> Not connected
 * GND  -> GND
 * RST  -> Pin 9
 * 3.3V -> 3.3V
 */

#include <SPI.h>
#include <MFRC522.h>
#include <Keyboard.h>  // Only works on Leonardo/Micro/Due

#define RST_PIN 9
#define SS_PIN 10

MFRC522 mfrc522(SS_PIN, RST_PIN);

String lastUID = "";
unsigned long lastScanTime = 0;
const unsigned long SCAN_DELAY = 2000; // 2 seconds between scans

void setup() {
  Serial.begin(9600);
  SPI.begin();
  mfrc522.PCD_Init();
  Keyboard.begin();  // Initialize keyboard emulation
  
  Serial.println("RFID Reader with Keyboard Emulation Ready!");
  Serial.println("Place card near reader...");
  
  // Blink LED to show ready
  pinMode(LED_BUILTIN, OUTPUT);
  for(int i = 0; i < 3; i++) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(200);
    digitalWrite(LED_BUILTIN, LOW);
    delay(200);
  }
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
    if (mfrc522.uid.uidByte[i] < 0x10) {
      cardUID += "0";
    }
    cardUID += String(mfrc522.uid.uidByte[i], HEX);
  }
  cardUID.toUpperCase();

  // Check if this is a duplicate scan
  unsigned long currentTime = millis();
  if (cardUID == lastUID && (currentTime - lastScanTime) < SCAN_DELAY) {
    // Ignore duplicate scan
    mfrc522.PICC_HaltA();
    return;
  }

  // Update last scan info
  lastUID = cardUID;
  lastScanTime = currentTime;

  // Print to Serial Monitor
  Serial.print("Card UID: ");
  Serial.println(cardUID);

  // Send UID as keyboard input
  Keyboard.print(cardUID);
  delay(100);
  Keyboard.press(KEY_RETURN);  // Press Enter
  delay(50);
  Keyboard.release(KEY_RETURN);  // Release Enter

  // Visual feedback
  digitalWrite(LED_BUILTIN, HIGH);
  delay(200);
  digitalWrite(LED_BUILTIN, LOW);

  // Halt PICC
  mfrc522.PICC_HaltA();
  
  Serial.println("Sent to computer as keyboard input!");
  Serial.println("Ready for next card...");
}
