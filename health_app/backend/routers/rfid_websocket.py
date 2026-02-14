"""
WebSocket endpoint for real-time RFID scanning
"""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.orm import Session
from database import get_db
import sql_models
import json
from datetime import datetime
from typing import Set

router = APIRouter()

# Store active WebSocket connections
active_connections: Set[WebSocket] = set()

class ConnectionManager:
    def __init__(self):
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)
        print(f"✅ WebSocket client connected. Total: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        self.active_connections.discard(websocket)
        print(f"❌ WebSocket client disconnected. Total: {len(self.active_connections)}")

    async def send_personal_message(self, message: dict, websocket: WebSocket):
        await websocket.send_json(message)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except:
                pass

manager = ConnectionManager()

@router.websocket("/ws/rfid")
async def websocket_rfid_endpoint(
    websocket: WebSocket,
    db: Session = Depends(get_db)
):
    """
    WebSocket endpoint for real-time RFID scanning
    Clients connect here to receive live RFID scan events
    """
    await manager.connect(websocket)
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types
            if message.get('type') == 'ping':
                # Respond to ping
                await manager.send_personal_message({
                    'type': 'pong',
                    'timestamp': datetime.now().isoformat()
                }, websocket)
            
            elif message.get('type') == 'rfid_scan':
                # Process RFID scan
                card_uid = message.get('card_uid', '').strip().upper()
                
                if card_uid:
                    # Look up card in database
                    card = db.query(sql_models.RFIDCard).filter(
                        sql_models.RFIDCard.card_uid == card_uid,
                        sql_models.RFIDCard.is_active == 1
                    ).first()
                    
                    if card:
                        # Get patient details
                        patient = db.query(sql_models.User).filter(
                            sql_models.User.id == card.patient_id
                        ).first()
                        
                        if patient:
                            # Send patient data back to client
                            response = {
                                'type': 'patient_found',
                                'card_uid': card_uid,
                                'patient': {
                                    'patient_id': patient.id,
                                    'full_name': patient.full_name,
                                    'email': patient.email,
                                    'phone': patient.phone,
                                    'age': patient.age
                                },
                                'timestamp': datetime.now().isoformat()
                            }
                            
                            # Send to requesting client
                            await manager.send_personal_message(response, websocket)
                            
                            # Optionally broadcast to all clients
                            # await manager.broadcast(response)
                        else:
                            await manager.send_personal_message({
                                'type': 'error',
                                'message': 'Patient not found',
                                'card_uid': card_uid
                            }, websocket)
                    else:
                        await manager.send_personal_message({
                            'type': 'error',
                            'message': 'RFID card not registered or inactive',
                            'card_uid': card_uid
                        }, websocket)
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        print(f"❌ WebSocket error: {e}")
        manager.disconnect(websocket)
