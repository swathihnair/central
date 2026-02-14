# ❓ WHAT IS NOT WORKING?

Please tell me EXACTLY what's happening:

---

## 🔍 QUESTION 1: What are you trying to do?

Check ONE:
- [ ] Login to the system
- [ ] View patient details
- [ ] Upload a report
- [ ] View reports
- [ ] Use Doctor AI
- [ ] Something else: _______________

---

## 🔍 QUESTION 2: Login Issue?

If you can't login, tell me:

**Which credentials are you using?**
- [ ] admin@health.com / admin123
- [ ] doctor@health.com / doctor123
- [ ] patient@health.com / patient123
- [ ] Other: _______________

**What happens when you click "Sign In"?**
- [ ] Nothing happens
- [ ] Error message appears
- [ ] Page refreshes but stays on login
- [ ] Other: _______________

**What error message do you see?** (exact text)
_______________________________________________

---

## 🔍 QUESTION 3: After Login Issue?

If you CAN login but something else doesn't work:

**What happens after you login?**
- [ ] Blank screen
- [ ] Dashboard loads but no data
- [ ] Can't click on patient name
- [ ] Upload button doesn't work
- [ ] Other: _______________

---

## 🔍 QUESTION 4: Patient Details Issue?

If clicking patient name doesn't work:

**What happens when you click patient name?**
- [ ] Nothing happens
- [ ] Error message
- [ ] Wrong screen opens
- [ ] Other: _______________

---

## 🔍 QUESTION 5: Browser Console Errors?

**Press F12 in your browser, go to Console tab**

Do you see any RED error messages?
- [ ] Yes - Copy and paste them here: _______________
- [ ] No errors

---

## 🧪 QUICK TESTS

### Test 1: Can you access the backend?
Open this in browser: http://127.0.0.1:8000/docs

- [ ] ✅ YES - I see FastAPI documentation
- [ ] ❌ NO - I see error or nothing

### Test 2: Is frontend running?
Look at your browser tab

- [ ] ✅ YES - I see the login page
- [ ] ❌ NO - I see error or blank page

### Test 3: Can you login as admin?
Try: admin@health.com / admin123 / Admin

- [ ] ✅ YES - I'm logged in
- [ ] ❌ NO - Error: _______________

---

## 📸 SCREENSHOT

If possible, take a screenshot of:
1. The error message
2. The browser console (F12 → Console)
3. What you see on screen

---

## 🎯 MOST COMMON ISSUES

### Issue 1: Wrong Password
**Symptom:** "Invalid credentials" error
**Solution:** Make sure you're using EXACTLY:
- admin@health.com / admin123
- patient@health.com / patient123
- doctor@health.com / doctor123

### Issue 2: Wrong Role
**Symptom:** Login fails
**Solution:** Make sure role matches:
- admin@health.com → Role: Admin
- patient@health.com → Role: Patient
- doctor@health.com → Role: Doctor

### Issue 3: Backend Not Running
**Symptom:** "Network error" or "Connection refused"
**Solution:** Check if backend is running on port 8000

### Issue 4: Frontend Not Connected
**Symptom:** Nothing happens when clicking buttons
**Solution:** Check browser console for errors (F12)

---

## 💬 TELL ME EXACTLY

Please copy this and fill in the blanks:

```
I am trying to: _______________
I am using credentials: _______________
When I do this: _______________
This happens: _______________
Error message (if any): _______________
Browser console shows: _______________
```

---

**Once you tell me what's not working, I can fix it immediately!**
