# Companion Connect Program (CCP) Admin Dashboard

## Overview
The CCP Admin Dashboard provides comprehensive analytics and metrics for the Companion Connect Program volunteers and mentees.

## Features

### 📊 Dashboard Sections

#### 1. Program Overview
- **Total Volunteers**: Count of all CCP volunteers
- **Active Volunteers**: Currently active mentors
- **Total Mentees**: All registered mentees
- **Pending Queries**: Unanswered volunteer queries

#### 2. Call Statistics
- **Total Hours**: Cumulative call duration across all volunteers
- **Average Duration**: Mean call duration in minutes

#### 3. Volunteer Lifecycle Visualization
- **Pie Chart**: Visual distribution of volunteers across lifecycle stages
- **Progress Bars**: Detailed breakdown with percentages
- **Stages Tracked**:
  - Onboarding (in_progress)
  - Training (in_progress)
  - Active (active mentoring)
  - Exit Pending (exit_requested or handover_pending)
  - Completed (exited)

#### 4. Mentee Assignment Status
- **Assigned**: Mentees with assigned volunteers
- **Unassigned**: Mentees awaiting assignment
- **Assignment Rate**: Percentage of assigned mentees

#### 5. Top Performers Chart
- **Bar Chart**: Top 5 volunteers by call hours
- **Interactive Tooltips**: Hover to see exact hours
- Sorted by total call hours in descending order

#### 6. Recent Queries
- Last 5 queries from volunteers
- Status indicators (Pending/Replied)
- Quick view of volunteer name and query text

## API Endpoints Used

### Volunteer Data
```
GET /admin/volunteers
Authorization: Bearer {adminToken}
```
Returns all volunteers with complete profiles including:
- Personal information
- Call statistics
- Lifecycle statuses
- Gamification metrics
- Program interests

### Mentee Data
```
GET /companion-connect/admin/mentees
Authorization: Bearer {adminToken}
```
Returns all mentees with:
- Personal details
- Assignment status
- Program details

### Query Data
```
GET /companion-connect/admin/queries
Authorization: Bearer {adminToken}
```
Returns all volunteer queries with:
- Query text
- Volunteer information
- Status (pending/replied)
- Timestamps
- Admin replies

## Metrics Calculated

### Volunteer Filtering
Volunteers are filtered for CCP by checking if their `interestedPrograms` contains "companion connect" (case-insensitive).

### Call Statistics
- **Total Hours**: Sum of `callStats.totalCallHours` across all CCP volunteers
- **Average Duration**: Total hours converted to minutes ÷ total calls

### Lifecycle Breakdown
Counts volunteers by their status:
- `onboardingStatus == 'in_progress'`
- `trainingStatus == 'in_progress'`
- `mentoringStatus == 'active'`
- `exitStatus == 'exit_requested' || 'handover_pending'`
- `exitStatus == 'exited'`

### Query Metrics
- **Pending**: Count where `status == 'pending'`
- **Total**: All queries from CCP volunteers

## Usage

### Access
Navigate from the Admin Dashboard:
1. Click the floating action button "CCP Analytics" (green button with analytics icon)
2. Or add to app navigation routes

### Refresh Data
- Pull down to refresh on mobile
- Click refresh icon in app bar

### Navigation
The dashboard is a standalone screen that can be accessed via:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CCPAdminDashboardScreen(),
  ),
);
```

## Visualizations

### Charts Used
1. **Pie Chart** (fl_chart): Lifecycle distribution
2. **Bar Chart** (fl_chart): Top performers
3. **Linear Progress Indicators**: Lifecycle percentages
4. **Metric Cards**: Key statistics

### Color Scheme
- **Primary Blue**: Overall theme
- **Accent Green**: Positive metrics, assigned mentees
- **Accent Orange**: Pending items, unassigned mentees
- **Red**: Urgent items, pending queries
- **Lifecycle Colors**:
  - Onboarding: Blue
  - Training: Purple
  - Active: Green
  - Exit Pending: Orange
  - Completed: Grey

## Future Enhancements

### Potential Features
1. **Export to CSV**: Download dashboard data
2. **Date Range Filters**: View metrics for specific periods
3. **Trend Analysis**: Track metrics over time
4. **Detailed Drill-Down**: Click metrics to view detailed volunteer lists
5. **Real-time Updates**: WebSocket integration for live data
6. **Comparative Analytics**: Compare volunteers, mentees by region
7. **Performance Reports**: Automated PDF reports
8. **Alert System**: Notify admins of low assignment rates

### Additional Metrics
- Mentee satisfaction scores
- Average calls per volunteer
- Volunteer retention rate
- Time to mentee assignment
- Query response time
- Completion rate by region

## Technical Details

### Dependencies
```yaml
fl_chart: ^0.70.1  # Charts and visualizations
http: ^1.2.0       # API calls
flutter_secure_storage: ^9.2.4  # Token storage
google_fonts: ^6.2.1  # Typography
```

### Authentication
Uses Flutter Secure Storage to retrieve admin token:
```dart
final token = await secureStorage.read(key: "adminToken");
```

### Error Handling
- Token validation
- API error responses
- Network connectivity issues
- Empty state handling

### Performance
- Parallel API calls using `Future.wait()`
- Efficient data filtering and calculations
- Optimized widget rebuilds

## Support

For issues or questions:
1. Check API connectivity
2. Verify admin token validity
3. Review backend API documentation
4. Check console for error logs

## Version
**v1.0.0** - Initial release with core dashboard features
