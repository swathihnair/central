# 📅 APPOINTMENT APPROVAL WORKFLOW

## ✨ NEW FEATURE: Dual Approval System

Appointments now require BOTH doctor AND admin approval before confirmation!

---

## 🔄 How It Works

### Step 1: Patient Books Appointment
```
Patient → Selects Doctor → Chooses Date/Time → Books Appointment
Status: "pending"
Doctor Approval: "pending"
Admin Approval: "pending"
```

### Step 2: Doctor Reviews Request
```
Doctor → Views Appointment Requests → Approves or Rejects
If Approved:
  Doctor Approval: "approved"
  Status: Still "pending" (waiting for admin)
  
If Rejected:
  Doctor Approval: "rejected"
  Status: "rejected" (appointment cancelled)
```

### Step 3: Admin Reviews Request
```
Admin → Views Appointment Requests → Approves or Rejects
If Approved:
  Admin Approval: "approved"
  Status: Still "pending" (if doctor hasn't approved yet)
  
If Rejected:
  Admin Approval: "rejected"
  Status: "rejected" (appointment cancelled)
```

### Step 4: Both Approved = Confirmed!
```
When BOTH doctor AND admin approve:
  Doctor Approval: "approved"
  Admin Approval: "approved"
  Status: "approved" ✅
  
Patient receives confirmation!
```

---

## 📊 Approval States

### Pending (Waiting for Approvals)
```
Status: "pending"
Doctor: "pending"
Admin: "pending"
```
**Meaning:** Appointment request submitted, waiting for both approvals

### Doctor Approved, Admin Pending
```
Status: "pending"
Doctor: "approved" ✅
Admin: "pending" ⏳
```
**Meaning:** Doctor approved, waiting for admin

### Admin Approved, Doctor Pending
```
Status: "pending"
Doctor: "pending" ⏳
Admin: "approved" ✅
```
**Meaning:** Admin approved, waiting for doctor

### Both Approved = Confirmed
```
Status: "approved" ✅
Doctor: "approved" ✅
Admin: "approved" ✅
```
**Meaning:** Appointment confirmed! Patient can attend

### Rejected by Either
```
Status: "rejected" ❌
Doctor: "rejected" OR Admin: "rejected"
```
**Meaning:** Appointment cancelled (either party rejected)

---

## 🎯 API Endpoints

### Approve Appointment
```
PUT /api/appointments/{appointment_id}/approve
Authorization: Bearer {token}

Response:
{
  "message": "Appointment approved",
  "doctor_approved": "approved",
  "admin_approved": "pending",
  "status": "pending"
}
```

### Reject Appointment
```
PUT /api/appointments/{appointment_id}/reject
Authorization: Bearer {token}

Response:
{
  "message": "Appointment rejected",
  "doctor_approved": "rejected",
  "admin_approved": "pending",
  "status": "rejected"
}
```

### Get Appointments (includes approval status)
```
GET /api/appointments/patient/{patient_id}
GET /api/appointments/doctor/{doctor_id}
GET /api/appointments/all (admin only)

Response includes:
{
  "id": "1",
  "status": "pending",
  "doctor_approved": "approved",
  "admin_approved": "pending",
  ...
}
```

---

## 🔐 Authorization Rules

### Doctor Can:
- ✅ Approve appointments where they are the assigned doctor
- ✅ Reject appointments where they are the assigned doctor
- ❌ Cannot approve/reject other doctors' appointments

### Admin Can:
- ✅ Approve any appointment
- ✅ Reject any appointment
- ✅ View all appointments

### Patient Can:
- ✅ Book appointments
- ✅ View their own appointments
- ✅ See approval status
- ❌ Cannot approve/reject

---

## 📱 User Experience

### For Patients:
```
1. Book appointment
2. See status: "Pending Approval"
3. Wait for doctor and admin to approve
4. When both approve: "Appointment Confirmed!"
5. If either rejects: "Appointment Rejected"
```

### For Doctors:
```
1. Receive appointment request notification
2. Review patient details
3. Approve or Reject
4. If approved: "Waiting for admin approval"
5. When admin also approves: "Appointment Confirmed!"
```

### For Admins:
```
1. View all pending appointments
2. See which ones doctor has approved
3. Approve or Reject
4. When both approved: "Appointment Confirmed!"
```

---

## 🎨 Status Display

### Patient View:
```
┌─────────────────────────────────────┐
│ Appointment with Dr. Smith          │
│ Date: 2026-02-15 10:00 AM          │
│                                     │
│ Status: Pending Approval            │
│ ✅ Doctor Approved                  │
│ ⏳ Waiting for Admin Approval       │
└─────────────────────────────────────┘
```

### Doctor View:
```
┌─────────────────────────────────────┐
│ Appointment Request                 │
│ Patient: John Doe                   │
│ Date: 2026-02-15 10:00 AM          │
│                                     │
│ [Approve] [Reject]                  │
└─────────────────────────────────────┘
```

### Admin View:
```
┌─────────────────────────────────────┐
│ Appointment Request                 │
│ Patient: John Doe                   │
│ Doctor: Dr. Smith                   │
│ Date: 2026-02-15 10:00 AM          │
│                                     │
│ Doctor Status: ✅ Approved          │
│ Admin Status: ⏳ Pending            │
│                                     │
│ [Approve] [Reject]                  │
└─────────────────────────────────────┘
```

---

## ✅ Benefits

1. **Quality Control:** Both medical and administrative review
2. **Resource Management:** Admin can manage doctor schedules
3. **Patient Safety:** Doctor verifies medical appropriateness
4. **Transparency:** Clear approval status for all parties
5. **Accountability:** Track who approved what

---

## 🧪 Testing the Workflow

### Test 1: Full Approval Flow
```
1. Login as patient (patient@health.com / patient123)
2. Book appointment with doctor
3. Logout

4. Login as doctor (doctor@health.com / doctor123)
5. View appointment requests
6. Approve the appointment
7. Verify status shows "Waiting for admin"
8. Logout

9. Login as admin (admin@health.com / admin123)
10. View appointment requests
11. Approve the appointment
12. Verify status changes to "Approved"
13. Logout

14. Login as patient again
15. View appointments
16. See "Appointment Confirmed!"
```

### Test 2: Doctor Rejection
```
1. Patient books appointment
2. Doctor rejects
3. Status immediately becomes "Rejected"
4. Admin doesn't need to review
```

### Test 3: Admin Rejection
```
1. Patient books appointment
2. Doctor approves
3. Admin rejects
4. Status becomes "Rejected"
```

---

## 📊 Database Schema

```sql
CREATE TABLE appointments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    date_time DATETIME NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    doctor_approved VARCHAR(50) DEFAULT 'pending',
    admin_approved VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES users(id),
    FOREIGN KEY (doctor_id) REFERENCES users(id)
);
```

---

## 🎉 FEATURE COMPLETE!

The dual approval system is now implemented and ready to use!

**Backend:** ✅ API endpoints updated
**Database:** ✅ New columns added
**Authorization:** ✅ Role-based approval
**Status Logic:** ✅ Automatic status updates

**Next:** Update frontend to show approval status and buttons!
