# Health App Project Plan

## Overview
A comprehensive healthcare application with Admin, Doctor, and Patient roles.
Tech Stack: Flutter (Frontend), FastAPI (Backend), MongoDB (Database).

## Features

### 1. Authentication & Roles
- **Login**: Support for Admin, Doctor, Patient.
- **Auth**: JWT based authentication.

### 2. Patient Module
- **Dashboard**:
  - Vitals Chart (BP, Sugar, Cholesterol) - Data from Admin uploaded reports.
  - Upcoming Appointments.
  - Healthy Tips.
- **Sidebar Navigation**:
  - Appointments
  - Doctor AI (Gemini Integration)
  - Reports (Sorted by department)
  - Settings

### 3. Doctor Module
- **Dashboard**: High-quality UI (referencing provided design).
  - Patient stats, appointment requests, etc.
- **Consultation**: Approve/Manage appointments.

### 4. Admin Module
- **User Management**: Add Doctors/Patients.
- **Report Management**: Upload reports (PDF/Image/Data) for patients.
  - These reports populate the patient's vitals chart.
  
## Implementation Phases

### Phase 1: Setup (In Progress)
- Project scaffolding (Flutter + FastAPI).
- Database connection setup.

### Phase 2: Backend Development
- Auth endpoints.
- Patient/Doctor/Admin CRUD.
- Report upload and parsing (or manual entry for vitals).
- Gemini AI endpoint.

### Phase 3: Frontend - Patient
- Dashboard UI with Charts (`fl_chart`).
- AI Chat Interface.
- Report Viewing.

### Phase 4: Frontend - Doctor
- Dashboard implementation based on reference.

### Phase 5: Frontend - Admin
- Data entry/upload screens.

### Phase 6: Integration
- Connect Front to Back.
- Testing.
