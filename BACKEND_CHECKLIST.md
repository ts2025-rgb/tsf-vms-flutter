# Companion Connect Backend - Implementation Checklist

## 🚨 FRONTEND IS READY - WAITING FOR THESE ENDPOINTS

The Flutter frontend is **100% complete** and ready to use. It just needs these backend endpoints to be implemented.

---

## 🔑 IMPORTANT: Admin Token

**Admin endpoints** receive the token from admin login response:
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "email": "admin@tsf.com",
    "role": "admin"
  }
}
```

This token is sent in **all admin endpoints** as:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Your backend must **decode the token** and verify `role === "admin"` for admin-only endpoints.

---

## ✅ Required Endpoints

### **1. GET /api/companion-connect/admin/mentees**
**Purpose:** Fetch all mentees for admin dashboard

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "mentees": [
    {
      "_id": "678abc...",
      "fullName": "John Doe",
      "age": 16,
      "gender": "Male",
      "phone": "+91 98634 61949",
      "location": "Imphal",
      "assignedTo": {
        "_id": "678vol...",
        "fullName": "Jane Smith"
      },
      "currentCell": 1,
      "status": "active"
    }
  ]
}
```

---

### **2. POST /api/companion-connect/admin/mentees**
**Purpose:** Create new mentee

**Headers:**
```
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Body:**
```json
{
  "fullName": "John Doe",
  "dob": "2009-05-15",
  "gender": "Male",
  "phone": "+91 98634 61949",
  "location": "Imphal",
  "programId": "6795d79f30cff35de1a08f79"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Mentee created successfully",
  "mentee": { ... }
}
```

---

### **3. POST /api/companion-connect/admin/assign-mentee**
**Purpose:** Assign mentee to volunteer

**Body:**
```json
{
  "menteeId": "678abc...",
  "volunteerId": "678vol..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Mentee assigned successfully"
}
```

---

### **4. POST /api/companion-connect/admin/unassign-mentee**
**Purpose:** Remove mentee assignment

**Body:**
```json
{
  "menteeId": "678abc..."
}
```

---

### **5. GET /api/companion-connect/mentee**
**Purpose:** Get volunteer's assigned mentee

**Headers:**
```
Authorization: Bearer <volunteer_token>
```

**Response:**
```json
{
  "success": true,
  "mentee": {
    "_id": "678abc...",
    "fullName": "John Doe",
    "age": 16,
    "phone": "+91 98634 61949",
    "location": "Imphal",
    "currentCell": 1,
    "assignedAt": "2026-01-13T10:00:00.000Z",
    "photoUrl": "https://..."
  }
}
```

---

### **6. POST /api/companion-connect/notes**
**Purpose:** Save post-call note

**Body:**
```json
{
  "menteeId": "678abc...",
  "note": "Great progress...",
  "cellNumber": 1,
  "callDuration": 45,
  "followUpRequired": false,
  "moodScore": 4,
  "checklist": [{"label": "Health", "isAchieved": true}],
  "topics": ["Studies", "Health"],
  "assistanceRequest": "Need help with...",
  "mentorHelpfulness": "Yes",
  "redFlags": "None"
}
```

---

### **7. GET /api/companion-connect/notes/:menteeId**
**Purpose:** Get call notes history

**Response:**
```json
{
  "success": true,
  "notes": [
    {
      "_id": "678note...",
      "cellNumber": 1,
      "note": "Discussion about...",
      "callDate": "2026-01-13T10:00:00.000Z",
      "callDuration": 45
    }
  ]
}
```

---

### **8. PATCH /api/companion-connect/progress**
**Purpose:** Advance mentee to next cell

**Body:**
```json
{
  "menteeId": "678abc...",
  "newCell": 2
}
```

**Response:**
```json
{
  "success": true,
  "message": "Progress updated successfully to Cell 2"
}
```

---

## 💬 Query System Endpoints

### **9. POST /api/companion-connect/queries**
**Purpose:** Submit a query from volunteer
**Headers:** `Authorization: Bearer <volunteer_token>`

**Body:**
```json
{
  "query": "I need help with...",
  "menteeId": "678abc..."
}
```

### **9.5. GET /api/companion-connect/queries**
**Purpose:** Get logged-in volunteer's query history
**Headers:** `Authorization: Bearer <volunteer_token>`

**Response:**
```json
{
  "success": true,
  "queries": [
    {
      "_id": "query123",
      "query": "How do I...",
      "reply": "You can...",
      "status": "replied",
      "createdAt": "2026-01-13T..."
    }
  ]
}
```

---

### **10. GET /api/companion-connect/admin/queries**
**Purpose:** Get all queries for admin
**Headers:** `Authorization: Bearer <admin_token>`

**Response:**
```json
{
  "success": true,
  "queries": [
    {
      "_id": "query123",
      "query": "I need help with...",
      "reply": null,
      "status": "pending",
      "volunteerName": "John Volunteer",
      "createdAt": "2026-01-13T..."
    }
  ]
}
```

---

### **11. POST /api/companion-connect/admin/queries/:id/reply**
**Purpose:** Reply to a query
**Headers:** `Authorization: Bearer <admin_token>`

**Body:**
```json
{
  "reply": "Here is the solution..."
}
```

---

## 📋 Database Models Needed

### Query
```javascript
{
  volunteerId: ObjectId (ref: User),
  menteeId: ObjectId (ref: Mentee),
  query: String,
  reply: String,
  status: String (default: 'pending', enum: ['pending', 'replied']),
  createdAt: Date,
  repliedAt: Date
}
```

### Mentee
```javascript
{
  fullName: String,
  age: Number (auto-calc from dob),
  dob: Date,
  gender: String,
  phone: String,
  location: String,
  assignedTo: ObjectId (ref: User),
  assignedAt: Date,
  programId: ObjectId (ref: Program),
  currentCell: Number (Any positive integer),
  status: String (active/completed/paused),
  photoUrl: String,
  notes: String
}
```

### CallNote
```javascript
{
  menteeId: ObjectId (ref: Mentee),
  volunteerId: ObjectId (ref: User),
  cellNumber: Number (Tagged Call #),
  note: String,
  callDate: Date,
  callDuration: Number,
  followUpRequired: Boolean,
  moodScore: Number,
  checklist: Array,
  topics: Array,
  otherTopicDetail: String,
  assistanceRequest: String,
  mentorHelpfulness: String,
  redFlags: String
}
```

---

## 🎯 Testing Guide

Once backend is ready, test in this order:

1. **Login as admin** → Click 👥 icon
2. **Create mentee** → Click "Add Mentee" button
3. **Assign to volunteer** → Click "Assign" on mentee card
4. **Login as volunteer** → See Companion Connect card
5. **View mentee** → Click card to see assigned mentee
6. **Log note** → Fill form and save
7. **Advance progress** → Click "Advance" button

---

## Frontend Files Ready:
✅ `lib/admin_mentee_management.dart` - Admin dashboard
✅ `lib/create_mentee_page.dart` - Create mentee form  
✅ `lib/companionconnect.dart` - Volunteer mentee page

**Everything is built and waiting!** 🚀
