"""
Real-Time RFID WebSocket Bridge
Connects Arduino RFID reader to web browser via WebSocket
"""
import asyncio
import serial
import serial.tools.list_ports
import json
from datetime import datetime
import sys

# WebSocket server
import websockets
from websockets.server import serve

# Configuration
SERIAL_PORT = 'COM3'
BAUD_RATE = 9600
WEBSOCKET_PORT = 8765
WEBSOCKET_HOST = '0.0.0.0'

# Store connected clients
connected_clients = set()

# Serial connection
ser = None

def list_serial_ports():
    """List all available serial ports"""
    ports = serial.tools.list_ports.comports()
    print("\n📡 Available Serial Ports:")
    print("-" * 50)
    for port in ports:
        print(f"  {port.device} - {port.description}")
    print("-" * 50)
    return [port.device for port in ports]

def find_arduino_port():
    """Auto-detect Arduino port"""
    available_ports = list_serial_ports()
    
    if not available_ports:
        print("\n❌ No serial ports found!")
        return None
    
    # Try to find Arduino
    for port in available_ports:
        if 'Arduino' in port or 'USB' in port or 'ACM' in port:
            print(f"\n✅ Auto-detected Arduino on: {port}")
            return port
    
    # Use first available port
    if len(available_ports) == 1:
        print(f"\n⚠️  Using only available port: {available_ports[0]}")
        return available_ports[0]
    
    # Use configured port
    if SERIAL_PORT in available_ports:
        print(f"\n✅ Using configured port: {SERIAL_PORT}")
        return SERIAL_PORT
    
    print(f"\n⚠️  Could not auto-detect Arduino. Using: {SERIAL_PORT}")
    return SERIAL_PORT

async def broadcast_to_clients(message):
    """Send message to all connected WebSocket clients"""
    if connected_clients:
        # Create tasks for all clients
        tasks = [client.send(json.dumps(message)) for client in connected_clients]
        # Wait for all sends to complete
        await asyncio.gather(*tasks, return_exceptions=True)
        print(f"📤 Broadcasted to {len(connected_clients)} client(s)")

async def handle_websocket(websocket):
    """Handle WebSocket client connection"""
    # Register client
    connected_clients.add(websocket)
    client_id = id(websocket)
    print(f"\n✅ Client connected: {client_id}")
    print(f"   Total clients: {len(connected_clients)}")
    
    # Send welcome message
    await websocket.send(json.dumps({
        'type': 'connected',
        'message': 'Connected to RFID WebSocket Bridge',
        'timestamp': datetime.now().isoformat()
    }))
    
    try:
        # Keep connection alive and handle incoming messages
        async for message in websocket:
            try:
                data = json.loads(message)
                print(f"📨 Received from client {client_id}: {data}")
                
                # Handle ping/pong
                if data.get('type') == 'ping':
                    await websocket.send(json.dumps({
                        'type': 'pong',
                        'timestamp': datetime.now().isoformat()
                    }))
            except json.JSONDecodeError:
                print(f"⚠️  Invalid JSON from client {client_id}")
    except websockets.exceptions.ConnectionClosed:
        print(f"\n❌ Client disconnected: {client_id}")
    finally:
        # Unregister client
        connected_clients.remove(websocket)
        print(f"   Total clients: {len(connected_clients)}")

async def read_rfid_serial():
    """Read RFID cards from Arduino serial port"""
    global ser
    
    port = find_arduino_port()
    if not port:
        print("\n❌ No Arduino port found!")
        return
    
    try:
        # Open serial connection
        ser = serial.Serial(port, BAUD_RATE, timeout=1)
        print(f"\n✅ Connected to Arduino on {port}")
        print("\n" + "=" * 60)
        print("🎴 RFID READER ACTIVE - Waiting for cards...")
        print("=" * 60)
        print("\nWebSocket clients can connect to:")
        print(f"ws://{WEBSOCKET_HOST}:{WEBSOCKET_PORT}")
        print("\nPlace an RFID card near the reader to scan.")
        print("Press Ctrl+C to stop.\n")
        
        last_card = ""
        last_time = 0
        
        while True:
            if ser.in_waiting > 0:
                # Read card UID
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                
                # Filter out debug messages and ensure valid UID
                if line and len(line) >= 8 and not line.startswith('RFID'):
                    card_uid = line.upper()
                    current_time = asyncio.get_event_loop().time()
                    
                    # Prevent duplicate reads (within 2 seconds)
                    if card_uid != last_card or (current_time - last_time) > 2:
                        print(f"\n📱 Card Scanned: {card_uid}")
                        print("-" * 60)
                        
                        # Broadcast to all WebSocket clients
                        message = {
                            'type': 'rfid_scan',
                            'card_uid': card_uid,
                            'timestamp': datetime.now().isoformat()
                        }
                        
                        await broadcast_to_clients(message)
                        
                        last_card = card_uid
                        last_time = current_time
                        
                        print("✅ Sent to web clients")
                        print("=" * 60 + "\n")
            
            # Small delay to prevent CPU overuse
            await asyncio.sleep(0.1)
    
    except serial.SerialException as e:
        print(f"\n❌ Serial port error: {e}")
        print(f"\nTroubleshooting:")
        print(f"  1. Make sure Arduino is connected to {port}")
        print(f"  2. Close Arduino IDE Serial Monitor if open")
        print(f"  3. Try unplugging and replugging Arduino")
        print(f"  4. Check available ports above")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
    finally:
        if ser and ser.is_open:
            ser.close()
            print("\n✅ Serial port closed")

async def main():
    """Main function to run WebSocket server and serial reader"""
    print("\n" + "=" * 60)
    print("🏥 HEALTH APP - REAL-TIME RFID WEBSOCKET BRIDGE")
    print("=" * 60)
    
    # Start WebSocket server
    print(f"\n🌐 Starting WebSocket server on ws://{WEBSOCKET_HOST}:{WEBSOCKET_PORT}")
    
    async with serve(handle_websocket, WEBSOCKET_HOST, WEBSOCKET_PORT):
        print("✅ WebSocket server started")
        
        # Start reading from Arduino
        try:
            await read_rfid_serial()
        except KeyboardInterrupt:
            print("\n\n⏹️  Stopping RFID bridge...")
            print("✅ Disconnected. Goodbye!")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n⏹️  Shutting down...")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        sys.exit(1)
