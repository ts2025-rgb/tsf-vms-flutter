# Backend Requirements for Enhanced VMS Dashboard Metrics

## Date: January 22, 2026

---

## 📊 New Metrics & Features Required

### 1. **Call Tracking Metrics**

#### Data Needed from Backend:

**Endpoint**: `GET /admin/vms/call-metrics`

**Query Parameters**:
- `filter`: `3days` | `week` | `month` | `all` (default: `all`)
- `volunteerId`: Optional - filter for specific volunteer

**Response Structure**:
```json
{
  "success": true,
  "data": {
    "totalCalls": 156,
    "callFrequency": {
      "daily": 5.2,
      "weekly": 36.4,
      "monthly": 156
    },
    "totalCallHours": 234.5,
    "averageCallDuration": 1.5,
    "callsByTimeRange": {
      "last3Days": 16,
      "lastWeek": 36,
      "lastMonth": 156
    }
  }
}
```

---

### 2. **Mood Tracking**

#### Data Needed from Backend:

**Endpoint**: `GET /admin/vms/mood-metrics`

**Query Parameters**:
- `filter`: `3days` | `week` | `month` | `all`
- `volunteerId`: Optional

**Response Structure**:
```json
{
  "success": true,
  "data": {
    "averageMood": 7.8,
    "moodTrend": "improving",
    "moodDistribution": {
      "excellent": 45,
      "good": 32,
      "neutral": 15,
      "poor": 8
    },
    "moodOverTime": [
      {"date": "2026-01-20", "average": 7.5},
      {"date": "2026-01-21", "average": 8.1},
      {"date": "2026-01-22", "average": 7.8}
    ]
  }
}
```

---

### 3. **Self-Esteem Tracking**

#### Data Needed from Backend:

**Endpoint**: `GET /admin/vms/self-esteem-metrics`

**Query Parameters**:
- `filter`: `3days` | `week` | `month` | `all`
- `volunteerId`: Optional

**Response Structure**:
```json
{
  "success": true,
  "data": {
    "averageSelfEsteem": 7.2,
    "selfEsteemTrend": "stable",
    "selfEsteemOverTime": [
      {"date": "2026-01-15", "score": 6.8},
      {"date": "2026-01-22", "score": 7.2}
    ],
    "improvementRate": 5.9
  }
}
```

---

### 4. **Call Quality Rating**

#### Schema Addition Required:

Add to your **Call/Session Schema**:
```javascript
{
  callQualityRating: {
    type: Number,
    min: 1,
    max: 5,
    default: null
  },
  callQualityNotes: {
    type: String,
    default: ""
  },
  ratedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  ratedAt: {
    type: Date
  }
}
```

**Endpoint**: `GET /admin/vms/call-quality-metrics`

**Response Structure**:
```json
{
  "success": true,
  "data": {
    "averageQualityRating": 4.2,
    "totalRatedCalls": 142,
    "qualityDistribution": {
      "5star": 45,
      "4star": 62,
      "3star": 25,
      "2star": 8,
      "1star": 2
    }
  }
}
```

**Endpoint to Rate**: `PATCH /admin/vms/calls/:callId/rate`
```json
{
  "rating": 4,
  "notes": "Great mentoring session"
}
```

---

### 5. **Learning Outcomes & Mentor Rating**

#### Schema Addition Required:

Add to **Volunteer/Mentor Schema**:
```javascript
{
  mentorRating: {
    type: Number,
    min: 1,
    max: 5,
    default: null
  },
  learningOutcomes: [{
    outcome: String,
    achievedDate: Date,
    ratingByMentee: Number,
    feedback: String
  }],
  totalMenteesFeedback: Number,
  averageMentorRating: Number
}
```

**Endpoint**: `GET /admin/vms/mentor-ratings`

**Response Structure**:
```json
{
  "success": true,
  "data": {
    "topRatedMentors": [
      {
        "volunteerId": "507f1f77bcf86cd799439011",
        "volunteerName": "John Doe",
        "averageRating": 4.8,
        "totalRatings": 25,
        "totalMentees": 12
      }
    ],
    "overallAverageRating": 4.3,
    "learningOutcomesAchieved": 345
  }
}
```

---

### 6. **Gamification - 12 Call Progress**

#### Data Needed from Backend:

**Endpoint**: `GET /admin/vms/volunteers/:id/progress`

**Response Structure**:
```json
{
  "success": true,
  "data": {
    "volunteerId": "507f1f77bcf86cd799439011",
    "volunteerName": "John Doe",
    "totalCallsCompleted": 8,
    "callsGoal": 12,
    "progressPercentage": 66.67,
    "milestones": [
      {"callNumber": 3, "achieved": true, "achievedDate": "2026-01-10"},
      {"callNumber": 6, "achieved": true, "achievedDate": "2026-01-18"},
      {"callNumber": 9, "achieved": false},
      {"callNumber": 12, "achieved": false}
    ],
    "nextMilestone": 9,
    "estimatedCompletionDate": "2026-02-05"
  }
}
```

---

### 7. **Export Data with Filters**

**Endpoint**: `GET /admin/vms/export`

**Query Parameters**:
- `format`: `csv` | `excel` | `json`
- `filter`: `3days` | `week` | `month` | `all`
- `metrics`: Array of metrics to include
  - `calls`
  - `mood`
  - `selfEsteem`
  - `callQuality`
  - `learningOutcomes`
- `includeVolunteers`: Boolean - include volunteer details

**Response**: File download or URL to download

---

### 8. **Enhanced Dashboard Endpoint**

**Endpoint**: `GET /admin/vms/dashboard/enhanced`

**Query Parameters**:
- `filter`: `3days` | `week` | `month` | `all`

**Response Structure**:
```json
{
  "success": true,
  "data": {
    "volunteers": {
      "total": 145,
      "active": 98,
      "inMentoring": 67
    },
    "calls": {
      "total": 1245,
      "totalHours": 1867.5,
      "averagePerVolunteer": 8.6,
      "frequencyDaily": 41.5
    },
    "mood": {
      "average": 7.8,
      "trend": "improving"
    },
    "selfEsteem": {
      "average": 7.2,
      "trend": "stable"
    },
    "callQuality": {
      "average": 4.2,
      "totalRated": 1050
    },
    "mentorRatings": {
      "average": 4.3,
      "totalRated": 450
    },
    "gamification": {
      "volunteersCompleted12Calls": 23,
      "averageProgress": 65.4
    }
  }
}
```

---

## 🔧 Database Schema Changes Summary

### New Collections/Tables Needed:

1. **CallSessions**
```javascript
{
  volunteerId: ObjectId,
  menteeId: ObjectId,
  callDate: Date,
  duration: Number, // in minutes
  callQualityRating: Number,
  callQualityNotes: String,
  ratedBy: ObjectId,
  ratedAt: Date,
  mood: Number, // 1-10
  notes: String
}
```

2. **SelfEsteemTracking**
```javascript
{
  volunteerId: ObjectId,
  menteeId: ObjectId,
  score: Number, // 1-10
  recordedDate: Date,
  notes: String
}
```

3. **MentorRatings**
```javascript
{
  volunteerId: ObjectId, // the mentor
  menteeId: ObjectId, // who rated
  rating: Number, // 1-5
  feedback: String,
  ratedDate: Date,
  learningOutcomes: [String]
}
```

### Update to Existing Volunteer Schema:
```javascript
{
  // ... existing fields
  callStats: {
    totalCalls: Number,
    totalCallHours: Number,
    averageCallDuration: Number,
    lastCallDate: Date
  },
  gamification: {
    currentCallCount: Number,
    callGoal: Number,
    milestonesAchieved: [Number],
    completionDate: Date
  }
}
```

---

## 📱 API Endpoints Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/admin/vms/dashboard/enhanced` | GET | Get all enhanced metrics |
| `/admin/vms/call-metrics` | GET | Get call tracking data |
| `/admin/vms/mood-metrics` | GET | Get mood averages |
| `/admin/vms/self-esteem-metrics` | GET | Get self-esteem tracking |
| `/admin/vms/call-quality-metrics` | GET | Get call quality ratings |
| `/admin/vms/mentor-ratings` | GET | Get mentor ratings & outcomes |
| `/admin/vms/volunteers/:id/progress` | GET | Get individual progress |
| `/admin/vms/calls/:callId/rate` | PATCH | Rate a call quality |
| `/admin/vms/export` | GET | Export data with filters |

---

## 🎨 Frontend Implementation Plan

Once backend provides these endpoints, we will:

1. ✅ Create new data models for all metrics
2. ✅ Update VMSService with new API calls
3. ✅ Create enhanced dashboard widgets
4. ✅ Add filter controls (3 days, week, month)
5. ✅ Implement number of calls display (top left)
6. ✅ Create gamification progress bar component
7. ✅ Add mood and self-esteem visualization
8. ✅ Create mentor rating display
9. ✅ Implement export functionality

---

## 📋 Priority Order for Backend Implementation

1. **Phase 1** (Critical):
   - Enhanced dashboard endpoint with basic call metrics
   - Call tracking schema and endpoints
   - Export functionality

2. **Phase 2** (High Priority):
   - Mood tracking
   - Self-esteem tracking
   - Call quality rating

3. **Phase 3** (Enhancement):
   - Gamification progress tracking
   - Mentor ratings
   - Learning outcomes

---

**Note**: All endpoints should support pagination, sorting, and the time-based filters (3 days, week, month, all).
