# RFID Scanner Troubleshooting Guide

## ✅ Backend is Working!

The backend API is confirmed working:
- ✅ Login endpoint works
- ✅ RFID scan endpoint returns 200 OK
- ✅ Card `51E4B217` is registered to Swathi H
- ✅ Card `CARD001` is registered to John Doe

## 🔍 Debugging Steps

### Step 1: Check Browser Console

1. Open Chrome DevTools (F12)
2. Go to Console tab
3. Look for debug messages when scanning:
   - `🎴 Scanning card UID: ...`
   - `✅ RFID Scan Success: ...`
   - `❌ RFID Scan Error: ...`

### Step 2: Check Network Tab

1. Open Chrome DevTools (F12)
2. Go to Network tab
3. Scan a card
4. Look for POST request to `/api/rfid/scan`
5. Check:
   - Status code (should be 200)
   - Response body
   - Request headers (Authorization token present?)

### Step 3: Test with Known Cards

Try these registered cards:
- `51E4B217` - Swathi H
- `CARD001` - John Doe

### Step 4: Check Error Messages

When you scan a card, what happens?

**Option A: Nothing happens**
- Check if input field is focused
- Check browser console for errors
- Try clicking "Manual Scan" button

**Option B: Error message appears**
- What does the error say?
- Check if you're logged in as admin
- Check network tab for failed requests

**Option C: Dialog appears but doesn't navigate**
- Click "View Medical History" button
- Check console for navigation errors

## 🧪 Manual API Test

Test the API directly from browser console:

```javascript
// 1. Login
fetch('http://127.0.0.1:8000/api/auth/login', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    email: 'admin@health.com',
    password: 'admin123',
    role: 'admin'
  })
})
.then(r => r.json())
.then(data => {
  console.log('Token:', data.access_token);
  window.adminToken = data.access_token;
});

// 2. Scan card (run after login)
fetch('http://127.0.0.1:8000/api/rfid/scan', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${window.adminToken}`
  },
  body: JSON.stringify({card_uid: '51E4B217'})
})
.then(r => r.json())
.then(data => console.log('Patient:', data));
```

## 🔧 Common Issues & Solutions

### Issue: "Card not registered"
**Solution:** 
- Card UID not in database
- Check spelling: `51E4B217` (no spaces)
- Case insensitive: `51e4b217` also works

### Issue: "Could not validate credentials"
**Solution:**
- Not logged in as admin
- Token expired - logout and login again
- Check Local Storage for token

### Issue: Dialog doesn't appear
**Solution:**
- Check browser console for errors
- Try hot reload: press `r` in Flutter terminal
- Check if `showDialog` is being called

### Issue: Can't navigate to patient page
**Solution:**
- Check patient_id is correct
- Verify PatientDetailsScreen exists
- Check navigation route

## 📱 Quick Test Steps

1. **Login as Admin**
   - Email: admin@health.com
   - Password: admin123

2. **Go to RFID Scanner**
   - Click 6th menu item (NFC icon)

3. **Type Card UID**
   - Enter: `51E4B217`
   - Press Enter

4. **Expected Result:**
   - Orange status: "Scanning card..."
   - Green status: "Patient found: Swathi H"
   - Dialog appears with patient info
   - Click "View Medical History"
   - Navigate to patient details page

## 🐛 Debug Logs Added

The scanner now prints debug messages:
- `🎴 Scanning card UID: ...` - When scan starts
- `✅ RFID Scan Success: ...` - When API returns data
- `❌ RFID Scan Error: ...` - When error occurs

Check Flutter DevTools or browser console for these messages.

## 📞 What to Check

Please provide:
1. What happens when you scan/enter a card?
2. Any error messages shown?
3. Browser console output?
4. Network tab - does the API call succeed?

This will help identify the exact issue!
