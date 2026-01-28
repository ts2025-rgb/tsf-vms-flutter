# CCP Analytics Dashboard - Quick Start Guide

## 🚀 What's New

A comprehensive analytics dashboard has been added for Companion Connect Program (CCP) administrators.

## 📍 How to Access

### From Admin Dashboard
1. Log in as admin
2. Look for the **green floating action button** at the bottom right
3. Click **"CCP Analytics"** button
4. Dashboard will open showing all metrics and visualizations

### Alternative Access
The dashboard can also be integrated into your navigation menu or app drawer.

## 📊 What You'll See

### Overview Cards (Top)
- 📊 **Total Volunteers** - All CCP volunteers
- ✅ **Active Volunteers** - Currently mentoring
- 🎓 **Total Mentees** - All registered mentees
- ❓ **Pending Queries** - Unanswered volunteer questions

### Call Statistics
- ⏱️ **Total Hours** - Sum of all call durations
- ⏲️ **Average Duration** - Mean call length in minutes

### Volunteer Lifecycle
- 🥧 **Pie Chart** - Visual distribution of volunteer stages
- 📊 **Progress Bars** - Detailed breakdown with percentages
- Shows: Onboarding → Training → Active → Exit Pending → Completed

### Mentee Assignments
- ✅ **Assigned** - Mentees with volunteers
- ⚠️ **Unassigned** - Awaiting assignment
- 📈 **Assignment Rate** - Percentage assigned

### Top Performers
- 🏆 **Bar Chart** - Top 5 volunteers by call hours
- Interactive tooltips on hover

### Recent Queries
- 📝 Last 5 volunteer queries
- Status indicators (Pending/Replied)

## 🔄 Refreshing Data

- **Pull down** on the screen to refresh
- Or click the **refresh icon** in the app bar

## 🎨 Color Indicators

- **Green** - Positive/Active metrics
- **Orange** - Pending/Unassigned items
- **Red** - Urgent/Pending queries
- **Blue** - Primary information

## 📱 Navigation Buttons

Three floating action buttons at bottom right:
1. **CCP Analytics** (Green) - This dashboard
2. **Manage Mentees** (Blue) - Mentee management
3. **Manage Queries** (Orange) - Query management

## 🔍 Understanding the Data

### Who is a CCP Volunteer?
Volunteers are counted if their `interestedPrograms` includes "Companion Connect"

### Lifecycle Stages
- **Onboarding**: New volunteers getting oriented
- **Training**: Volunteers in training phase
- **Active**: Currently mentoring mentees
- **Exit Pending**: Requested exit or handover in progress
- **Completed**: Successfully exited the program

### Call Statistics
Based on the `callStats` object in volunteer profiles:
- Total calls made
- Total hours spent on calls
- Average duration calculated automatically

## 🛠️ Technical Requirements

### Backend API Endpoints Required
```
✅ GET /admin/volunteers
✅ GET /companion-connect/admin/mentees
✅ GET /companion-connect/admin/queries
```

All require admin authentication token.

## 💡 Tips

1. **Best Time to Check**: Daily or weekly for trends
2. **Focus Areas**:
   - Low assignment rate? Assign more mentees
   - High pending queries? Respond to volunteers
   - Few active volunteers? Approve pending applications
3. **Performance Tracking**: Use Top Performers chart to recognize volunteers
4. **Lifecycle Monitoring**: Ensure smooth progression through stages

## 🐛 Troubleshooting

### Dashboard Not Loading?
- Check internet connection
- Verify admin token is valid
- Check backend API is running

### Empty Data?
- Ensure volunteers have selected "Companion Connect" program
- Check that mentees are created in the system
- Verify API endpoints return data

### Charts Not Showing?
- Requires at least 1 volunteer with data
- Pie chart needs volunteers in different stages
- Bar chart needs volunteers with call hours

## 📈 Future Enhancements

Coming soon:
- Export to CSV
- Date range filters
- Trend analysis over time
- Detailed reports
- Email notifications

## 📞 Support

For issues:
1. Check console for error messages
2. Verify API responses in network tab
3. Ensure admin token is valid
4. Check backend logs

---

**Version**: 1.0.0  
**Last Updated**: January 27, 2026  
**Dependencies**: Flutter, fl_chart, http, flutter_secure_storage
