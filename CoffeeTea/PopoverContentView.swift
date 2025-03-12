//
//  PopoverContentView.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import SwiftData
import SwiftUI

struct PopoverContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var beverageRecords: [BeverageRecord]

    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var customQuantity: Int = 1
    @State private var showingCustomQuantityInput = false
    @State private var showingDateDetail = false
    @State private var detailDate: Date?

    var body: some View {
        VStack(spacing: 0) {
            // 快速记录按钮
            HStack(spacing: 20) {
                Button(action: { addRecord(type: .coffee) }) {
                    VStack {
                        Text("☕️").font(.system(size: 24))
                        // Text("咖啡").font(.caption)
                    }
                    .frame(width: 60, height: 60)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .onLongPressGesture {
                    showingCustomQuantityInput = true
                }

                Button(action: { addRecord(type: .tea) }) {
                    VStack {
                        Text("🧋").font(.system(size: 24))
                        // Text("奶茶").font(.caption)
                    }
                    .frame(width: 60, height: 60)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .onLongPressGesture {
                    showingCustomQuantityInput = true
                }
            }
            .padding(.top, 10)

            Divider().padding(.vertical, 10)

            // 日历视图 - Itsycal 风格
            ItsycalStyleCalendarView(
                currentMonth: $currentMonth,
                selectedDate: $selectedDate,
                beverageRecords: beverageRecords,
                onDateLongPress: { date in
                    detailDate = date
                    showingDateDetail = true
                }
            )
            .padding(.top, 5)

            Divider().padding(.vertical, 10)

            DateDetailView(
                date: selectedDate, records: recordsForDate(selectedDate))
        }
        .frame(width: 300)
        .sheet(isPresented: $showingCustomQuantityInput) {
            CustomQuantityView(
                quantity: $customQuantity,
                onSave: {
                    showingCustomQuantityInput = false
                })
        }
        .sheet(isPresented: $showingDateDetail) {
            if let date = detailDate {
                DateDetailView(date: date, records: recordsForDate(date))
            }
        }
    }

    private func addRecord(type: BeverageType) {
        let newRecord = BeverageRecord(timestamp: selectedDate, type: type)
        modelContext.insert(newRecord)

        NotificationCenter.default.post(
            name: Notification.Name("DrinkAdded"), object: nil)
    }

    private func recordsForDate(_ date: Date) -> [BeverageRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return beverageRecords.filter { record in
            record.timestamp >= startOfDay && record.timestamp < endOfDay
        }
    }
}

struct ItsycalStyleCalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    var beverageRecords: [BeverageRecord]
    var onDateLongPress: (Date) -> Void

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols
    private let daysInWeek = 7
    private let rowHeight: CGFloat = 30

    var body: some View {
        VStack(spacing: 8) {
            // 月份导航
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(monthYearString(from: currentMonth))
                    .font(.headline)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)

            // 星期标题
            HStack(spacing: 0) {
                ForEach(getAdjustedWeekdaySymbols(), id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }

            // 日期网格
            VStack(spacing: 2) {
                ForEach(monthDays(), id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.self) { day in
                            if let date = day {
                                DateCell(
                                    date: date,
                                    isSelected: calendar.isDate(
                                        date, inSameDayAs: selectedDate),
                                    isToday: calendar.isDateInToday(date),
                                    records: recordsForDate(date),
                                    onTap: {
                                        selectedDate = date
                                    },
                                    onLongPress: {
                                        onDateLongPress(date)
                                    }
                                )
                            } else {
                                // 空白单元格
                                Color.clear
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: rowHeight)
                            }
                        }
                    }
                }
            }
        }
    }

    // 获取调整后的星期符号（从周一开始）
    private func getAdjustedWeekdaySymbols() -> [String] {
        let firstWeekday = calendar.firstWeekday
        var symbols = weekdaySymbols

        if firstWeekday > 1 {
            let symbolsToMove = symbols.prefix(firstWeekday - 1)
            symbols.removeFirst(firstWeekday - 1)
            symbols.append(contentsOf: symbolsToMove)
        }

        return symbols
    }

    // 获取月份和年份字符串
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // 获取当前月的所有日期，按周分组
    private func monthDays() -> [[Date?]] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDay = calendar.date(
            from: calendar.dateComponents([.year, .month], from: currentMonth))!

        // 计算第一天是星期几
        var firstWeekday =
            calendar.component(.weekday, from: firstDay) - calendar.firstWeekday
        if firstWeekday < 0 {
            firstWeekday += 7
        }

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in 1...range.count {
            if let date = calendar.date(
                byAdding: .day, value: day - 1, to: firstDay)
            {
                days.append(date)
            }
        }

        // 补全最后一周
        let remainingCells =
            (daysInWeek - (days.count % daysInWeek)) % daysInWeek
        days.append(contentsOf: Array(repeating: nil, count: remainingCells))

        // 按周分组
        return stride(from: 0, to: days.count, by: daysInWeek).map {
            Array(days[$0..<min($0 + daysInWeek, days.count)])
        }
    }

    // 获取指定日期的记录
    private func recordsForDate(_ date: Date) -> [BeverageRecord] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return beverageRecords.filter { record in
            record.timestamp >= startOfDay && record.timestamp < endOfDay
        }
    }

    private func previousMonth() {
        if let newDate = calendar.date(
            byAdding: .month, value: -1, to: currentMonth)
        {
            currentMonth = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(
            byAdding: .month, value: 1, to: currentMonth)
        {
            currentMonth = newDate
        }
    }
}

struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let records: [BeverageRecord]
    let onTap: () -> Void
    let onLongPress: () -> Void

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 28

    var body: some View {
        VStack(spacing: 2) {
            // 日期数字
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 12))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(textColor)
                .frame(width: cellSize, height: cellSize)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .opacity(isSelected || isToday ? 1 : 0)
                )

            // 饮品指示器
            HStack(spacing: 2) {
                if records.count > 0 {
                    if records.count > 2 {
                        Text(records[0].emoji)
                            .font(.system(size: 12))
                        Text("+\(records.count - 1)")
                            .font(.system(size: 6))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(0..<min(records.count, 2), id: \.self) {
                            index in
                            Text(records[index].emoji)
                                .font(.system(size: 12))
                        }
                    }
                } else {
                    Text("")
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .white
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .gray
        } else {
            return .clear
        }
    }
}

struct DateDetailView: View {
    let date: Date
    let records: [BeverageRecord]

    // 每行最多显示的记录数
    private let maxDisplayCount = 8

    var body: some View {
        VStack(spacing: 10) {
            // 修改标题显示：周几 + 咖啡数量 + 奶茶数量
            Text(simplifiedSummary)
                .font(.headline)
                .padding(.bottom, 5)

            if records.isEmpty {
                Text("没有记录")
                    .foregroundColor(.secondary)
            } else {
                // 横向排列记录
                HStack(spacing: 8) {
                    ForEach(0..<min(records.count, maxDisplayCount), id: \.self)
                    { index in
                        let record = records.sorted(by: {
                            $0.timestamp < $1.timestamp
                        })[index]

                        // 使用 tooltip 显示时间
                        Text(
                            record.emoji
                                + (record.quantity > 1
                                    ? " x\(record.quantity)" : "")
                        )
                        .font(.system(size: 16))
                        .help(timeString(from: record.timestamp))
                    }

                    // 显示剩余数量
                    if records.count > maxDisplayCount {
                        Text("+\(records.count - maxDisplayCount)")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                }
                .padding(.vertical, 5)
            }

            Spacer()
        }
        .padding(.top, 0)
    }

    // 简化的摘要信息：周几 + 咖啡数量 + 奶茶数量
    private var simplifiedSummary: String {
        let weekday = weekdayString(from: date)

        let coffeeCount = records.filter { $0.beverageType == .coffee }
            .reduce(0) { $0 + $1.quantity }

        let teaCount = records.filter { $0.beverageType == .tea }
            .reduce(0) { $0 + $1.quantity }

        var summary = weekday

        if coffeeCount > 0 {
            summary += "，咖啡\(coffeeCount)杯"
        }

        if teaCount > 0 {
            summary += "，奶茶\(teaCount)杯"
        }

        return summary
    }

    // 获取周几字符串
    private func weekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"  // 完整的星期名称
        formatter.locale = Locale(identifier: "zh_CN")  // 使用中文
        return formatter.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// 添加 CustomQuantityView 定义
struct CustomQuantityView: View {
    @Binding var quantity: Int
    var onSave: () -> Void

    var body: some View {
        VStack {
            Text("输入数量").font(.headline)

            Stepper("\(quantity) 杯", value: $quantity, in: 1...10)
                .padding()

            Button("保存") {
                onSave()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 200, height: 150)
    }
}
