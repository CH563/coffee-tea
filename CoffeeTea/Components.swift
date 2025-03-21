import SwiftUI
import SwiftData
import AppKit
import Foundation

// MARK: - 日期更新观察者
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

// MARK: - 饮料警告视图
struct DrinkWarningView: View {
    let message: String
    let type: BeverageType
    let onDrink: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack{
                // 图标
                Text("💧")
                    .font(.system(size: 24))
                    .padding(.top, 20)
                
                // 警告消息
                Text(message)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // 按钮
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    HStack {
                        Text("喝水去 💧")
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .cornerRadius(8)
                }
                
                Button(action: onDrink) {
                    HStack {
                        Text("就要喝" + type.emoji)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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

// MARK: - 日期详情视图
struct DateDetailView: View {
    let date: Date
    let records: [BeverageRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirmation = false
    @State private var recordToDelete: BeverageRecord?
    @State private var deleteScale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 标题显示
            HStack {
                Text(date.formattedDateString())
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
                // 记录列表
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
                                
                                Text(record.timestamp.timeString())
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(record.beverageType.themeColor.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(record.beverageType.themeColor.opacity(0.3), lineWidth: 1)
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
                .frame(height: 50)
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
            name: Notification.Name("DrinkRemoved"),
            object: nil)
    }
}

// MARK: - 自定义数量输入视图
struct CustomQuantityView: View {
    @Binding var quantity: Int
    let beverageType: BeverageType
    var onSave: () -> Void
    var onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("\(beverageType.emoji) 添加\(beverageType.displayName)")
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
                        .foregroundColor(quantity > 1 ? beverageType.themeColor : .gray)
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
                        .foregroundColor(quantity < 10 ? beverageType.themeColor : .gray)
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
                .background(beverageType.themeColor)
                .cornerRadius(8)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 220)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}

// MARK: - 日历视图
struct ItsycalStyleCalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    var beverageRecords: [BeverageRecord]
    var onDateLongPress: (Date) -> Void

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols
    private let daysInWeek = 7
    private let rowHeight: CGFloat = 28

    var body: some View {
        VStack(spacing: 4) {
            // 月份导航
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

                Text(currentMonth.monthYearString())
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

            // 星期标题
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

            // 日期网格
            VStack(spacing: 2) {
                ForEach(monthDays(), id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.self) { day in
                            if let date = day {
                                DateCell(
                                    date: date,
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
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
                                    .frame(maxWidth: .infinity, maxHeight: rowHeight)
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

    // 获取当前月的所有日期，按周分组
    private func monthDays() -> [[Date?]] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDay = calendar.date(
            from: calendar.dateComponents([.year, .month], from: currentMonth))!

        // 计算第一天是星期几
        var firstWeekday = calendar.component(.weekday, from: firstDay) - calendar.firstWeekday
        if firstWeekday < 0 {
            firstWeekday += 7
        }

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        // 补全最后一周
        let remainingCells = (daysInWeek - (days.count % daysInWeek)) % daysInWeek
        days.append(contentsOf: Array(repeating: nil, count: remainingCells))

        // 按周分组
        return stride(from: 0, to: days.count, by: daysInWeek).map {
            Array(days[$0..<min($0 + daysInWeek, days.count)])
        }
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }

    private func canMoveToNextMonth() -> Bool {
        let currentDate = Date()
        let currentMonthValue = calendar.component(.month, from: currentDate)
        let currentYearValue = calendar.component(.year, from: currentDate)
        
        let displayedMonthValue = calendar.component(.month, from: self.currentMonth)
        let displayedYearValue = calendar.component(.year, from: self.currentMonth)
        
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

// MARK: - 日期单元格
struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let records: [BeverageRecord]
    let onTap: () -> Void
    let onLongPress: () -> Void

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 22
    private var isFutureDate: Bool {
        return date > Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            // 日期数字
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
            
            // 饮品指示器
            if records.count > 0 && !isFutureDate {
                HStack(spacing: 3) {
                    // 咖啡指示器
                    if records.contains(where: { $0.beverageType == .coffee }) {
                        Circle()
                            .fill(Color.brown)
                            .frame(width: 4, height: 4)
                    }
                    
                    // 奶茶指示器
                    if records.contains(where: { $0.beverageType == .tea }) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 4, height: 4)
                    }

                    // 柠檬茶指示器
                    if records.contains(where: { $0.beverageType == .lemonTea }) {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.top, 1)
            } else {
                Spacer()
                    .frame(height: 5)
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

// MARK: - Date扩展
extension Date {
    func formattedDateString() -> String {
        let weekday = weekdayString()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let dateStr = formatter.string(from: self)
        return "\(dateStr) \(weekday)"
    }
    
    func weekdayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
    
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}

// MARK: - 通知名称
extension Notification.Name {
    static let drinkAdded = Notification.Name("DrinkAdded")
    static let drinkRemoved = Notification.Name("DrinkRemoved")
    static let updateCurrentDate = Notification.Name("UpdateCurrentDate")
} 
