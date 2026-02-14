# Swathi's RFID Card Assignment

## ✅ Card Successfully Assigned!

### Card Details
- **Card UID**: `51E4B217` (from your RFID-RC522 reader)
- **Patient Name**: Swathi H
- **Patient ID**: 4
- **Email**: swathi.h.2005@gmail.com
- **Phone**: 9876543210
- **Age**: 21

### Login Credentials
- **Email**: swathi.h.2005@gmail.com
- **Password**: patient123
- **Role**: Patient

## 🎯 How to Test

### Method 1: With RFID Hardware
1. Login as admin (admin@health.com / admin123)
2. Go to "RFID Scanner" in the menu
3. Place Swathi's RFID card on the reader
4. The card UID `51E4B217` will be scanned automatically
5. Press Enter
6. Swathi's patient information will appear
7. Click "View Medical History"

### Method 2: Manual Testing (Without Hardware)
1. Login as admin
2. Go to "RFID Scanner"
3. Type `51E4B217` in the input field
4. Press Enter or click "Manual Scan"
5. Swathi's information will appear
6. Click "View Medical History"

## 📋 All Registered Cards

| Card UID  | Patient Name | Patient ID | Status |
|-----------|--------------|------------|--------|
| CARD001   | John Doe     | 3          | Active |
| 51E4B217  | Swathi H     | 4          | Active |

## 🔧 Arduino Code Format

Your Arduino should send the UID in this format:
```
51E4B217
```

The spaces in `51 E4 B2 17` are automatically removed by the system, so both formats work:
- `51E4B217` ✅
- `51 E4 B2 17` ✅
- `51e4b217` ✅ (case insensitive)

## 📱 Testing Steps

1. **Scan the card** with your RFID reader
2. **System looks up** the UID in the database
3. **Finds Swathi's** patient record
4. **Displays** her information:
   - Name: Swathi H
   - Email: swathi.h.2005@gmail.com
   - Phone: 9876543210
   - Age: 21
5. **Click button** to view medical history
6. **Redirects** to patient details page

## 🎉 Ready to Use!

The card is now active and ready to scan. You can:
- Scan it in the RFID Scanner page
- View Swathi's medical records instantly
- Add reports to her account
- Book appointments for her

## 🔐 Security

- Only admins can scan RFID cards
- Card UIDs are unique and indexed
- All operations require authentication
- Cards can be deactivated if needed

## 📝 Notes

- The card UID is stored exactly as: `51E4B217`
- The system is case-insensitive for scanning
- Spaces are automatically removed
- The card is currently active and ready to use
