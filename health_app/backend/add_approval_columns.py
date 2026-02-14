"""
Add doctor_approved and admin_approved columns to appointments table
"""
from database import SessionLocal, engine
from sqlalchemy import text

def add_approval_columns():
    db = SessionLocal()
    
    try:
        print("Adding approval columns to appointments table...")
        
        # Add doctor_approved column
        try:
            db.execute(text("""
                ALTER TABLE appointments 
                ADD COLUMN doctor_approved VARCHAR(50) DEFAULT 'pending'
            """))
            print("✅ Added doctor_approved column")
        except Exception as e:
            if "Duplicate column name" in str(e):
                print("⚠️  doctor_approved column already exists")
            else:
                raise e
        
        # Add admin_approved column
        try:
            db.execute(text("""
                ALTER TABLE appointments 
                ADD COLUMN admin_approved VARCHAR(50) DEFAULT 'pending'
            """))
            print("✅ Added admin_approved column")
        except Exception as e:
            if "Duplicate column name" in str(e):
                print("⚠️  admin_approved column already exists")
            else:
                raise e
        
        db.commit()
        print("\n✅ Migration completed successfully!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    add_approval_columns()
