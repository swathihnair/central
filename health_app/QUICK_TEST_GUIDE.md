# 🧪 QUICK TEST GUIDE - Verify Everything Works

## ⚡ 5-Minute Test to Verify Data Consistency

### Step 1: Login as Patient (30 seconds)
```
1. Open browser: http://localhost:XXXX (your Flutter app)
2. Email: patient@health.com
3. Password: patient123
4. Role: Patient
5. Click "Sign In"
```

### Step 2: Check Dashboard Values (30 seconds)
```
1. You should see the Dashboard (Home) screen
2. Note down the values:
   - Blood Pressure: ___/___
   - Sugar Level: ___ mg/dL
   - Cholesterol: ___ mg/dL
```

### Step 3: Ask AI About Same Values (1 minute)
```
1. Click "Doctor AI" in sidebar/bottom nav
2. Type: "What is my blood pressure?"
3. AI should respond with SAME value as dashboard
4. Type: "What is my sugar level?"
5. AI should respond with SAME value as dashboard
6. Type: "What is my cholesterol?"
7. AI should respond with SAME value as dashboard
```

### Step 4: Ask AI to Analyze Report (1 minute)
```
1. Still in Doctor AI screen
2. Type: "Analyze my latest blood test"
3. AI should:
   ✅ Automatically fetch your reports
   ✅ Show the values (same as dashboard)
   ✅ Provide medical analysis
   ✅ Give recommendations
```

### Step 5: Upload New PDF (2 minutes)
```
1. Logout from patient account
2. Login as admin:
   - Email: admin@health.com
   - Password: admin123
   - Role: Admin
3. Go to "Upload Reports"
4. Select patient: "swathi" (or any patient)
5. Title: "Test Blood Report"
6. Department: "Pathology"
7. Upload any PDF file (medical report if you have one)
8. Click "Upload Report"
9. Check backend logs - should show:
   "Extracted X characters from PDF"
   "AI extracted vitals: {...}" (if medical PDF)
```

### Step 6: Verify New Data (1 minute)
```
1. Logout from admin
2. Login as patient again
3. Go to Dashboard
4. Values should be updated (if new report was uploaded)
5. Go to Doctor AI
6. Ask: "What are my latest test results?"
7. AI should show the NEW values (same as dashboard)
```

## ✅ SUCCESS CRITERIA

If all these work, your system is 100% functional:

✅ Dashboard shows vitals from database
✅ AI shows SAME vitals from database
✅ AI can analyze reports automatically
✅ Admin can upload PDFs
✅ AI extracts vitals from PDFs
✅ New data appears in both dashboard and AI
✅ **Data is consistent everywhere**

## 🎯 EXPECTED RESULTS

### Dashboard Display:
```
Blood Pressure: 121/88 mmHg
Sugar Level: 126 mg/dL
Cholesterol: 152 mg/dL
```

### AI Response to "What is my blood pressure?":
```
Based on your latest test results, your blood pressure is 121/88 mmHg.
This is within the normal range (systolic: 90-120, diastolic: 60-80).
Your systolic is slightly elevated but not concerning.
```

### AI Response to "Analyze my blood test":
```
I've automatically fetched your latest medical reports. Here's the analysis:

📄 Most Recent Test Results (from 2024-XX-XX):
- Blood Pressure: 121/88 mmHg
- Blood Sugar Level: 126 mg/dL
- Cholesterol: 152 mg/dL

Assessment:
1. Blood Pressure: Slightly elevated systolic (121), but within acceptable range
2. Blood Sugar: Borderline high (normal fasting: 70-100 mg/dL)
3. Cholesterol: Within normal range (desirable: <200 mg/dL)

Recommendations:
- Monitor blood sugar levels, consider reducing sugar intake
- Maintain healthy diet and regular exercise
- Schedule follow-up with your doctor if symptoms persist
```

## 🚨 TROUBLESHOOTING

### If Dashboard Shows "Loading..."
- Check if backend is running (Process 13)
- Check browser console for errors
- Verify patient has reports in database

### If AI Doesn't Show Values
- Check if patient_id is being sent with chat request
- Check backend logs for errors
- Verify reports have pdf_text in database

### If Values Don't Match
- This should NOT happen anymore!
- If it does, check:
  - Dashboard is calling `/api/reports/patient/{id}/vitals`
  - AI is calling same endpoint
  - Both are using same patient_id

## 📞 QUICK CHECKS

### Backend Running?
```bash
# Check Process 13 output
# Should show: "Uvicorn running on http://0.0.0.0:8000"
```

### Frontend Running?
```bash
# Check Process 14 output
# Should show Flutter app running in Chrome
```

### Database Connected?
```bash
# Backend logs should NOT show MySQL connection errors
# If you see connection errors, check MySQL password in .env
```

### AI Working?
```bash
# Backend logs should show: "Successfully used model: gemini-2.5-flash"
# If not, check GEMINI_API_KEY in .env
```

## 🎉 YOU'RE DONE!

If all tests pass, your system is production-ready!

**Key Achievement**: Data is now dynamically extracted from PDFs using AI, and both dashboard and AI use the same data source, ensuring consistency.

---

**Need Help?** Check:
1. `SYSTEM_STATUS.md` - Complete system overview
2. `RAG_IMPLEMENTATION_GUIDE.md` - RAG system details
3. Backend logs (Process 13) - Error messages
4. Browser console - Frontend errors
