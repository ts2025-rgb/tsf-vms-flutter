# CCP Analytics Dashboard Layout

## Screen Structure

```
┌─────────────────────────────────────────┐
│  ← Companion Connect Analytics    🔄    │  App Bar (Gradient Blue)
├─────────────────────────────────────────┤
│                                         │
│  ┌────────────┐  ┌────────────┐        │  Overview Metrics
│  │ 👥 Total   │  │ ✅ Active  │        │  (2x2 Grid)
│  │    25      │  │    18      │        │
│  │ Volunteers │  │ Volunteers │        │
│  └────────────┘  └────────────┘        │
│                                         │
│  ┌────────────┐  ┌────────────┐        │
│  │ 🎓 Total   │  │ ❓ Pending │        │
│  │    42      │  │     3      │        │
│  │  Mentees   │  │  Queries   │        │
│  └────────────┘  └────────────┘        │
│                                         │
├─────────────────────────────────────────┤
│  📞 Call Statistics                     │  Call Stats Card
│                                         │
│  ┌────────────┐  ┌────────────┐        │
│  │ ⏱️ Total   │  │ ⏲️ Avg     │        │
│  │  142 hrs   │  │  45.2 min  │        │
│  └────────────┘  └────────────┘        │
│                                         │
├─────────────────────────────────────────┤
│  📊 Volunteer Lifecycle                 │  Lifecycle Section
│                                         │
│         ┌─────────┐                     │  Pie Chart
│      ┌──┤         ├──┐                  │
│      │  │    🥧   │  │                  │
│      └──┤         ├──┘                  │
│         └─────────┘                     │
│                                         │
│  ● Onboarding    5 (20%) ████████       │  Progress Bars
│  ● Training      8 (32%) █████████████  │
│  ● Active       18 (72%) ███████████████│
│  ● Exit Pending  2 (8%)  ███            │
│  ● Completed     7 (28%) █████████      │
│                                         │
├─────────────────────────────────────────┤
│  🔗 Mentee Assignments                  │  Assignment Status
│                                         │
│      ┌────────────┬────────────┐        │
│      │     38     │     4      │        │
│      │  Assigned  │ Unassigned │        │
│      └────────────┴────────────┘        │
│                                         │
│       90% Assignment Rate               │
│                                         │
├─────────────────────────────────────────┤
│  🏆 Top Performers                      │  Bar Chart
│                                         │
│     30h │                █              │
│     20h │          █     █     █        │
│     10h │     █    █     █     █     █  │
│      0h └────┴────┴─────┴─────┴────┴── │
│         Sarah John Maria Alex  David    │
│                                         │
├─────────────────────────────────────────┤
│  💬 Recent Queries                      │  Query List
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ John Doe               [PENDING] │   │
│  │ How to handle difficult...       │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ Sarah Smith            [REPLIED] │   │
│  │ What resources are...            │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
                                     ┌─────┐
                              🟢 CCP │ 📊  │  Floating
                              Analytics   │  Action
                              ─────────────┘  Buttons
                              🔵 Manage │ 🎓  │
                              Mentees  │     │
                              ─────────────┘
                              🟠 Manage │ ❓  │
                              Queries  │     │
                              ─────────────┘
```

## Color Scheme

### Primary Colors
- **App Bar**: Blue gradient (#2196F3 → #1976D2)
- **Cards**: White with subtle shadow
- **Background**: Light grey (#F5F5F5)

### Metric Colors
- **Total Volunteers**: Blue (#2196F3)
- **Active Volunteers**: Green (#4CAF50)
- **Total Mentees**: Orange (#FF9800)
- **Pending Queries**: Red (#F44336)

### Chart Colors
- **Onboarding**: Blue (#2196F3)
- **Training**: Purple (#9C27B0)
- **Active**: Green (#4CAF50)
- **Exit Pending**: Orange (#FF9800)
- **Completed**: Grey (#9E9E9E)
- **Top Performers Bar**: Green (#4CAF50)

### Status Indicators
- **Assigned**: Green background
- **Unassigned**: Orange background
- **Pending Query**: Red badge
- **Replied Query**: Green badge

## Interactive Elements

### Touchable/Clickable
1. **Refresh Button** (App Bar) - Reload all data
2. **Metric Cards** - Could expand for details (future)
3. **Chart Bars** - Show tooltip on tap/hover
4. **Pie Chart Sections** - Show percentage on tap/hover
5. **Query Cards** - Could expand to show full query (future)
6. **FAB Buttons** - Navigate to respective screens

### Scroll Behavior
- Entire page scrolls vertically
- App bar stays pinned at top
- Pull to refresh gesture enabled

## Responsive Design

### Mobile (< 600px)
- 2 columns for metric cards
- Charts at full width
- Stacked layout for all sections

### Tablet (600px - 1200px)
- 4 columns for metric cards
- Charts side by side where applicable
- More breathing room

### Desktop (> 1200px)
- Grid layout for better space utilization
- Charts side by side
- Maximum content width with margins

## Animation & Transitions

1. **Page Load**: Fade in with slight slide up
2. **Metric Cards**: Scale up on mount
3. **Charts**: Animated drawing (bars grow, pie animates)
4. **Refresh**: Circular progress with fade
5. **Query List**: Stagger animation for each item

## Accessibility

- All icons have semantic labels
- High contrast text
- Touch targets minimum 44x44 points
- Screen reader support for all data
- Color not the only indicator (icons + text)

## Real Data Example

```
Total Volunteers: 25
Active Volunteers: 18 (72%)
Total Mentees: 42
Assigned Mentees: 38 (90%)
Unassigned Mentees: 4 (10%)
Pending Queries: 3

Total Call Hours: 142
Average Call Duration: 45.2 minutes

Lifecycle Breakdown:
- Onboarding: 5 (20%)
- Training: 8 (32%)
- Active: 18 (72%)
- Exit Pending: 2 (8%)
- Completed: 7 (28%)

Top 5 Performers:
1. Sarah Johnson - 28 hours
2. John Smith - 22 hours
3. Maria Garcia - 20 hours
4. Alex Chen - 18 hours
5. David Brown - 15 hours
```
