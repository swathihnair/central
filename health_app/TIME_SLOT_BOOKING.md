# Time Slot Booking System

## Overview
The appointment booking system now shows only available time slots for each doctor, preventing double-booking and ensuring proper scheduling.

## Features

### 30-Minute Time Slots
- Each appointment slot is 30 minutes long
- Working hours: 9:00 AM to 5:00 PM
- Slots are generated in 30-minute intervals (9:00, 9:30, 10:00, 10:30, etc.)

### Smart Availability
- When a patient books a slot, it becomes unavailable for other patients
- Only future time slots are shown (past times are automatically filtered)
- Rejected appointments don't block time slots
- Pending and approved appointments block the time slot

### User Experience

#### Patient Booking Flow:
1. Click "Book" button on Appointments screen
2. Select a doctor from dropdown
3. Available slots automatically load for today
4. Select a date (optional - defaults to today)
5. Available slots refresh for the selected date
6. Click on a time slot to select it (turns blue)
7. Add optional notes
8. Click "Book" to confirm

#### Visual Indicators:
- **Available slots**: Gray background, clickable
- **Selected slot**: Blue background with white text
- **No slots available**: Orange info box with message
- **Loading**: Spinner while fetching slots

## API Endpoint

### GET `/api/appointments/available-slots/{doctor_id}/{date}`

**Parameters:**
- `doctor_id`: The doctor's ID
- `date`: ISO 8601 date string (e.g., "2026-02-13T00:00:00")

**Response:**
```json
{
  "date": "2026-02-13T00:00:00",
  "doctor_id": "2",
  "available_slots": [
    {
      "time": "09:00",
      "display": "09:00 AM",
      "datetime": "2026-02-13T09:00:00"
    },
    {
      "time": "09:30",
      "display": "09:30 AM",
      "datetime": "2026-02-13T09:30:00"
    }
  ],
  "booked_count": 5
}
```

## Business Logic

### Slot Blocking Rules:
1. Appointments with status "pending" → Block slot
2. Appointments with status "approved" → Block slot
3. Appointments with status "rejected" → Don't block slot
4. Appointments with status "completed" → Don't block slot (past appointments)

### Time Filtering:
- For today's date: Only show slots after current time
- For future dates: Show all slots within working hours
- Past dates: Not selectable in date picker

## Example Scenario

**Scenario**: Patient A books 10:00 AM with Dr. Smith

1. Patient A selects Dr. Smith
2. Available slots show: 9:00, 9:30, 10:00, 10:30, 11:00, etc.
3. Patient A selects 10:00 AM and books
4. Appointment created with status "pending"

**Result**: Patient B now sees:
- Available slots: 9:00, 9:30, ~~10:00~~, 10:30, 11:00, etc.
- 10:00 AM is blocked (not shown in available slots)
- Patient B can only book 10:30 AM or later

## Testing

### Test Case 1: Basic Booking
1. Login as patient@health.com
2. Go to Appointments
3. Click "Book"
4. Select a doctor
5. Verify slots appear
6. Select a slot and book
7. Verify success message

### Test Case 2: Slot Blocking
1. Login as patient@health.com
2. Book 10:00 AM with a doctor
3. Logout and login as another patient
4. Try to book with same doctor
5. Verify 10:00 AM is not available
6. Verify 10:30 AM is available

### Test Case 3: Date Change
1. Select a doctor
2. Change date to tomorrow
3. Verify slots refresh
4. Verify all working hour slots are available (no bookings yet)

## Files Modified

### Backend:
- `health_app/backend/routers/appointments.py`
  - Added `get_available_slots()` endpoint
  - Imports `timedelta` for slot calculation

### Frontend:
- `health_app/frontend/lib/services/api_service.dart`
  - Added `getAvailableSlots()` method

- `health_app/frontend/lib/screens/patient/appointments_screen.dart`
  - Replaced time picker with slot grid
  - Added slot loading logic
  - Added slot selection UI
  - Auto-refresh slots on doctor/date change

## Future Enhancements

Possible improvements:
1. Configurable working hours per doctor
2. Different slot durations (15 min, 45 min, 1 hour)
3. Break times / lunch hours
4. Weekend/holiday handling
5. Recurring appointments
6. Waitlist for fully booked days
