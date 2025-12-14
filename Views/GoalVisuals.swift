//
//  GoalVisuals.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI
#if canImport(Charts)
import Charts
#endif

// MARK: - Visual Components

struct ListVisual: View {
    let myItems: [GoalListItem]
    let buddyItems: [GoalListItem]?
    let taskName: String?
    let showBothUsers: Bool
    
    let myName: String
    let buddyName: String?
    
    init(items: [GoalListItem], taskName: String?, buddyItems: [GoalListItem]? = nil, showBothUsers: Bool = false, myName: String = "Me", buddyName: String? = nil) {
        self.myItems = items
        self.buddyItems = buddyItems
        self.taskName = taskName
        self.showBothUsers = showBothUsers
        self.myName = myName
        self.buddyName = buddyName
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let taskName = taskName {
                Text("Completed \(taskName)")
                    .font(.headline)
            } else {
                Text("Completed Items")
                    .font(.headline)
            }
            
            if showBothUsers && buddyItems != nil {
                // Show both users side by side
                HStack(alignment: .top, spacing: 16) {
                    listColumn(title: myName, items: myItems)
                    if let buddyItems = buddyItems {
                        listColumn(title: buddyName ?? "Buddy", items: buddyItems)
                    }
                }
            } else {
                // Show single user list
                if myItems.isEmpty {
                    Text("No items completed yet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(myItems.sorted(by: { $0.date > $1.date })) { item in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(item.title)
                                .font(.body)
                            Spacer()
                            Text(formatDate(item.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func listColumn(title: String, items: [GoalListItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            if items.isEmpty {
                Text("No items yet")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(items.sorted(by: { $0.date > $1.date }).prefix(10)) { item in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(item.title)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct UserCreatedListVisual: View {
    let originalItems: [String]
    let myCompletedItems: [GoalListItem]
    let buddyCompletedItems: [GoalListItem]?
    let myName: String
    let buddyName: String?
    var onItemTap: ((String) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.headline)
            
            HStack(alignment: .top, spacing: 16) {
                // My column
                VStack(alignment: .leading, spacing: 8) {
                    Text(myName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(originalItems.enumerated()), id: \.offset) { index, item in
                        Button(action: {
                            onItemTap?(item)
                        }) {
                            HStack {
                                Image(systemName: isItemCompleted(item, in: myCompletedItems) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(isItemCompleted(item, in: myCompletedItems) ? .green : .gray)
                                Text(item)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .strikethrough(isItemCompleted(item, in: myCompletedItems))
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Buddy column
                if let buddyName = buddyName, let buddyItems = buddyCompletedItems {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(buddyName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        ForEach(Array(originalItems.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Image(systemName: isItemCompleted(item, in: buddyItems) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(isItemCompleted(item, in: buddyItems) ? .green : .gray)
                                Text(item)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .strikethrough(isItemCompleted(item, in: buddyItems))
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func isItemCompleted(_ item: String, in completedItems: [GoalListItem]) -> Bool {
        return completedItems.contains { $0.title.lowercased().trimmingCharacters(in: .whitespaces) == item.lowercased().trimmingCharacters(in: .whitespaces) }
    }
}

struct SumBoxVisual: View {
    let count: Int
    let label: String?
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.blue)
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Items Completed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SumBoxGoalVisual: View {
    let current: Int
    let goal: Int
    let label: String?
    
    private var percentage: Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(current) / \(goal)")
                    .font(.system(size: 36, weight: .bold))
                if let label = label {
                    Text(label)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(percentage * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EndDateBoxVisual: View {
    let endDate: Date
    let label: String?
    
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return max(components.day ?? 0, 0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(daysRemaining)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(daysRemaining <= 7 ? .red : .blue)
                Text(daysRemaining == 1 ? "Day Remaining" : "Days Remaining")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 4) {
                Text("End Date")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatDate(endDate))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct CalendarWithCheckVisual: View {
    let myCompletedDays: [String]
    let buddyCompletedDays: [String]?
    let onDateTap: ((String) -> Void)?
    let isCreator: Bool // To determine which color is blue (creator) vs red (buddy)
    let creatorName: String
    let buddyName: String?
    
    @State private var currentMonth: Date = Date()
    @State private var localMyCompletedDays: [String] = []
    @State private var localBuddyCompletedDays: [String]? = nil
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    
    // New initializer with both users' data
    init(myCompletedDays: [String], buddyCompletedDays: [String]?, onDateTap: ((String) -> Void)? = nil, isCreator: Bool, creatorName: String, buddyName: String?) {
        self.myCompletedDays = myCompletedDays
        self.buddyCompletedDays = buddyCompletedDays
        self.onDateTap = onDateTap
        self.isCreator = isCreator
        self.creatorName = creatorName
        self.buddyName = buddyName
        // Initialize local state with the provided values
        _localMyCompletedDays = State(initialValue: myCompletedDays)
        _localBuddyCompletedDays = State(initialValue: buddyCompletedDays)
    }
    
    // Legacy initializer - also initialize local state
    init(completedDays: [String], onDateTap: ((String) -> Void)? = nil) {
        self.myCompletedDays = completedDays
        self.buddyCompletedDays = nil
        self.onDateTap = onDateTap
        self.isCreator = true
        self.creatorName = "Creator"
        self.buddyName = nil
        _localMyCompletedDays = State(initialValue: completedDays)
        _localBuddyCompletedDays = State(initialValue: nil)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Calendar")
                    .font(.headline)
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { changeMonth(-1) }) {
                        Image(systemName: "chevron.left")
                    }
                    Text(monthYearString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Button(action: { changeMonth(1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            
            // Legend (only show if buddy exists)
            if buddyCompletedDays != nil {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isCreator ? .blue : .red)
                            .frame(width: 8, height: 8)
                        Text(isCreator ? creatorName : (buddyName ?? "Buddy"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isCreator ? .red : .blue)
                            .frame(width: 8, height: 8)
                        Text(isCreator ? (buddyName ?? "Buddy") : creatorName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 4)
            }
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { day in
                    if let day = day {
                        let dayString = dateFormatter.string(from: day)
                        // Use local state if available (for immediate updates), otherwise use props
                        let effectiveMyDays = localMyCompletedDays.isEmpty ? myCompletedDays : localMyCompletedDays
                        let effectiveBuddyDays = localBuddyCompletedDays ?? buddyCompletedDays
                        let isMyCompleted = effectiveMyDays.contains(dayString)
                        let isBuddyCompleted = effectiveBuddyDays?.contains(dayString) ?? false
                        let isToday = calendar.isDateInToday(day)
                        let isCurrentMonth = calendar.isDate(day, equalTo: currentMonth, toGranularity: .month)
                        // Check if date is in the future (after today)
                        let isFutureDate = day > Date()
                        
                        Button(action: {
                            // Only allow action if date is not in the future
                            if !isFutureDate, let onTap = onDateTap {
                                // Call the tap handler first - it will handle the state update
                                // For actions that require confirmation (like past dates in daily tracker),
                                // the handler will return early and we won't update local state
                                onTap(dayString)
                                
                                // Only update local state optimistically if the date is today or future
                                // (for past dates that require confirmation, we wait for actual completion)
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd"
                                if let date = dateFormatter.date(from: dayString) {
                                    let calendar = Calendar.current
                                    let today = calendar.startOfDay(for: Date())
                                    let selectedDate = calendar.startOfDay(for: date)
                                    
                                    // Only do optimistic update for today or future dates
                                    // Past dates require confirmation, so we wait for the actual state update
                                    if selectedDate >= today {
                                        // Update local state immediately for instant visual feedback
                                        if isMyCompleted {
                                            localMyCompletedDays.removeAll { $0 == dayString }
                                        } else {
                                            if localMyCompletedDays.isEmpty {
                                                localMyCompletedDays = myCompletedDays
                                            }
                                            localMyCompletedDays.append(dayString)
                                        }
                                    }
                                }
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.caption)
                                    .foregroundColor(isCurrentMonth ? .primary : .secondary)
                                
                                // Show both checkmarks side by side if both users completed
                                HStack(spacing: 2) {
                                    if isMyCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(isCreator ? .blue : .red)
                                    }
                                    if isBuddyCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(isCreator ? .red : .blue)
                                    }
                                }
                            }
                            .frame(width: 32, height: 32)
                            .background(isToday ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isFutureDate)
                    } else {
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onChange(of: myCompletedDays) { newDays in
            // Sync local state when props update (from server or when popup is cancelled)
            // This ensures the calendar reflects the actual state, not optimistic updates
            localMyCompletedDays = newDays
        }
        .onAppear {
            // Initialize local state when view appears
            localMyCompletedDays = myCompletedDays
        }
        .onChange(of: buddyCompletedDays) { newDays in
            // Sync local state when props update (from server)
            localBuddyCompletedDays = newDays
        }
        .onAppear {
            // Initialize local state on appear
            localMyCompletedDays = myCompletedDays
            localBuddyCompletedDays = buddyCompletedDays
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let startOffset = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: startOffset)
        
        var currentDay = firstDay
        while calendar.isDate(currentDay, equalTo: currentMonth, toGranularity: .month) {
            days.append(currentDay)
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
        }
        
        // Fill remaining days to complete grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func changeMonth(_ direction: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: direction, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

struct StreakCounterVisual: View {
    let currentStreak: Int
    let maxStreak: Int
    
    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.orange)
                Text("Current Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Text("\(maxStreak)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.blue)
                Text("Max Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TotalDaysCountVisual: View {
    let count: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.blue)
            Text(count == 1 ? "Day Completed" : "Days Completed")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BarChartVisual: View {
    let myEntries: [DailyQuantityEntry]
    let buddyEntries: [DailyQuantityEntry]?
    let unit: String
    let timeRange: TimeRange
    let isCreator: Bool // Whether the current viewer is the creator (to determine which entries are creator's vs buddy's)
    let creatorName: String
    let buddyName: String?
    
    @State private var selectedRange: TimeRange = .week
    @State private var currentPeriodOffset: Int = 0 // 0 = current period, -1 = previous, etc.
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // Legacy initializer for backward compatibility
    init(entries: [DailyQuantityEntry], unit: String, timeRange: TimeRange) {
        self.myEntries = entries
        self.buddyEntries = nil
        self.unit = unit
        self.timeRange = timeRange
        self.isCreator = true
        self.creatorName = "Creator"
        self.buddyName = nil
    }
    
    // New initializer with both users' data
    init(myEntries: [DailyQuantityEntry], buddyEntries: [DailyQuantityEntry]?, unit: String, timeRange: TimeRange, isCreator: Bool, creatorName: String, buddyName: String?) {
        self.myEntries = myEntries
        self.buddyEntries = buddyEntries
        self.unit = unit
        self.timeRange = timeRange
        self.isCreator = isCreator
        self.creatorName = creatorName
        self.buddyName = buddyName
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Totals")
                    .font(.headline)
                Spacer()
                Picker("Range", selection: $selectedRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .onChange(of: selectedRange) { _ in
                    // Reset to current period when range changes
                    currentPeriodOffset = 0
                }
            }
            
            // Navigation buttons
            HStack {
                Button(action: { currentPeriodOffset += 1 }) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                }
                Spacer()
                Text(periodLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { 
                    if currentPeriodOffset > getMinOffset() {
                        currentPeriodOffset -= 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .disabled(currentPeriodOffset <= getMinOffset())
            }
            
            #if canImport(Charts)
            if #available(iOS 16.0, *) {
                let yAxisMax = calculateYAxisMax()
                
                // All views use the same format - single chart with y-axis on the right
                if let buddyEntries = buddyEntries {
                    // User legend (only show if buddy exists)
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text(creatorName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text(buddyName ?? "Buddy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Clustered bar chart with both users
                    // Create combined data structure for clustering
                    let combinedData = createCombinedChartData()
                    
                    Chart(combinedData) { dataPoint in
                        BarMark(
                            x: .value("Date", dataPoint.date, unit: chartXAxisUnit),
                            y: .value("Quantity", dataPoint.quantity)
                        )
                        .foregroundStyle(dataPoint.isCreator ? .blue : .red)
                        .position(by: .value("User", dataPoint.isCreator ? "Me" : "Buddy"))
                    }
                    .chartXAxis {
                        AxisMarks(values: chartAxisValues) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            if let dateValue = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(formatChartAxisDate(dateValue))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.secondary.opacity(0.3))
                            AxisValueLabel()
                        }
                    }
                    .chartYScale(domain: 0...yAxisMax)
                    .frame(height: 200)
                } else {
                    // Single user chart
                    Chart(filteredMyEntries) { entry in
                        BarMark(
                            x: .value("Date", entry.date, unit: chartXAxisUnit),
                            y: .value("Quantity", entry.quantity)
                        )
                        .foregroundStyle(.blue)
                    }
                    .chartXAxis {
                        AxisMarks(values: chartAxisValues) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            if let dateValue = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(formatChartAxisDate(dateValue))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.secondary.opacity(0.3))
                            AxisValueLabel()
                        }
                    }
                    .chartYScale(domain: 0...yAxisMax)
                    .frame(height: 200)
                }
            } else {
                // Fallback for iOS < 16
                fallbackBarChart
            }
            #else
            // Fallback if Charts not available
            fallbackBarChart
            #endif
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var fallbackBarChart: some View {
        let combinedEntries = prepareFallbackEntries()
        
        return ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(combinedEntries.enumerated()), id: \.offset) { index, entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatChartAxisDate(entry.date))
                            .font(.caption)
                        HStack(spacing: 4) {
                            if let buddyQty = entry.buddyQty {
                                // Show both bars side by side
                                GeometryReader { geometry in
                                    HStack(spacing: 2) {
                                        Rectangle()
                                            .fill(isCreator ? .blue : .red)
                                            .frame(width: geometry.size.width * 0.48 * CGFloat(entry.myQty / maxQuantity), height: 20)
                                        Rectangle()
                                            .fill(isCreator ? .red : .blue)
                                            .frame(width: geometry.size.width * 0.48 * CGFloat(buddyQty / maxQuantity), height: 20)
                                    }
                                }
                                .frame(height: 20)
                            } else {
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(.blue)
                                        .frame(width: geometry.size.width * CGFloat(entry.myQty / maxQuantity), height: 20)
                                }
                                .frame(height: 20)
                            }
                            Text(String(format: "%.1f", entry.myQty))
                                .font(.caption)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
            .frame(width: max(CGFloat(max(filteredMyEntries.count, filteredBuddyEntries.count)) * chartBarWidth * 2, 300))
        }
        .frame(height: 200)
    }
    
    private func prepareFallbackEntries() -> [(date: Date, myQty: Double, buddyQty: Double?)] {
        var combinedEntries: [(date: Date, myQty: Double, buddyQty: Double?)] = []
        let calendar = Calendar.current
        let allDates = Set(filteredMyEntries.map { calendar.startOfDay(for: $0.date) } + 
                           filteredBuddyEntries.map { calendar.startOfDay(for: $0.date) })
        
        for date in allDates.sorted() {
            let myEntry = filteredMyEntries.first { calendar.startOfDay(for: $0.date) == date }
            let buddyEntry = filteredBuddyEntries.first { calendar.startOfDay(for: $0.date) == date }
            combinedEntries.append((
                date: date,
                myQty: myEntry?.quantity ?? 0,
                buddyQty: buddyEntry?.quantity
            ))
        }
        
        return combinedEntries
    }
    
    private var filteredMyEntries: [DailyQuantityEntry] {
        return filterEntries(myEntries)
    }
    
    private var filteredBuddyEntries: [DailyQuantityEntry] {
        guard let buddyEntries = buddyEntries else { return [] }
        return filterEntries(buddyEntries)
    }
    
    // Combined data structure for clustered bar chart
    private struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let quantity: Double
        let isCreator: Bool // true = creator (blue), false = buddy (red)
    }
    
    private func createCombinedChartData() -> [ChartDataPoint] {
        var dataPoints: [ChartDataPoint] = []
        
        // If current viewer is creator:
        // - myEntries = creator's entries (blue)
        // - buddyEntries = buddy's entries (red)
        // If current viewer is buddy:
        // - myEntries = buddy's entries (red)
        // - buddyEntries = creator's entries (blue)
        
        // Add entries from current viewer
        for entry in filteredMyEntries {
            dataPoints.append(ChartDataPoint(
                date: entry.date,
                quantity: entry.quantity,
                isCreator: isCreator // If viewer is creator, these are creator's entries
            ))
        }
        
        // Add entries from the other user
        for entry in filteredBuddyEntries {
            dataPoints.append(ChartDataPoint(
                date: entry.date,
                quantity: entry.quantity,
                isCreator: !isCreator // If viewer is creator, these are buddy's entries (and vice versa)
            ))
        }
        
        return dataPoints
    }
    
    private func filterEntries(_ entries: [DailyQuantityEntry]) -> [DailyQuantityEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        // Determine the period start and end dates based on selected range and offset
        let (periodStart, periodEnd): (Date, Date) = {
            switch selectedRange {
            case .week:
                // Get start of current week (Sunday)
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
                // Apply offset to get previous weeks
                let offsetWeekStart = calendar.date(byAdding: .weekOfYear, value: -currentPeriodOffset, to: weekStart) ?? weekStart
                let offsetWeekEnd = calendar.date(byAdding: .day, value: 6, to: offsetWeekStart) ?? offsetWeekStart
                return (offsetWeekStart, offsetWeekEnd)
                
            case .month:
                // Get start of current month
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
                // Apply offset to get previous months
                let offsetMonthStart = calendar.date(byAdding: .month, value: -currentPeriodOffset, to: monthStart) ?? monthStart
                // Get end of that month
                let offsetMonthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: offsetMonthStart) ?? offsetMonthStart
                return (offsetMonthStart, offsetMonthEnd)
                
            case .year:
                // Get start of current year
                let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
                // Apply offset to get previous years
                let offsetYearStart = calendar.date(byAdding: .year, value: -currentPeriodOffset, to: yearStart) ?? yearStart
                // Get end of that year
                let offsetYearEnd = calendar.date(from: DateComponents(year: calendar.component(.year, from: offsetYearStart), month: 12, day: 31)) ?? offsetYearStart
                return (offsetYearStart, offsetYearEnd)
            }
        }()
        
        // Get existing entries within the period
        let existingEntries = entries.filter { entry in
            entry.date >= periodStart && entry.date <= periodEnd
        }
        
        // Group entries by day and sum quantities for the same day
        var entriesDict: [Date: DailyQuantityEntry] = [:]
        for entry in existingEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            if let existing = entriesDict[dayStart] {
                // Sum quantities for the same day
                entriesDict[dayStart] = DailyQuantityEntry(
                    id: existing.id,
                    date: dayStart,
                    quantity: existing.quantity + entry.quantity,
                    unit: unit
                )
            } else {
                entriesDict[dayStart] = DailyQuantityEntry(
                    id: entry.id,
                    date: dayStart,
                    quantity: entry.quantity,
                    unit: unit
                )
            }
        }
        
        // Generate all dates in the period and fill in missing ones with 0
        var allEntries: [DailyQuantityEntry] = []
        
        if selectedRange == .year {
            // For year view, aggregate by month
            var monthTotals: [Date: Double] = [:]
            
            // Sum all entries by month
            for entry in entriesDict.values {
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) ?? entry.date
                monthTotals[monthStart, default: 0] += entry.quantity
            }
            
            // Generate all months in the year period
            var currentDate = calendar.startOfDay(for: periodStart)
            while currentDate <= periodEnd {
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
                let total = monthTotals[monthStart] ?? 0
                allEntries.append(DailyQuantityEntry(
                    date: monthStart,
                    quantity: total,
                    unit: unit
                ))
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }
        } else {
            // For week and month views, show daily entries
            var currentDate = calendar.startOfDay(for: periodStart)
            
            while currentDate <= periodEnd {
                if let existingEntry = entriesDict[currentDate] {
                    allEntries.append(existingEntry)
                } else {
                    // Create entry with 0 value for missing dates
                    allEntries.append(DailyQuantityEntry(
                        date: currentDate,
                        quantity: 0,
                        unit: unit
                    ))
                }
                
                // Move to next day
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return allEntries.sorted(by: { $0.date < $1.date })
    }
    
    private var chartXAxisUnit: Calendar.Component {
        switch selectedRange {
        case .week, .month:
            return .day
        case .year:
            return .month
        }
    }
    
    private var chartAxisValues: AxisMarkValues {
        switch selectedRange {
        case .week:
            return .stride(by: .day, count: 1)
        case .month:
            // Show label every 5 days to reduce clutter
            return .stride(by: .day, count: 5)
        case .year:
            return .stride(by: .month, count: 1)
        }
    }
    
    private var chartBarWidth: CGFloat {
        switch selectedRange {
        case .week:
            return 40
        case .month:
            return 20
        case .year:
            return 30
        }
    }
    
    private var periodLabel: String {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedRange {
        case .week:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let offsetWeekStart = calendar.date(byAdding: .weekOfYear, value: -currentPeriodOffset, to: weekStart) ?? weekStart
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            if currentPeriodOffset == 0 {
                return "This Week"
            } else {
                return formatter.string(from: offsetWeekStart)
            }
            
        case .month:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let offsetMonthStart = calendar.date(byAdding: .month, value: -currentPeriodOffset, to: monthStart) ?? monthStart
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            if currentPeriodOffset == 0 {
                return "This Month"
            } else {
                return formatter.string(from: offsetMonthStart)
            }
            
        case .year:
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            let offsetYearStart = calendar.date(byAdding: .year, value: -currentPeriodOffset, to: yearStart) ?? yearStart
            let year = calendar.component(.year, from: offsetYearStart)
            if currentPeriodOffset == 0 {
                return "This Year"
            } else {
                return "\(year)"
            }
        }
    }
    
    private func getMinOffset() -> Int {
        // Calculate minimum offset based on earliest entry date from both users
        let allEntries = myEntries + (buddyEntries ?? [])
        guard let earliestEntry = allEntries.min(by: { $0.date < $1.date }) else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedRange {
        case .week:
            let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let earliestWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: earliestEntry.date)) ?? earliestEntry.date
            let weeksDiff = calendar.dateComponents([.weekOfYear], from: earliestWeekStart, to: currentWeekStart).weekOfYear ?? 0
            return -weeksDiff
            
        case .month:
            let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let earliestMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: earliestEntry.date)) ?? earliestEntry.date
            let monthsDiff = calendar.dateComponents([.month], from: earliestMonthStart, to: currentMonthStart).month ?? 0
            return -monthsDiff
            
        case .year:
            let currentYear = calendar.component(.year, from: now)
            let earliestYear = calendar.component(.year, from: earliestEntry.date)
            return -(currentYear - earliestYear)
        }
    }
    
    private func formatChartAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedRange {
        case .week:
            formatter.dateFormat = "MM/dd"
        case .month:
            formatter.dateFormat = "MM/dd"
        case .year:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
    
    private var maxQuantity: Double {
        let myMax = filteredMyEntries.map { $0.quantity }.max() ?? 0
        let buddyMax = filteredBuddyEntries.map { $0.quantity }.max() ?? 0
        return max(myMax, buddyMax, 1.0)
    }
    
    /// Calculate a clean y-axis maximum value that rounds up to nearest 5 or 10
    private func calculateYAxisMax() -> Double {
        let myMax = filteredMyEntries.map { $0.quantity }.max() ?? 0
        let buddyMax = filteredBuddyEntries.map { $0.quantity }.max() ?? 0
        let maxValue = max(myMax, buddyMax)
        
        // If max is 0, return 10 as a default
        guard maxValue > 0 else { return 10 }
        
        // Round up to nearest clean number
        if maxValue <= 5 {
            return 5
        } else if maxValue <= 10 {
            return 10
        } else if maxValue <= 20 {
            return 20
        } else if maxValue <= 50 {
            return ceil(maxValue / 5) * 5
        } else if maxValue <= 100 {
            return ceil(maxValue / 10) * 10
        } else {
            // For larger values, round to nearest 50 or 100
            let magnitude = pow(10, floor(log10(maxValue)))
            let normalized = maxValue / magnitude
            let rounded = ceil(normalized / 5) * 5
            return rounded * magnitude
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }
    
    private func formatChartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }
}

struct BarTotalsVisual: View {
    let entries: [DailyQuantityEntry]
    let unit: String
    
    private var total: Double {
        entries.reduce(0) { $0 + $1.quantity }
    }
    
    private var average: Double {
        guard !entries.isEmpty else { return 0 }
        return total / Double(entries.count)
    }
    
    private var max: Double {
        entries.map { $0.quantity }.max() ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            StatBox(title: "Total", value: String(format: "%.1f %@", total, unit))
            StatBox(title: "Average", value: String(format: "%.1f %@", average, unit))
            StatBox(title: "Max", value: String(format: "%.1f %@", max, unit))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Models

struct DailyQuantityEntry: Identifiable {
    let id: UUID
    let date: Date
    let quantity: Double
    let unit: String
    
    init(id: UUID = UUID(), date: Date, quantity: Double, unit: String) {
        self.id = id
        self.date = date
        self.quantity = quantity
        self.unit = unit
    }
}

// MARK: - Helper Functions

func calculateStreak(from completedDays: [String]) -> (current: Int, max: Int) {
    guard !completedDays.isEmpty else { return (0, 0) }
    
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    let sortedDates = completedDays.compactMap { dateFormatter.date(from: $0) }.sorted()
    
    var currentStreak = 0
    var maxStreak = 0
    var tempStreak = 1
    
    let today = Date()
    var checkDate = calendar.startOfDay(for: today)
    
    // Calculate current streak (backwards from today)
    for i in 0..<365 { // Check up to a year back
        let dateString = dateFormatter.string(from: checkDate)
        if sortedDates.contains(where: { dateFormatter.string(from: $0) == dateString }) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        } else {
            break
        }
    }
    
    // Calculate max streak
    for i in 1..<sortedDates.count {
        if let prevDate = calendar.date(byAdding: .day, value: -1, to: sortedDates[i]),
           calendar.isDate(prevDate, inSameDayAs: sortedDates[i-1]) {
            tempStreak += 1
        } else {
            maxStreak = max(maxStreak, tempStreak)
            tempStreak = 1
        }
    }
    maxStreak = max(maxStreak, tempStreak)
    
    return (currentStreak, maxStreak)
}

