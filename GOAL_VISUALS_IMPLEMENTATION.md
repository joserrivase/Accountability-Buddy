# Goal Visuals Implementation

This document describes the visual system implemented for goal tracking based on questionnaire answers.

## Visual Components Created

All visual components are in `Views/GoalVisuals.swift`:

1. **ListVisual** - Simple list of completed items with checkmarks
2. **UserCreatedListVisual** - Collaborative list with checkboxes per user
3. **SumBoxVisual** - Total items completed count
4. **SumBoxGoalVisual** - Progress toward a goal with percentage bar
5. **EndDateBoxVisual** - End date and days remaining
6. **CalendarWithCheckVisual** - Calendar view with daily checkmarks
7. **StreakCounterVisual** - Current and max streak display
8. **TotalDaysCountVisual** - Total days completed count
9. **BarChartVisual** - Daily totals in bar chart (week/month/year view)
10. **BarTotalsVisual** - Aggregated stats (total, average, max)

## Visual Selection Logic

The `GoalVisualSelector` in `Views/GoalVisualSelector.swift` determines which visuals to show based on:
- `goal_type` (list_tracker, daily_tracker, list_created_by_user)
- `challenge_or_friendly` (challenge, friendly)
- `winning_condition` (for challenge mode)
- `keep_streak` (for daily_tracker)
- `track_daily_quantity` (for daily_tracker)

## Visual Scenarios Implemented

### Visual 1: List Tracker + Friendly
- **Condition:** `goal_type = "list_tracker"` AND `challenge_or_friendly = "friendly"`
- **Visuals:** List + Sum Box

### Visual 2: List Tracker + Challenge + First to Reach X
- **Condition:** `goal_type = "list_tracker"` AND `challenge_or_friendly = "challenge"` AND `winning_condition` contains "first to reach X number"
- **Visuals:** List + Sum Box Goal

### Visual 3: List Tracker + Challenge + Most by End Date
- **Condition:** `goal_type = "list_tracker"` AND `challenge_or_friendly = "challenge"` AND `winning_condition` contains "most number" AND "end date"
- **Visuals:** List + End Date Box

### Visual 4: List Created + Friendly
- **Condition:** `goal_type = "list_created_by_user"` AND `challenge_or_friendly = "friendly"`
- **Visuals:** User Created List + Sum Box Goal

### Visual 5: List Created + Challenge + First to Finish
- **Condition:** `goal_type = "list_created_by_user"` AND `challenge_or_friendly = "challenge"` AND `winning_condition` contains "first to finish"
- **Visuals:** User Created List + Sum Box Goal

### Visual 6: List Created + Challenge + Most by End Date
- **Condition:** `goal_type = "list_created_by_user"` AND `challenge_or_friendly = "challenge"` AND `winning_condition` contains "most number" AND "end date"
- **Visuals:** User Created List + Sum Box Goal + End Date Box

### Daily Tracker Scenarios
- **Base Visuals:** Calendar with Check + Total Days Count (always shown)
- **If `keep_streak = true`:** Add Streak Counter
- **If `track_daily_quantity = true`:** Add Bar Chart + Bar Totals
- **If challenge mode AND winning condition is "first person to complete X number of units":** Add Sum Box Goal (with quantity)

## Progress Tracking Structure

### List Tracker (`list_tracker`)
- **Storage:** `goal_progress.list_items` (JSONB)
- **Structure:** `[{id, title, date}]`
- **Usage:** User adds items dynamically

### List Created By User (`list_created_by_user`)
- **Original List:** `goals.list_items` (TEXT[])
- **Completed Items:** `goal_progress.list_items` (JSONB)
- **Matching:** Items matched by title (case-insensitive, trimmed)
- **Usage:** User checks off items from predefined list

### Daily Tracker (`daily_tracker`)
- **Days Completed:** `goal_progress.completed_days` (TEXT[])
- **Total Quantity:** `goal_progress.numeric_value` (DOUBLE PRECISION)
- **Daily Quantities:** `goal_progress.list_items` (JSONB) - stores `{title: "quantity", date: date}`
- **Usage:** 
  - Mark days as completed
  - Optionally track daily quantities
  - Optionally track streaks

## Database Schema

### No Schema Changes Required

The existing `goals` and `goal_progress` tables support all scenarios:

- **`goals` table:** Already has all questionnaire fields (see `GOALS_DATABASE_UPDATE.md`)
- **`goal_progress` table:** Already supports:
  - `numeric_value` for totals
  - `completed_days` for day tracking
  - `list_items` (JSONB) for list items and daily quantities

### Note on Daily Quantity Tracking

For daily tracker with quantity, we store daily entries in `list_items` as:
```json
[
  {"id": "uuid", "title": "5.2", "date": "2025-01-15T10:00:00Z"},
  {"id": "uuid", "title": "6.1", "date": "2025-01-16T10:00:00Z"}
]
```

The `title` field stores the quantity as a string (which can be parsed to Double), and `date` stores when it was recorded.

## Tracking Method Field

The `tracking_method` field in the `goals` table is still used for:
- Backward compatibility with old goals
- Determining which progress fields to use

For new goals created via questionnaire:
- `list_tracker` → `tracking_method = "input_list"`
- `daily_tracker` → `tracking_method = "track_days_completed"`
- `list_created_by_user` → `tracking_method = "input_list"`

**Recommendation:** Keep `tracking_method` for now as it's used by the progress update logic. We can deprecate it later if needed.

## Implementation Notes

1. **List Created By User Matching:** Items are matched by normalized title (lowercase, trimmed). This works for most cases but may have edge cases with special characters.

2. **Daily Quantity Storage:** Currently using `list_items` to store daily quantities. For production, you might want a dedicated `daily_quantity_entries` JSONB field.

3. **Bar Chart:** Uses Swift Charts (iOS 16+) with fallback for older iOS versions.

4. **Streak Calculation:** Calculates current streak (backwards from today) and max streak (longest consecutive period).

5. **User Names:** Currently using "Me" and "Buddy" as placeholders. You can enhance this by fetching user profiles.

## Next Steps

1. ✅ Visual components created
2. ✅ Visual selector logic implemented
3. ✅ GoalDetailView updated to use new visuals
4. ⏳ Test all visual scenarios
5. ⏳ Enhance user name display (fetch from profiles)
6. ⏳ Add buddy progress comparison views where appropriate

