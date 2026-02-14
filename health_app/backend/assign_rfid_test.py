"""
Script to assign test RFID cards to patients
Run this after creating test users
"""
from database import SessionLocal, engine
import sql_models

def assign_test_rfid_cards():
    db = SessionLocal()
    
    try:
        # Get all patients
        patients = db.query(sql_models.User).filter(
            sql_models.User.role == "patient"
        ).all()
        
        if not patients:
            print("No patients found. Please create test users first.")
            return
        
        # Assign RFID cards to patients
        # Using simple UIDs for testing (in real scenario, these would come from actual RFID cards)
        test_cards = [
            "CARD001",
            "CARD002",
            "CARD003",
            "A1B2C3D4",
            "12345678",
        ]
        
        for i, patient in enumerate(patients):
            if i < len(test_cards):
                # Check if card already exists
                existing_card = db.query(sql_models.RFIDCard).filter(
                    sql_models.RFIDCard.patient_id == patient.id
                ).first()
                
                if existing_card:
                    print(f"Patient {patient.full_name} already has RFID card: {existing_card.card_uid}")
                else:
                    new_card = sql_models.RFIDCard(
                        card_uid=test_cards[i],
                        patient_id=patient.id
                    )
                    db.add(new_card)
                    print(f"Assigned RFID card {test_cards[i]} to patient {patient.full_name} (ID: {patient.id})")
        
        db.commit()
        print("\n✅ RFID cards assigned successfully!")
        
        # Display all assignments
        print("\n📋 Current RFID Card Assignments:")
        print("-" * 60)
        all_cards = db.query(sql_models.RFIDCard).all()
        for card in all_cards:
            patient = db.query(sql_models.User).filter(
                sql_models.User.id == card.patient_id
            ).first()
            status = "Active" if card.is_active else "Inactive"
            print(f"Card UID: {card.card_uid:15} | Patient: {patient.full_name:20} | Status: {status}")
        print("-" * 60)
        
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    assign_test_rfid_cards()
