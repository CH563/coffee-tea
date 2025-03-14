//
//  PopoverContentView.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import SwiftData
import SwiftUI
import AppKit

struct PopoverContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var beverageRecords: [BeverageRecord]

    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var customQuantity: Int = 1
    @State private var showingCustomQuantityInput = false
    @State private var showingDateDetail = false
    @State private var detailDate: Date?
    @State private var addedAnimation: Bool = false
    @State private var selectedBeverageType: BeverageType?

    var isFutureDate: Bool {
        return selectedDate > Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("饮品记录")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    // 重置为今天
                    selectedDate = Date()
                    currentMonth = Date()
                }) {
                    Label("今天", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Divider().padding(.vertical, 8)
            
            // 日历视图
            ItsycalStyleCalendarView(
                currentMonth: $currentMonth,
                selectedDate: $selectedDate,
                beverageRecords: beverageRecords,
                onDateLongPress: { date in
                    detailDate = date
                    showingDateDetail = true
                }
            )
            .padding(.horizontal, 8)
            
            Divider().padding(.vertical, 8)
            
            // 日期详情视图
            DateDetailView(
                date: selectedDate, 
                records: recordsForDate(selectedDate)
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            
            Divider()
            
            // 底部快速添加按钮
            HStack(spacing: 20) {
                Spacer()
                
                Button(action: { 
                    withAnimation {
                        selectedBeverageType = .coffee
                        addedAnimation = true
                    }
                    addRecord(type: .coffee)
                    
                    // 重置动画状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            addedAnimation = false
                        }
                    }
                }) {
                    VStack {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.brown)
                        Text("咖啡")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 70, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.brown.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brown.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .scaleEffect(selectedBeverageType == .coffee && addedAnimation ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .disabled(isFutureDate)
                .opacity(isFutureDate ? 0.5 : 1.0)
                .onLongPressGesture {
                    if !isFutureDate {
                        selectedBeverageType = .coffee
                        showingCustomQuantityInput = true
                    }
                }

                Button(action: { 
                    withAnimation {
                        selectedBeverageType = .tea
                        addedAnimation = true
                    }
                    addRecord(type: .tea)
                    
                    // 重置动画状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            addedAnimation = false
                        }
                    }
                }) {
                    VStack {
                        Image(systemName: "mug.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                        Text("奶茶")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 70, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .scaleEffect(selectedBeverageType == .tea && addedAnimation ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .disabled(isFutureDate)
                .opacity(isFutureDate ? 0.5 : 1.0)
                .onLongPressGesture {
                    if !isFutureDate {
                        selectedBeverageType = .tea
                        showingCustomQuantityInput = true
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 320)
        .background(Color(.textBackgroundColor))
        .sheet(isPresented: $showingCustomQuantityInput) {
            CustomQuantityView(
                quantity: $customQuantity,
                beverageType: selectedBeverageType ?? .coffee,
                onSave: {
                    if let type = selectedBeverageType {
                        addRecord(type: type, quantity: customQuantity)
                    }
                    showingCustomQuantityInput = false
                    customQuantity = 1
                },
                onCancel: {
                    showingCustomQuantityInput = false
                    customQuantity = 1
                }
            )
        }
        .sheet(isPresented: $showingDateDetail) {
            if let date = detailDate {
                DateDetailView(date: date, records: recordsForDate(date))
                    .presentationDetents([.medium])
            }
        }
        .animation(.spring(response: 0.3), value: selectedDate)
    }

    private func addRecord(type: BeverageType, quantity: Int = 1) {
        let newRecord = BeverageRecord(timestamp: selectedDate, type: type, quantity: quantity)
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
    private let rowHeight: CGFloat = 32

    var body: some View {
        VStack(spacing: 8) {
            // 月份导航
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                Text(monthYearString(from: currentMonth))
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(canMoveToNextMonth() ? .blue : .gray)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(6)
                        .background(canMoveToNextMonth() ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(!canMoveToNextMonth())
            }
            .padding(.horizontal, 8)

            // 星期标题
            HStack(spacing: 0) {
                ForEach(getAdjustedWeekdaySymbols(), id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)

            // 日期网格
            VStack(spacing: 4) {
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
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedDate = date
                                        }
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

    private func canMoveToNextMonth() -> Bool {
        let currentDate = Date()
        let currentMonthValue = calendar.component(.month, from: currentDate)
        let currentYearValue = calendar.component(.year, from: currentDate)
        
        let displayedMonthValue = calendar.component(.month, from: self.currentMonth)
        let displayedYearValue = calendar.component(.year, from: self.currentMonth)
        
        // 如果显示的年份大于当前年份，或者年份相同但月份大于等于当前月份，则不能前进
        return !(displayedYearValue > currentYearValue || (displayedYearValue == currentYearValue && displayedMonthValue >= currentMonthValue))
    }

    // 获取指定日期的记录
    private func recordsForDate(_ date: Date) -> [BeverageRecord] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return beverageRecords.filter { record in
            record.timestamp >= startOfDay && record.timestamp < endOfDay
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
    private let cellSize: CGFloat = 24
    private var isFutureDate: Bool {
        return date > Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            // 日期数字
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14))
                .fontWeight(isToday || isSelected ? .bold : .regular)
                .foregroundColor(textColor)
                .frame(width: cellSize, height: cellSize)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .opacity(isSelected || isToday ? 1 : 0)
                )
            
            // 饮品指示器 - 改为彩色圆点
            if records.count > 0 && !isFutureDate {
                HStack(spacing: 4) {
                    // 检查是否有咖啡
                    if records.contains(where: { $0.beverageType == .coffee }) {
                        Circle()
                            .fill(Color.brown)
                            .frame(width: 5, height: 5)
                    }
                    
                    // 检查是否有奶茶
                    if records.contains(where: { $0.beverageType == .tea }) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.top, 2)
            } else {
                Spacer()
                    .frame(height: 7) // 保持一致的高度
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .opacity(isFutureDate ? 0.4 : 1.0)
        .onTapGesture {
            if !isFutureDate {
                onTap()
            }
        }
        .onLongPressGesture {
            if !isFutureDate {
                onLongPress()
            }
        }
    }

    private var textColor: Color {
        if isFutureDate {
            return .gray
        } else if isSelected {
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
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirmation = false
    @State private var recordToDelete: BeverageRecord?
    @State private var deleteScale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题显示
            HStack {
                Text(dateString(from: date))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !records.isEmpty {
                    Text("\(records.count) 杯")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            if records.isEmpty {
                HStack {
                    Spacer()
                    Text("今日暂无记录")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                // 记录列表
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(records.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { record in
                            VStack(spacing: 4) {
                                Text(record.emoji)
                                    .font(.system(size: 24))
                                
                                if record.quantity > 1 {
                                    Text("x\(record.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(timeString(from: record.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(record.beverageType == .coffee ? 
                                          Color.brown.opacity(0.1) : 
                                          Color.purple.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(record.beverageType == .coffee ? 
                                                   Color.brown.opacity(0.3) : 
                                                   Color.purple.opacity(0.3), 
                                                   lineWidth: 1)
                                    )
                            )
                            .scaleEffect(recordToDelete?.id == record.id ? deleteScale : 1.0)
                            .onTapGesture {
                                recordToDelete = record
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical, 8)
        .confirmationDialog("确定要删除这条记录吗？", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                if let record = recordToDelete {
                    withAnimation(.spring(response: 0.3)) {
                        deleteScale = 0.5
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            deleteRecord(record)
                            deleteScale = 1.0
                        }
                    }
                }
            }
            Button("取消", role: .cancel) {}
        }
    }
    
    private func deleteRecord(_ record: BeverageRecord) {
        modelContext.delete(record)
        NotificationCenter.default.post(
            name: Notification.Name("DrinkRemoved"), object: nil)
    }

    private func dateString(from date: Date) -> String {
        let weekday = weekdayString(from: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        let dateStr = formatter.string(from: date)
        return "\(dateStr) \(weekday)"
    }

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

struct CustomQuantityView: View {
    @Binding var quantity: Int
    let beverageType: BeverageType
    var onSave: () -> Void
    var onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var beverageEmoji: String {
        return beverageType == .coffee ? "☕️" : "🧋"
    }
    
    var beverageName: String {
        return beverageType == .coffee ? "咖啡" : "奶茶"
    }
    
    var beverageColor: Color {
        return beverageType == .coffee ? .brown : .purple
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("\(beverageEmoji) 添加\(beverageName)")
                .font(.headline)
                .padding(.top, 20)

            Text("请选择数量")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: {
                    if quantity > 1 {
                        quantity -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(quantity > 1 ? beverageColor : .gray)
                }
                
                Text("\(quantity)")
                    .font(.system(size: 36, weight: .bold))
                    .frame(width: 60)
                
                Button(action: {
                    if quantity < 10 {
                        quantity += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(quantity < 10 ? beverageColor : .gray)
                }
            }
            .padding()
            
            HStack(spacing: 20) {
                Button("取消") {
                    onCancel()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                
                Button("添加") {
                    onSave()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(beverageColor)
                .cornerRadius(10)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 250)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}
