#!/usr/bin/env python3
"""
Health App Setup Script
Automates the setup process for the Health App
"""

import os
import subprocess
import sys
import secrets

def print_header(text):
    print("\n" + "="*60)
    print(f"  {text}")
    print("="*60 + "\n")

def run_command(command, cwd=None):
    """Run a shell command and return success status"""
    try:
        subprocess.run(command, shell=True, check=True, cwd=cwd)
        return True
    except subprocess.CalledProcessError:
        return False

def setup_backend():
    print_header("Setting up Backend")
    
    backend_dir = os.path.join(os.path.dirname(__file__), 'backend')
    
    # Check if Python is installed
    print("✓ Checking Python installation...")
    if not run_command("python --version"):
        print("✗ Python not found. Please install Python 3.8+")
        return False
    
    # Create virtual environment
    print("✓ Creating virtual environment...")
    venv_path = os.path.join(backend_dir, 'venv')
    if not os.path.exists(venv_path):
        if not run_command("python -m venv venv", cwd=backend_dir):
            print("✗ Failed to create virtual environment")
            return False
    
    # Determine activation command based on OS
    if sys.platform == "win32":
        activate_cmd = os.path.join(venv_path, 'Scripts', 'activate')
        pip_cmd = os.path.join(venv_path, 'Scripts', 'pip')
    else:
        activate_cmd = f"source {os.path.join(venv_path, 'bin', 'activate')}"
        pip_cmd = os.path.join(venv_path, 'bin', 'pip')
    
    # Install dependencies
    print("✓ Installing Python dependencies...")
    if not run_command(f"{pip_cmd} install -r requirements.txt", cwd=backend_dir):
        print("✗ Failed to install dependencies")
        return False
    
    # Setup .env file
    print("✓ Configuring environment variables...")
    env_file = os.path.join(backend_dir, '.env')
    
    # Generate secret key
    secret_key = secrets.token_hex(32)
    
    env_content = f"""MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=health_app
SECRET_KEY={secret_key}
GEMINI_API_KEY=INSERT_YOUR_GEMINI_API_KEY_HERE
"""
    
    with open(env_file, 'w') as f:
        f.write(env_content)
    
    print("✓ Backend setup complete!")
    print("\n⚠️  IMPORTANT: Edit backend/.env and add your GEMINI_API_KEY")
    print("   Get your key from: https://makersuite.google.com/app/apikey")
    return True

def setup_frontend():
    print_header("Setting up Frontend")
    
    frontend_dir = os.path.join(os.path.dirname(__file__), 'frontend')
    
    # Check if Flutter is installed
    print("✓ Checking Flutter installation...")
    if not run_command("flutter --version"):
        print("✗ Flutter not found. Please install Flutter from https://flutter.dev")
        return False
    
    # Get Flutter dependencies
    print("✓ Installing Flutter dependencies...")
    if not run_command("flutter pub get", cwd=frontend_dir):
        print("✗ Failed to install Flutter dependencies")
        return False
    
    print("✓ Frontend setup complete!")
    return True

def check_mongodb():
    print_header("Checking MongoDB")
    
    print("Checking if MongoDB is running...")
    # Try to connect to MongoDB
    try:
        from pymongo import MongoClient
        client = MongoClient('mongodb://localhost:27017/', serverSelectionTimeoutMS=2000)
        client.server_info()
        print("✓ MongoDB is running!")
        return True
    except:
        print("⚠️  MongoDB is not running or not installed")
        print("\nOptions:")
        print("1. Install MongoDB locally: https://www.mongodb.com/try/download/community")
        print("2. Use MongoDB Atlas (cloud): https://www.mongodb.com/cloud/atlas")
        print("\nIf using Atlas, update MONGODB_URL in backend/.env")
        return False

def create_test_users():
    print_header("Creating Test Users")
    
    print("Would you like to create test users? (y/n): ", end='')
    response = input().strip().lower()
    
    if response != 'y':
        print("Skipping test user creation")
        return
    
    print("\nStarting backend server to create users...")
    print("This will take a few seconds...\n")
    
    # Note: This is a simplified version. In practice, you'd want to:
    # 1. Start the server in background
    # 2. Wait for it to be ready
    # 3. Make API calls
    # 4. Stop the server
    
    print("To create test users, run these commands after starting the backend:")
    print("\n# Admin User:")
    print('curl -X POST http://localhost:8000/api/auth/register -H "Content-Type: application/json" -d \'{"email": "admin@health.com", "password": "admin123", "full_name": "Admin User", "role": "admin"}\'')
    print("\n# Doctor User:")
    print('curl -X POST http://localhost:8000/api/auth/register -H "Content-Type: application/json" -d \'{"email": "doctor@health.com", "password": "doctor123", "full_name": "Dr. Smith", "role": "doctor", "specialization": "Cardiology"}\'')
    print("\n# Patient User:")
    print('curl -X POST http://localhost:8000/api/auth/register -H "Content-Type: application/json" -d \'{"email": "patient@health.com", "password": "patient123", "full_name": "John Doe", "role": "patient"}\'')

def main():
    print_header("Health App Setup")
    print("This script will set up the Health App for you")
    
    # Setup backend
    if not setup_backend():
        print("\n✗ Backend setup failed!")
        sys.exit(1)
    
    # Setup frontend
    if not setup_frontend():
        print("\n✗ Frontend setup failed!")
        sys.exit(1)
    
    # Check MongoDB
    check_mongodb()
    
    # Create test users
    create_test_users()
    
    print_header("Setup Complete!")
    print("Next steps:")
    print("\n1. Ensure MongoDB is running")
    print("2. Add your GEMINI_API_KEY to backend/.env")
    print("3. Start the backend:")
    print("   cd backend")
    if sys.platform == "win32":
        print("   venv\\Scripts\\activate")
    else:
        print("   source venv/bin/activate")
    print("   python main.py")
    print("\n4. In a new terminal, start the frontend:")
    print("   cd frontend")
    print("   flutter run -d chrome")
    print("\n5. Create test users using the curl commands above")
    print("\nEnjoy your Health App! 🏥")

if __name__ == "__main__":
    main()
