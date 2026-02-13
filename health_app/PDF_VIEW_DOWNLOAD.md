# PDF View and Download Feature

## Overview
Patients and admins can now view and download medical report PDFs directly from the application.

## Features Implemented

### Backend API Endpoints

#### 1. View PDF Endpoint
**GET** `/api/reports/view/{report_id}`

- Opens PDF in browser (inline display)
- Requires authentication
- Authorization: Patients can only view their own reports, admins can view all
- Returns PDF with `Content-Disposition: inline`

#### 2. Download PDF Endpoint
**GET** `/api/reports/download/{report_id}`

- Downloads PDF file to device
- Requires authentication
- Authorization: Patients can only download their own reports, admins can download all
- Returns PDF with `Content-Disposition: attachment`

### Frontend Implementation

#### Patient Reports Screen
**Location**: `lib/screens/patient/reports_screen.dart`

**Features**:
- View button (eye icon) - Opens PDF in new browser tab
- Download button (download icon) - Downloads PDF to device
- Both buttons appear on each report card
- Success/error notifications

**UI Changes**:
- Added two icon buttons in report card trailing section
- Blue eye icon for viewing
- Green download icon for downloading
- Tooltips on hover

#### Admin Patient Details Screen
**Location**: `lib/screens/admin/patient_details_screen.dart`

**Features**:
- View PDF button in expanded report card
- Download button in expanded report card
- Both buttons styled as outlined buttons
- Success/error notifications

**UI Changes**:
- Replaced placeholder buttons with functional ones
- Blue styling for View button
- Green styling for Download button
- Full-width buttons in row layout

## How It Works

### Authorization Flow
1. User clicks View or Download button
2. Frontend gets auth token from SharedPreferences
3. Request sent to backend with Authorization header
4. Backend validates token and checks permissions:
   - Patient: Can only access their own reports
   - Admin: Can access all reports
   - Doctor: Not implemented (can be added)
5. If authorized, PDF file is served

### View PDF Flow
1. User clicks "View PDF" button
2. URL constructed: `http://127.0.0.1:8000/api/reports/view/{report_id}`
3. Opens in new browser tab using `url_launcher`
4. Browser displays PDF inline

### Download PDF Flow
1. User clicks "Download" button
2. Frontend calls `ApiService.downloadPDF(reportId, filename)`
3. API fetches PDF bytes from backend with auth token
4. Creates a Blob from the PDF bytes
5. Creates a temporary download link using `html.Url.createObjectUrlFromBlob()`
6. Triggers browser download using anchor element with `download` attribute
7. File downloads directly to browser's default download location
8. Cleanup: Removes temporary elements and revokes object URL
9. Success notification shown

### Technical Implementation

**Browser Download API**:
```dart
// Create blob from PDF bytes
final blob = html.Blob([response.bodyBytes], 'application/pdf');
final url = html.Url.createObjectUrlFromBlob(blob);

// Create temporary anchor and trigger download
final anchor = html.AnchorElement(href: url)
  ..setAttribute('download', filename)
  ..style.display = 'none';

html.document.body?.children.add(anchor);
anchor.click();

// Cleanup
html.document.body?.children.remove(anchor);
html.Url.revokeObjectUrl(url);
```

This approach:
- Downloads file directly to local device
- Uses browser's native download functionality
- Works in all modern browsers
- Doesn't open new tabs
- Allows custom filename

## Testing

### Test as Patient

1. **Login**
   ```
   Email: patient@health.com
   Password: patient123
   ```

2. **View Reports**
   - Go to Reports tab
   - See list of your reports
   - Click eye icon (View) on any report
   - PDF opens in new browser tab

3. **Download Reports**
   - Click download icon on any report
   - PDF downloads to your Downloads folder
   - See success notification

### Test as Admin

1. **Login**
   ```
   Email: admin@health.com
   Password: admin123
   ```

2. **View Patient Reports**
   - Click on any patient name
   - See patient's reports list
   - Expand any report card
   - Click "View PDF" button
   - PDF opens in new browser tab

3. **Download Patient Reports**
   - In expanded report card
   - Click "Download" button
   - PDF downloads to Downloads folder
   - See success notification

### Test Authorization

1. **Patient accessing own reports**: ✅ Should work
2. **Patient accessing other patient's reports**: ❌ Should fail (403 Forbidden)
3. **Admin accessing any reports**: ✅ Should work
4. **Unauthenticated access**: ❌ Should fail (401 Unauthorized)

## File Structure

### Backend Files
```
health_app/backend/routers/reports.py
├── download_report()  # New endpoint
└── view_report()      # New endpoint
```

### Frontend Files
```
health_app/frontend/lib/screens/
├── patient/reports_screen.dart
│   ├── _viewReport()      # New method
│   └── _downloadReport()  # New method
└── admin/patient_details_screen.dart
    ├── _viewReport()      # New method
    └── _downloadReport()  # New method
```

## Dependencies

### Backend
- `fastapi.responses.FileResponse` - For serving PDF files
- `os` - For file path operations

### Frontend
- `url_launcher` - For opening PDFs in browser (view functionality)
- `dart:html` - For browser download API (download functionality)
- Already in Flutter Web

## Error Handling

### Backend Errors
- **404 Not Found**: Report doesn't exist or file missing
- **403 Forbidden**: User not authorized to access report
- **401 Unauthorized**: No valid auth token

### Frontend Errors
- **Cannot launch URL**: Browser/system issue
- **Network error**: Backend not reachable
- **File not found**: PDF file missing from server

All errors show user-friendly SnackBar notifications.

## Security Considerations

### Authorization Checks
```python
# Patient can only access their own reports
if current_user.role == "patient" and current_user.id != report.patient_id:
    raise HTTPException(status_code=403, detail="Not authorized")

# Admin can access all reports
if current_user.role == "admin":
    # Allow access
```

### File Path Security
- Files stored in `uploads/` directory
- File paths validated before serving
- No directory traversal allowed
- Only PDF files served

## Browser Compatibility

### View PDF (Inline)
- ✅ Chrome: Native PDF viewer
- ✅ Firefox: Native PDF viewer
- ✅ Edge: Native PDF viewer
- ✅ Safari: Native PDF viewer

### Download PDF
- ✅ All modern browsers support download
- ✅ Downloads directly to default download location (no prompt)
- ✅ Custom filename support
- ✅ No new tabs opened
- ✅ Works offline after initial load

## Future Enhancements

Possible improvements:
- [ ] In-app PDF viewer (using flutter_pdfview)
- [ ] PDF preview thumbnails
- [ ] Batch download multiple reports
- [ ] Share report via email
- [ ] Print report directly
- [ ] PDF annotations/comments
- [ ] Report versioning
- [ ] Encrypted PDF storage
- [ ] Watermarking for security
- [ ] Access logs/audit trail

## Example URLs

### View PDF
```
http://127.0.0.1:8000/api/reports/view/1
http://127.0.0.1:8000/api/reports/view/2
```

### Download PDF
```
http://127.0.0.1:8000/api/reports/download/1
http://127.0.0.1:8000/api/reports/download/2
```

## Troubleshooting

### PDF doesn't open
- Check if backend is running
- Verify report ID exists
- Check browser popup blocker
- Try different browser

### Download doesn't start
- Check browser download settings
- Verify sufficient disk space
- Check file permissions
- Try clearing browser cache

### 403 Forbidden error
- Verify you're logged in
- Check you have permission for this report
- Try logging out and back in

### File not found error
- Report may have been deleted
- File may have been moved
- Contact admin to re-upload

## API Response Examples

### Successful View/Download
```
HTTP 200 OK
Content-Type: application/pdf
Content-Disposition: inline; filename=report.pdf
[PDF binary data]
```

### Unauthorized
```json
{
  "detail": "Not authorized to access this report"
}
```

### Not Found
```json
{
  "detail": "Report file not found"
}
```
