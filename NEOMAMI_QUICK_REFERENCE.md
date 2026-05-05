# Neomami Hub - Quick Reference Guide

## 🚀 Quick Start

### For Volunteers
1. **Access:** Tap "Neomami Hub" card on home screen (only if subscribed)
2. **Create Entry:** Click "New Entry" button
3. **Fill Form:** Title, Description, Hours, Skills
4. **Save:** Entry is immediately saved to backend
5. **View:** All entries displayed in list format
6. **Edit/Delete:** Use action buttons on each card

### For Admins
1. **Access:** Navigate to `/admin/neomami` route
2. **View All:** See entries from all volunteers
3. **Search:** Use search box to filter by name/content
4. **Statistics:** View total entries and hours at top
5. **Details:** Tap any entry to see full information

---

## 📱 Navigation

### Volunteer Routes
```dart
Navigator.pushNamed(context, '/neomami-hub');
```

### Admin Routes
```dart
Navigator.pushNamed(context, '/admin/neomami');
```

---

## 🔑 Key Classes

### NeomamEntry
```dart
NeomamEntry(
  volunteerId: String,      // Required
  title: String,            // Required
  description: String,      // Required
  hoursDedicated: int,      // Required (numeric)
  skillsLearned: String,    // Required
)
```

### NeomamService
```dart
// Create
await neomamService.createNeomamEntry(entry);

// Read
await neomamService.getVolunteerNeomamEntries();
await neomamService.getNeomamEntry(entryId);

// Update
await neomamService.updateNeomamEntry(entryId, updatedEntry);

// Delete
await neomamService.deleteNeomamEntry(entryId);
```

---

## 🎨 UI Components

### Main Screens
- **NeomamHubScreen** - Volunteer entry management
- **NeomamAdminScreen** - Admin dashboard

### Sub-Components
- **_EntryCard** - Display single entry
- **_CreateEntryDialog** - Create new entry form
- **_EditEntryDialog** - Edit entry form

---

## 📊 Data Flow

```
User Action
    ↓
UI Widget (_showCreateDialog, etc)
    ↓
Service Call (NeomamService)
    ↓
API Request (HTTP with Bearer token)
    ↓
Backend Validation (Auth + Subscription)
    ↓
Database Operation
    ↓
Response to Service
    ↓
UI Update (setState)
    ↓
SnackBar Notification
```

---

## 🔒 Security Checks

### Volunteer Endpoints
```
✅ Authentication (Token)
✅ Subscription Status
✅ Authorization (Own entries only)
```

### Admin Endpoints
```
✅ Authentication (Admin token)
✅ Authorization (Admin role)
✅ No subscription check
```

---

## ⚠️ Error Codes

| Status | Meaning | Response |
|--------|---------|----------|
| 200/201 | Success | Entry data |
| 400 | Bad Request | Invalid input |
| 401 | Unauthorized | Invalid token |
| 403 | Forbidden | Not subscribed |
| 404 | Not Found | Entry doesn't exist |
| 500 | Server Error | Backend issue |

---

## 📝 API Response Examples

### Success
```json
{
  "success": true,
  "message": "Entry created successfully",
  "data": { ... }
}
```

### Subscription Error
```json
{
  "success": false,
  "message": "You are not subscribed to the Neomami Hub program"
}
```

### Auth Error
```json
{
  "success": false,
  "message": "Authentication failed. Please login again."
}
```

---

## 🧪 Testing

### Manual Testing
1. **Create:** Add entry → Verify in list
2. **Read:** Open entry → Check all fields display
3. **Update:** Edit entry → Verify changes saved
4. **Delete:** Delete entry → Confirm removal
5. **Search:** Type in search → Verify filtering (Admin)
6. **Subscription:** Test with non-subscribed user → Should get 403

### Test Data
```dart
final testEntry = NeomamEntry(
  volunteerId: '507f1f77bcf86cd799439011',
  title: 'Community Workshop',
  description: 'Organized a digital literacy workshop',
  hoursDedicated: 5,
  skillsLearned: 'Communication, Teaching, Leadership',
);
```

---

## 🐛 Common Issues & Solutions

### Issue: "You are not subscribed to the Neomami Hub program"
**Solution:** User hasn't subscribed or token is for non-subscribed account. Ensure user is enrolled in the Neomami Hub program.

### Issue: "Authentication failed. Please login again."
**Solution:** Token expired or not found in secure storage. User needs to re-login.

### Issue: Entries not loading
**Solution:** Check network connectivity. Try retry button. Verify backend is running.

### Issue: Changes not reflected immediately
**Solution:** UI updates use setState. Ensure refresh after API response. Check for setTimeout delays.

---

## 📚 Files Reference

| File | Purpose |
|------|---------|
| `neomami_model.dart` | Data structures |
| `neomami_service.dart` | API communication |
| `neomami_hub_screen.dart` | Volunteer UI |
| `neomami_admin_screen.dart` | Admin UI |
| `home_screen.dart` | Navigation card |
| `main.dart` | Routes |

---

## 🔗 Integration Points

### Home Screen
- New "Neomami Hub" card added
- Only visible to approved volunteers
- Navigates to `/neomami-hub`

### Admin Panel
- New route `/admin/neomami`
- Can be added to admin menu

### Profile
- Could show Neomami stats on volunteer profile

---

## 💡 Tips & Best Practices

### For Users
- Always fill in all fields before saving
- Use clear, descriptive titles
- Be specific about skills learned
- Review entries before deleting
- Use search to find past entries quickly

### For Developers
- Always validate token before API calls
- Handle network errors gracefully
- Show loading/error states to user
- Log API responses for debugging
- Test with both subscribed and non-subscribed users

---

## 📞 Support

For issues or questions:
1. Check the NEOMAMI_HUB_IMPLEMENTATION.md for detailed docs
2. Review error messages - they're user-friendly
3. Check backend API logs
4. Verify token and subscription status
5. Test with different user roles (volunteer/admin)

---

## ✅ Checklist Before Going Live

- [ ] Backend API endpoints tested
- [ ] Subscription validation working
- [ ] Tokens properly stored/retrieved
- [ ] Error messages user-friendly
- [ ] UI responsive on all devices
- [ ] Loading states show progress
- [ ] Empty states display helpfully
- [ ] Admin can view all entries
- [ ] Volunteers can only see own entries
- [ ] Non-subscribed users get proper error
- [ ] All CRUD operations working
- [ ] Search functionality working (admin)
- [ ] Delete confirmation dialog shows
- [ ] Timestamps display correctly
- [ ] Navigation routes working

---

Last Updated: 2024-05-05
