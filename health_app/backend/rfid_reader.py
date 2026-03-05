"""
RFID Reader Bridge - Connects Arduino RFID reader to Health App API
Reads card UIDs from serial port and sends to backend API
"""
import serial
import serial.tools.list_ports
import requests
import time
import sys

# Configuration
SERIAL_PORT = 'COM3'  # Your Arduino port (auto-detected if possible)
BAUD_RATE = 9600
API_URL = 'http://127.0.0.1:8000/api/rfid/scan'

def list_serial_ports():
    """List all available serial ports"""
    ports = serial.tools.list_ports.comports()
    print("\n📡 Available Serial Ports:")
    print("-" * 50)
    for port in ports:
        print(f"  {port.device} - {port.description}")
    print("-" * 50)
    return [port.device for port in ports]

def get_admin_token():
    """Get admin token by logging in"""
    print("\n🔐 Logging in as admin...")
    try:
        response = requests.post(
            'http://127.0.0.1:8000/api/auth/login',
            json={
                'email': 'admin@health.com',
                'password': 'admin123',
                'role': 'admin'
            }
        )
        if response.status_code == 200:
            token = response.json()['access_token']
            print("✅ Login successful!")
            return token
        else:
            print(f"❌ Login failed: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Login error: {e}")
        return None

def scan_card(card_uid, token):
    """Send card UID to API and get patient info"""
    try:
        response = requests.post(
            API_URL,
            json={'card_uid': card_uid},
            headers={'Authorization': f'Bearer {token}'},
            timeout=5
        )
        
        if response.status_code == 200:
            patient = response.json()
            print(f"\n✅ PATIENT FOUND!")
            print("=" * 60)
            print(f"Name:     {patient['full_name']}")
            print(f"ID:       {patient['patient_id']}")
            print(f"Email:    {patient['email']}")
            if patient.get('phone'):
                print(f"Phone:    {patient['phone']}")
            if patient.get('age'):
                print(f"Age:      {patient['age']}")
            print("=" * 60)
            print(f"\n🏥 Open patient page: http://localhost/admin/patient/{patient['patient_id']}")
            return True
        else:
            error = response.json().get('detail', 'Unknown error')
            print(f"\n❌ Card not registered: {error}")
            return False
    except requests.exceptions.Timeout:
        print("\n❌ API timeout - is the backend running?")
        return False
    except Exception as e:
        print(f"\n❌ API Error: {e}")
        return False

def read_rfid(port, token):
    """Main RFID reading loop"""
    try:
        # Open serial connection
        ser = serial.Serial(port, BAUD_RATE, timeout=1)
        print(f"\n✅ Connected to {port}")
        print("\n" + "=" * 60)
        print("🎴 RFID READER ACTIVE - Waiting for cards...")
        print("=" * 60)
        print("\nPlace an RFID card near the reader to scan.")
        print("Press Ctrl+C to stop.\n")
        
        last_card = ""
        last_time = 0
        
        while True:
            if ser.in_waiting > 0:
                # Read card UID
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                
                # Filter out debug messages
                if line and len(line) >= 8 and not line.startswith('RFID'):
                    card_uid = line.upper()
                    current_time = time.time()
                    
                    # Prevent duplicate reads (within 2 seconds)
                    if card_uid != last_card or (current_time - last_time) > 2:
                        print(f"\n📱 Card Scanned: {card_uid}")
                        print("-" * 60)
                        
                        # Send to API
                        scan_card(card_uid, token)
                        
                        last_card = card_uid
                        last_time = current_time
                        
                        print("\n" + "=" * 60)
                        print("Ready for next card...")
                        print("=" * 60 + "\n")
            
            time.sleep(0.1)
    
    except serial.SerialException as e:
        print(f"\n❌ Serial port error: {e}")
        print(f"\nTroubleshooting:")
        print(f"  1. Make sure Arduino is connected to {port}")
        print(f"  2. Close Arduino IDE Serial Monitor if open")
        print(f"  3. Try a different COM port")
        print(f"  4. Check available ports above")
        return False
    except KeyboardInterrupt:
        print("\n\n⏹️  Stopping RFID reader...")
        ser.close()
        print("✅ Disconnected. Goodbye!")
        return True
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        return False

def main():
    print("\n" + "=" * 60)
    print("🏥 HEALTH APP - RFID READER BRIDGE")
    print("=" * 60)
    
    # List available ports
    available_ports = list_serial_ports()
    
    if not available_ports:
        print("\n❌ No serial ports found!")
        print("   Make sure Arduino is connected via USB.")
        sys.exit(1)
    
    # Auto-detect Arduino port
    arduino_port = None
    for port in available_ports:
        if 'Arduino' in port or 'USB' in port or 'ACM' in port:
            arduino_port = port
            print(f"\n✅ Auto-detected Arduino on: {arduino_port}")
            break
    
    if not arduino_port:
        if len(available_ports) == 1:
            arduino_port = available_ports[0]
            print(f"\n⚠️  Using only available port: {arduino_port}")
        else:
            print(f"\n⚠️  Could not auto-detect Arduino.")
            print(f"   Edit SERIAL_PORT in this file to match your port.")
            arduino_port = SERIAL_PORT
    
    # Get admin token
    token = get_admin_token()
    if not token:
        print("\n❌ Could not get admin token. Is the backend running?")
        print("   Start backend: cd health_app/backend && python main.py")
        sys.exit(1)
    
    # Start reading RFID cards
    print(f"\n🔌 Connecting to {arduino_port}...")
    read_rfid(arduino_port, token)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        sys.exit(1)
