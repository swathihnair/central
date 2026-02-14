"""
Assign RFID card UID: 51E4B217 to Swathi's patient account
"""
from database import SessionLocal
import sql_models
from routers.auth import get_password_hash

def assign_swathi_rfid():
    db = SessionLocal()
    
    try:
        # Card UID from the RFID reader (without spaces)
        card_uid = "51E4B217"
        
        # Try to find Swathi's account
        patient = db.query(sql_models.User).filter(
            sql_models.User.email == "swathi.h.2005@gmail.com"
        ).first()
        
        if not patient:
            print("Swathi's account not found. Creating new patient account...")
            
            # Create Swathi's patient account
            hashed_password = get_password_hash("patient123")
            patient = sql_models.User(
                email="swathi.h.2005@gmail.com",
                full_name="Swathi H",
                role="patient",
                hashed_password=hashed_password,
                phone="9876543210",
                age=21
            )
            db.add(patient)
            db.commit()
            db.refresh(patient)
            print(f"✅ Created patient account: {patient.full_name} (ID: {patient.id})")
        else:
            print(f"Found existing patient: {patient.full_name} (ID: {patient.id})")
        
        # Check if card already exists
        existing_card = db.query(sql_models.RFIDCard).filter(
            sql_models.RFIDCard.card_uid == card_uid
        ).first()
        
        if existing_card:
            # Update existing card
            existing_card.patient_id = patient.id
            existing_card.is_active = 1
            print(f"Updated existing RFID card {card_uid}")
        else:
            # Create new card assignment
            new_card = sql_models.RFIDCard(
                card_uid=card_uid,
                patient_id=patient.id
            )
            db.add(new_card)
            print(f"Created new RFID card assignment")
        
        db.commit()
        
        print("\n" + "="*60)
        print("✅ RFID CARD SUCCESSFULLY ASSIGNED!")
        print("="*60)
        print(f"Card UID:      {card_uid}")
        print(f"Patient Name:  {patient.full_name}")
        print(f"Patient ID:    {patient.id}")
        print(f"Email:         {patient.email}")
        print(f"Phone:         {patient.phone}")
        print(f"Age:           {patient.age}")
        print("="*60)
        print("\n📱 You can now scan this card in the RFID Scanner!")
        print(f"   Card UID: {card_uid}")
        print("\n🔐 Login credentials:")
        print(f"   Email: {patient.email}")
        print(f"   Password: patient123")
        print("="*60)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    assign_swathi_rfid()
