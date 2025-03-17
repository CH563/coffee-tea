//
//  PopoverContentView.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import SwiftData
import SwiftUI
import AppKit

// 创建一个观察者类来处理通知
class DateUpdateObserver: ObservableObject {
    @Published var lastUpdateTime = Date()
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateDate),
            name: Notification.Name("UpdateCurrentDate"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func updateDate() {
        lastUpdateTime = Date()
    }
}

struct PopoverContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var beverageRecords: [BeverageRecord]
    
    // 使用 StateObject 确保观察者的生命周期与视图一致
    @StateObject private var dateObserver = DateUpdateObserver()
    
    // 使用计算属性获取当前日期
    private var currentDate: Date {
        // 每当 dateObserver.lastUpdateTime 更新时，这个属性会返回新的日期
        return Date()
    }
    
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var customQuantity: Int = 1
    @State private var showingCustomQuantityInput = false
    @State private var showingDateDetail = false
    @State private var detailDate: Date?
    @State private var addedAnimation: Bool = false
    @State private var selectedBeverageType: BeverageType?
    @State private var showingDrinkWarning = false
    @State private var warningType: BeverageType?
    @State private var warningQuantity: Int = 1
    @State private var warningMessage: String = ""

    var isFutureDate: Bool {
        return selectedDate > Date()
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 顶部标题栏 - 更紧凑
                HStack {
                    Text("饮品记录")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: {
                        // 重置为今天
                        selectedDate = Date()
                        currentMonth = Date()
                    }) {
                        Label("今天", systemImage: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)
                
                Divider().padding(.vertical, 0)
                
                // 日历视图 - 更紧凑
                ItsycalStyleCalendarView(
                    currentMonth: $currentMonth,
                    selectedDate: $selectedDate,
                    beverageRecords: beverageRecords,
                    onDateLongPress: { date in
                        detailDate = date
                        showingDateDetail = true
                    }
                )
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                
                Divider().padding(.vertical, 0)
                
                // 日期详情视图 - 更紧凑
                DateDetailView(
                    date: selectedDate, 
                    records: recordsForDate(selectedDate)
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                
                Divider()
                
                // 底部快速添加按钮 - 更紧凑
                HStack(spacing: 16) {
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
                        VStack(spacing: 2) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.brown)
                            Text("咖啡")
                                .font(.system(size: 10))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 60, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.brown.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
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
                        VStack(spacing: 2) {
                            Image(systemName: "mug.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.purple)
                            Text("奶茶")
                                .font(.system(size: 10))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 60, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
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
                .padding(.vertical, 8)
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .frame(width: 280)
            .background(Color(.textBackgroundColor))
            .onChange(of: dateObserver.lastUpdateTime) {
                selectedDate = currentDate
                currentMonth = currentDate
            }
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
            .blur(radius: showingDrinkWarning ? 2 : 0)
            .disabled(showingDrinkWarning)
            
            // 自定义警告视图
            if showingDrinkWarning {
                DrinkWarningView(
                    message: warningMessage,
                    type: warningType ?? .coffee,
                    onDrink: {
                        if let type = warningType {
                            addDrinkRecord(type: type, quantity: warningQuantity)
                        }
                        showingDrinkWarning = false
                    },
                    onCancel: {
                        showingDrinkWarning = false
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func addRecord(type: BeverageType, quantity: Int = 1) {
        // 检查当天饮料数量
        let today = Calendar.current.startOfDay(for: Date())
        
        let todayRecords = beverageRecords.filter { record in
            let recordDate = Calendar.current.startOfDay(for: record.timestamp)
            return recordDate == today
        }
        
        let totalDrinks = todayRecords.reduce(0) { $0 + $1.quantity }
        
        if totalDrinks >= 2 {
            // 已经喝了2杯或更多，显示提示
            showDrinkWarning(type: type, quantity: quantity)
        } else {
            // 直接添加记录
            addDrinkRecord(type: type, quantity: quantity)
        }
    }

    private func showDrinkWarning(type: BeverageType, quantity: Int) {
        // 随机选择一条诙谐提示语
        let warningMessages = [
            "今天的咖啡因已经超标啦！饮料好喝莫贪杯，不如来杯清水润润肺？",
            "又来一杯？您的肾脏正在抗议：'主人，我已经很努力了！'",
            "多喝热水，少喝甜饮，医生微笑，肾脏感谢！",
            "今日糖分摄入已达小熊维尼级别，确定要继续吗？",
            "您的身体正在组织一场名为'抗糖联盟'的集会，要不要考虑喝杯水？"
        ]
        
        let randomIndex = Int.random(in: 0..<warningMessages.count)
        warningMessage = warningMessages[randomIndex]
        warningType = type
        warningQuantity = quantity
        
        withAnimation(.spring(response: 0.3)) {
            showingDrinkWarning = true
        }
    }

    private func addDrinkRecord(type: BeverageType, quantity: Int) {
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

// 自定义警告视图
struct DrinkWarningView: View {
    let message: String
    let type: BeverageType
    let onDrink: () -> Void
    let onCancel: () -> Void
    
    var beverageEmoji: String {
        return type == .coffee ? "☕️" : "🧋"
    }
    
    var beverageColor: Color {
        return type == .coffee ? .brown : .purple
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 图标
            Image(systemName: "drop.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            // 警告消息
            Text(message)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // 按钮
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    HStack {
                        Image(systemName: "drop")
                        Text("喝水去 💧")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                
                Button(action: onDrink) {
                    HStack {
                        Text("就要喝 \(beverageEmoji)")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(beverageColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 240)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
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
    private let rowHeight: CGFloat = 28 // 减小行高

    var body: some View {
        VStack(spacing: 4) { // 减小间距
            // 月份导航 - 更紧凑
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(canMoveToNextMonth() ? .blue : .gray)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(4)
                        .background(canMoveToNextMonth() ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(!canMoveToNextMonth())
            }
            .padding(.horizontal, 6)

            // 星期标题 - 更紧凑
            HStack(spacing: 0) {
                ForEach(getAdjustedWeekdaySymbols(), id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10))
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 2)

            // 日期网格 - 更紧凑
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
    private let cellSize: CGFloat = 22 // 减小单元格尺寸
    private var isFutureDate: Bool {
        return date > Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            // 日期数字 - 更紧凑
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 12))
                .fontWeight(isToday || isSelected ? .bold : .regular)
                .foregroundColor(textColor)
                .frame(width: cellSize, height: cellSize)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .opacity(isSelected || isToday ? 1 : 0)
                )
            
            // 饮品指示器 - 彩色圆点
            if records.count > 0 && !isFutureDate {
                HStack(spacing: 3) {
                    // 检查是否有咖啡
                    if records.contains(where: { $0.beverageType == .coffee }) {
                        Circle()
                            .fill(Color.brown)
                            .frame(width: 4, height: 4)
                    }
                    
                    // 检查是否有奶茶
                    if records.contains(where: { $0.beverageType == .tea }) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.top, 1)
            } else {
                Spacer()
                    .frame(height: 5) // 保持一致的高度
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
        VStack(alignment: .leading, spacing: 6) { // 减小间距
            // 标题显示 - 更紧凑
            HStack {
                Text(dateString(from: date))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !records.isEmpty {
                    Text("\(records.count) 杯")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            if records.isEmpty {
                HStack {
                    Spacer()
                    Text("今日暂无记录")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    Spacer()
                }
            } else {
                // 记录列表 - 更紧凑
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(records.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { record in
                            VStack(spacing: 2) {
                                Text(record.emoji)
                                    .font(.system(size: 20))
                                
                                if record.quantity > 1 {
                                    Text("x\(record.quantity)")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(timeString(from: record.timestamp))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(record.beverageType == .coffee ? 
                                          Color.brown.opacity(0.1) : 
                                          Color.purple.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
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
                    .padding(.vertical, 2)
                }
                .frame(height: 50) // 固定高度，更紧凑
            }
        }
        .padding(.vertical, 4)
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
        formatter.dateFormat = "MM/dd"  // 更紧凑的日期格式
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
        VStack(spacing: 16) { // 减小间距
            Text("\(beverageEmoji) 添加\(beverageName)")
                .font(.system(size: 14, weight: .medium))
                .padding(.top, 16)

            Text("请选择数量")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: {
                    if quantity > 1 {
                        quantity -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(quantity > 1 ? beverageColor : .gray)
                }
                
                Text("\(quantity)")
                    .font(.system(size: 30, weight: .bold))
                    .frame(width: 50)
                
                Button(action: {
                    if quantity < 10 {
                        quantity += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(quantity < 10 ? beverageColor : .gray)
                }
            }
            .padding(.vertical, 8)
            
            HStack(spacing: 16) {
                Button("取消") {
                    onCancel()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                Button("添加") {
                    onSave()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(beverageColor)
                .cornerRadius(8)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 220) // 减小宽度
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}
