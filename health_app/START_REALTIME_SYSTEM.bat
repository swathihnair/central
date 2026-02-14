@echo off
echo ============================================================
echo   HEALTH APP - REAL-TIME RFID SYSTEM LAUNCHER
echo ============================================================
echo.
echo This will start all required services:
echo   1. Backend API Server (Port 8000)
echo   2. WebSocket Bridge (Port 8765)
echo   3. Flutter Web App (Chrome)
echo.
echo Make sure Arduino is connected to COM9!
echo.
pause

echo.
echo Starting Backend Server...
start "Backend Server" cmd /k "cd backend && python main.py"
timeout /t 3 /nobreak > nul

echo Starting WebSocket Bridge...
start "WebSocket Bridge" cmd /k "cd backend && python rfid_websocket_bridge.py"
timeout /t 3 /nobreak > nul

echo Starting Flutter App...
start "Flutter App" cmd /k "cd frontend && flutter run -d chrome"

echo.
echo ============================================================
echo   ALL SERVICES STARTED!
echo ============================================================
echo.
echo   Backend:  http://127.0.0.1:8000
echo   WebSocket: ws://127.0.0.1:8765
echo   Frontend: Opening in Chrome...
echo.
echo   Login: admin@health.com / admin123
echo   Go to: RFID Scanner (6th menu item)
echo.
echo   Scan your RFID card and watch it appear instantly!
echo.
echo ============================================================
echo.
echo Press any key to close this window (services will keep running)
pause > nul
