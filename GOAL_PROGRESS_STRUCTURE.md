# Goal Progress Table Structure

This document describes how the `goal_progress` table should be structured to handle all questionnaire scenarios.

## Current Structure

The `goal_progress` table currently has:
- `numeric_value` (DOUBLE PRECISION) - for input_numbers tracking
- `completed_days` (TEXT[]) - array of date strings for track_days_completed
- `list_items` (JSONB) - array of completed items with timestamps

## Tracking Scenarios

### 1. List Tracker (`list_tracker`)
- **Tracking Method:** `input_list`
- **Progress Storage:** `list_items` (JSONB)
- **Structure:** Array of `{id, title, date}` objects
- **Example:** User adds "Book 1", "Book 2", etc. with timestamps

### 2. Daily Tracker (`daily_tracker`)
- **Tracking Method:** `track_days_completed`
- **Progress Storage:** 
  - `completed_days` (TEXT[]) - array of date strings (YYYY-MM-DD)
  - `numeric_value` (DOUBLE PRECISION) - optional, for daily quantity totals if `track_daily_quantity` is true
- **Scenarios:**
  - **Streak only:** Use `completed_days` to track which days were completed
  - **Quantity only:** Use `numeric_value` for total quantity, `completed_days` for which days had entries
  - **Both:** Use both fields together

### 3. List Created By User (`list_created_by_user`)
- **Tracking Method:** `input_list`
- **Progress Storage:** `list_items` (JSONB)
- **Structure:** Array of `{id, title, date}` objects
- **Difference from List Tracker:** Items are predefined in `goals.list_items`, user marks them as complete

## Recommended Updates

For better tracking of daily quantities with dates, we might want to add a new field:

```sql
-- Optional: Add daily_quantity_entries for detailed daily quantity tracking
ALTER TABLE goal_progress
ADD COLUMN IF NOT EXISTS daily_quantity_entries JSONB;

COMMENT ON COLUMN goal_progress.daily_quantity_entries IS 'Array of {date, quantity, unit} objects for daily quantity tracking';
```

This would allow storing:
```json
[
  {"date": "2025-01-15", "quantity": 5.2, "unit": "Mi"},
  {"date": "2025-01-16", "quantity": 6.1, "unit": "Mi"}
]
```

However, for MVP, we can use:
- `completed_days` - to track which days had entries
- `numeric_value` - to store the total quantity accumulated

## Current Implementation

The current structure should work for all scenarios:

1. **List Tracker:** Uses `list_items` JSONB
2. **Daily Tracker (Streak):** Uses `completed_days` TEXT[]
3. **Daily Tracker (Quantity):** Uses `numeric_value` for total, `completed_days` for dates
4. **List Created By User:** Uses `list_items` JSONB

## Next Steps

1. ✅ Store questionnaire answers in `goals` table
2. ✅ Use existing `goal_progress` structure for all tracking scenarios
3. ⏳ Update goal detail views to display progress based on questionnaire answers
4. ⏳ Add visualizations based on goal type and challenge mode

