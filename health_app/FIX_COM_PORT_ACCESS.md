# Fix COM Port Access Error

## Error
```
❌ Serial port error: could not open port 'COM9': PermissionError(13, 'Access is denied.')
```

## Cause
Another program is using COM9 (most likely Arduino IDE Serial Monitor)

## Solution (Quick Fix)

### Step 1: Close Arduino IDE Serial Monitor
1. Go to Arduino IDE
2. Close the Serial Monitor window (if open)
3. Or close Arduino IDE completely

### Step 2: Try Again
```bash
cd health_app\backend
python rfid_reader.py
```

## Still Not Working?

### Check What's Using COM9

Run this in PowerShell:
```powershell
Get-CimInstance -ClassName Win32_SerialPort | Where-Object {$_.DeviceID -eq "COM9"}
```

### Force Close Programs Using COM9

1. Open Task Manager (Ctrl+Shift+Esc)
2. Look for:
   - Arduino IDE
   - PuTTY
   - Serial Monitor
   - Any terminal programs
3. End those tasks

### Unplug and Replug Arduino

1. Unplug Arduino USB cable
2. Wait 5 seconds
3. Plug it back in
4. Try again:
   ```bash
   python rfid_reader.py
   ```

## Alternative: Use Different Port

If COM9 is stuck:

1. Unplug Arduino
2. Plug into different USB port
3. Check new port number in Device Manager
4. Update `rfid_reader.py`:
   ```python
   SERIAL_PORT = 'COM10'  # or whatever new port
   ```

## Quick Test

After closing Arduino IDE, run:
```bash
python rfid_reader.py
```

You should see:
```
✅ Connected to COM9
============================================================
🎴 RFID READER ACTIVE - Waiting for cards...
============================================================
```

Then scan your RFID card! 🚀
