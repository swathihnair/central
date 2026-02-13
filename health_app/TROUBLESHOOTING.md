# 🔧 TROUBLESHOOTING GUIDE

## Tell me EXACTLY what's not working

Please check each item and tell me which one is the problem:

---

## ❓ QUESTION 1: Can you login?

**Test:** Go to http://localhost:XXXX (your Flutter app)

- [ ] ✅ YES - I can login as patient
- [ ] ❌ NO - I get an error when logging in
- [ ] ❌ NO - The page doesn't load

**If NO, what error do you see?** _______________

---

## ❓ QUESTION 2: Can you see the Dashboard?

**Test:** After logging in as patient, do you see the Dashboard (Home) screen?

- [ ] ✅ YES - I see the dashboard with vitals cards
- [ ] ❌ NO - I see a blank screen
- [ ] ❌ NO - I see "Loading..." forever
- [ ] ❌ NO - I see an error message

**If NO, what do you see?** _______________

---

## ❓ QUESTION 3: What values does the Dashboard show?

**Test:** Look at the vitals cards on the Dashboard

**Blood Pressure shows:** _______________
**Sugar Level shows:** _______________
**Cholesterol shows:** _______________

**Expected values:**
- BP: 130/85
- Sugar: 110 mg/dL
- Cholesterol: 200 mg/dL

- [ ] ✅ Values match expected
- [ ] ❌ Values are different
- [ ] ❌ Shows "Loading..."
- [ ] ❌ Shows nothing

---

## ❓ QUESTION 4: Can you access Doctor AI?

**Test:** Click on "Doctor AI" in the sidebar/bottom navigation

- [ ] ✅ YES - I see the chat interface
- [ ] ❌ NO - Nothing happens
- [ ] ❌ NO - I get an error

---

## ❓ QUESTION 5: Can you send a message to AI?

**Test:** Type "Hello" and send

- [ ] ✅ YES - AI responds
- [ ] ❌ NO - Nothing happens
- [ ] ❌ NO - I get an error message

**If AI responds, what does it say?** _______________

---

## ❓ QUESTION 6: What does AI say about blood pressure?

**Test:** Ask AI: "What is my blood pressure?"

**AI Response:** _______________

**Expected:** Should say "130/85 mmHg" or similar

- [ ] ✅ AI says 130/85
- [ ] ❌ AI says different value
- [ ] ❌ AI says it doesn't have data
- [ ] ❌ AI doesn't respond

---

## ❓ QUESTION 7: Are Dashboard and AI values the same?

**Dashboard BP:** _______________
**AI reported BP:** _______________

- [ ] ✅ YES - They match
- [ ] ❌ NO - They are different

---

## 🔍 COMMON ISSUES AND SOLUTIONS

### Issue 1: Dashboard shows "Loading..." forever

**Cause:** Frontend can't connect to backend

**Solution:**
```bash
# Check if backend is running
# Should see: "Uvicorn running on http://0.0.0.0:8000"
```

**Check:**
1. Is Process 13 (backend) running?
2. Open http://127.0.0.1:8000/docs - Does it load?

---

### Issue 2: Dashboard shows different values than AI

**Cause:** This should NOT happen anymore (we fixed it!)

**Solution:**
1. Clear browser cache (Ctrl+Shift+Delete)
2. Refresh page (F5)
3. Logout and login again

---

### Issue 3: AI says "I don't have your data"

**Cause:** patient_id not being sent

**Solution:**
1. Check browser console (F12) for errors
2. Verify you're logged in as patient (not admin/doctor)
3. Check if patient_id is in localStorage

---

### Issue 4: AI doesn't respond at all

**Cause:** Backend AI endpoint error

**Solution:**
1. Check backend logs (Process 13)
2. Look for "Successfully used model: gemini-2.5-flash"
3. If not, check GEMINI_API_KEY in .env

---

### Issue 5: Values are all zeros or random

**Cause:** Database doesn't have vitals

**Solution:**
```bash
cd health_app/backend
.\venv\Scripts\python.exe test_complete.py
```

Should show 3 vitals for patient 4

---

## 🧪 QUICK DIAGNOSTIC TESTS

### Test A: Backend Health Check
```bash
# Open in browser:
http://127.0.0.1:8000/docs

# Should show FastAPI documentation
```

### Test B: Database Check
```bash
cd health_app/backend
.\venv\Scripts\python.exe test_complete.py

# Should show:
# ✅ Found 3 vitals for patient 4
# Latest: BP 130/85, Sugar 110, Cholesterol 200
```

### Test C: AI Check
```bash
cd health_app/backend
.\venv\Scripts\python.exe test_ai.py

# Should show:
# Status Code: 200
# Response includes "130/85 mmHg"
```

### Test D: Frontend Console Check
```
1. Open browser (Chrome)
2. Press F12 (Developer Tools)
3. Go to Console tab
4. Look for errors (red text)
5. Copy and paste any errors here: _______________
```

---

## 📞 WHAT TO TELL ME

Please answer these questions so I can help:

1. **Which test failed?** (Question 1-7 above)
2. **What error message do you see?** (exact text)
3. **What values does Dashboard show?** (BP, Sugar, Cholesterol)
4. **What does AI say when you ask about BP?** (exact response)
5. **Any errors in browser console?** (F12 → Console tab)
6. **Any errors in backend logs?** (Process 13 output)

---

## 🎯 EXPECTED BEHAVIOR

### ✅ CORRECT BEHAVIOR:

1. Login as patient → See Dashboard
2. Dashboard shows: BP 130/85, Sugar 110, Cholesterol 200
3. Click Doctor AI → Chat interface appears
4. Ask "What is my blood pressure?" → AI says "130/85 mmHg"
5. Dashboard value = AI value ✅

### ❌ INCORRECT BEHAVIOR:

Tell me which of these you're experiencing:

- [ ] Can't login
- [ ] Dashboard blank/loading forever
- [ ] Dashboard shows wrong values
- [ ] AI doesn't respond
- [ ] AI shows different values than dashboard
- [ ] Something else: _______________

---

## 💡 MOST LIKELY ISSUES

Based on "it's not working", here are the most common problems:

### 1. Frontend not connecting to backend
**Symptom:** Dashboard shows "Loading..." forever
**Fix:** Check if backend is running on port 8000

### 2. Browser cache showing old data
**Symptom:** Values don't update
**Fix:** Clear cache (Ctrl+Shift+Delete) and refresh

### 3. Not logged in as correct user
**Symptom:** No data appears
**Fix:** Make sure you're logged in as patient@health.com (patient ID 4)

### 4. Database connection issue
**Symptom:** Backend errors in logs
**Fix:** Check MySQL is running, password is "swathi"

---

## 🚀 QUICK FIX CHECKLIST

Try these in order:

1. [ ] Refresh browser page (F5)
2. [ ] Clear browser cache (Ctrl+Shift+Delete)
3. [ ] Logout and login again
4. [ ] Check backend is running (Process 13)
5. [ ] Check frontend is running (Process 14)
6. [ ] Run test_complete.py to verify database
7. [ ] Check browser console for errors (F12)

---

**Please tell me specifically what's not working so I can fix it!**
