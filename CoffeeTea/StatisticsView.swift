import SwiftUI
import SwiftData
import Charts

// 统计数据模型
struct DrinkStats: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let coffeeCount: Int
    let teaCount: Int
    let lemonTeaCount: Int
    let bottledCount: Int
    
    var totalCount: Int {
        return coffeeCount + teaCount + lemonTeaCount + bottledCount
    }
    
    // 为了实现Equatable协议，需要实现相等性比较
    static func == (lhs: DrinkStats, rhs: DrinkStats) -> Bool {
        return lhs.date == rhs.date &&
               lhs.coffeeCount == rhs.coffeeCount &&
               lhs.teaCount == rhs.teaCount &&
               lhs.lemonTeaCount == rhs.lemonTeaCount &&
               lhs.bottledCount == rhs.bottledCount
    }
}

// 统计时间范围枚举
enum StatsPeriod: String, CaseIterable, Identifiable {
    case day = "日视图"
    case week = "周视图"
    case month = "月视图"
    
    var id: String { self.rawValue }
}

// 饮料类型统计项
struct BeverageStatItem: Identifiable {
    let id = UUID()
    let type: BeverageType
    let count: Int
    
    var color: Color {
        type.themeColor
    }
}

// 饮料统计视图
struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var beverageRecords: [BeverageRecord]
    
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var currentDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // 时间范围选择器
            Picker("统计周期", selection: $selectedPeriod) {
                ForEach(StatsPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 12)
            .animation(.easeInOut, value: selectedPeriod)
            
            // 时间导航
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        moveToPrevious()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.windowBackgroundColor).opacity(0.8))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text(periodTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .animation(.easeInOut, value: periodTitle)
                    .frame(minWidth: 150)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            moveToNext()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.windowBackgroundColor).opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentDate = Date()
                        }
                    }) {
                        Text("今天")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            
            // 图表视图
            VStack(spacing: 16) {
                // 总饮料统计
                if !beverageStatItems.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(beverageStatItems) { item in
                            VStack(spacing: 6) {
                                Text(item.type.emoji)
                                    .font(.system(size: 22))
                                Text("\(item.count)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(item.type.themeColor)
                            }
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.windowBackgroundColor))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.top, 8)
                }
                
                // 图表
                VStack(spacing: 10) {
                    if statsData.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "cup.and.saucer")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("暂无数据")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.windowBackgroundColor))
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    } else {
                        Chart {
                            ForEach(statsData) { stat in
                                if stat.coffeeCount > 0 {
                                    BarMark(
                                        x: .value("日期", displayDateForStat(stat)),
                                        y: .value("咖啡", stat.coffeeCount)
                                    )
                                    .foregroundStyle(BeverageType.coffee.themeColor)
                                    .position(by: .value("类型", "咖啡"))
                                    .cornerRadius(4)
                                }
                                
                                if stat.teaCount > 0 {
                                    BarMark(
                                        x: .value("日期", displayDateForStat(stat)),
                                        y: .value("奶茶", stat.teaCount)
                                    )
                                    .foregroundStyle(BeverageType.tea.themeColor)
                                    .position(by: .value("类型", "奶茶"))
                                    .cornerRadius(4)
                                }
                                
                                if stat.lemonTeaCount > 0 {
                                    BarMark(
                                        x: .value("日期", displayDateForStat(stat)),
                                        y: .value("柠檬茶", stat.lemonTeaCount)
                                    )
                                    .foregroundStyle(BeverageType.lemonTea.themeColor)
                                    .position(by: .value("类型", "柠檬茶"))
                                    .cornerRadius(4)
                                }
                                
                                if stat.bottledCount > 0 {
                                    BarMark(
                                        x: .value("日期", displayDateForStat(stat)),
                                        y: .value("三得利", stat.bottledCount)
                                    )
                                    .foregroundStyle(BeverageType.bottled.themeColor)
                                    .position(by: .value("类型", "三得利"))
                                    .cornerRadius(4)
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(preset: .aligned) { value in
                                AxisValueLabel {
                                    if let dateString = value.as(String.self) {
                                        Text(dateString)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text("\(intValue)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                        .chartLegend(position: .bottom, spacing: 12) {
                            HStack {
                                ForEach([BeverageType.coffee, BeverageType.tea, BeverageType.lemonTea, BeverageType.bottled], id: \.self) { type in
                                    Circle()
                                        .fill(type.themeColor)
                                        .frame(width: 8, height: 8)
                                    Text(type.displayName)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    
                                    if type != .bottled {
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .frame(height: 280)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.windowBackgroundColor))
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        .animation(.easeInOut, value: statsData)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.vertical)
        .frame(width: 500, height: 500)
        .background(Color(.windowBackgroundColor))
    }
    
    // 获取统计数据
    var statsData: [DrinkStats] {
        switch selectedPeriod {
        case .day:
            return getDayStats()
        case .week:
            return getWeekStats()
        case .month:
            return getMonthStats()
        }
    }
    
    // 获取每种饮料的总数
    var beverageStatItems: [BeverageStatItem] {
        let coffeeTotal = statsData.reduce(0) { $0 + $1.coffeeCount }
        let teaTotal = statsData.reduce(0) { $0 + $1.teaCount }
        let lemonTeaTotal = statsData.reduce(0) { $0 + $1.lemonTeaCount }
        let bottledTotal = statsData.reduce(0) { $0 + $1.bottledCount }
        
        var items: [BeverageStatItem] = []
        
        if coffeeTotal > 0 {
            items.append(BeverageStatItem(type: .coffee, count: coffeeTotal))
        }
        if teaTotal > 0 {
            items.append(BeverageStatItem(type: .tea, count: teaTotal))
        }
        if lemonTeaTotal > 0 {
            items.append(BeverageStatItem(type: .lemonTea, count: lemonTeaTotal))
        }
        if bottledTotal > 0 {
            items.append(BeverageStatItem(type: .bottled, count: bottledTotal))
        }
        
        return items
    }
    
    // 周期标题
    var periodTitle: String {
        let formatter = DateFormatter()
        
        switch selectedPeriod {
        case .day:
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: currentDate)
        case .week:
            let calendar = Calendar.current
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            
            let startFormatter = DateFormatter()
            let endFormatter = DateFormatter()
            
            if calendar.component(.month, from: weekStart) == calendar.component(.month, from: weekEnd) {
                startFormatter.dateFormat = "MM月dd日"
                endFormatter.dateFormat = "dd日"
            } else {
                startFormatter.dateFormat = "MM月dd日"
                endFormatter.dateFormat = "MM月dd日"
            }
            
            return "\(startFormatter.string(from: weekStart)) - \(endFormatter.string(from: weekEnd))"
        case .month:
            formatter.dateFormat = "yyyy年MM月"
            return formatter.string(from: currentDate)
        }
    }
    
    // 用于图表显示的日期格式
    func displayDateForStat(_ stat: DrinkStats) -> String {
        let formatter = DateFormatter()
        
        switch selectedPeriod {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week:
            formatter.dateFormat = "E"
            formatter.locale = Locale(identifier: "zh_CN")
        case .month:
            formatter.dateFormat = "dd"
        }
        
        return formatter.string(from: stat.date)
    }
    
    // 获取日统计
    func getDayStats() -> [DrinkStats] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: currentDate)
        _ = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        // 创建24小时的数据点
        var hourlyStats: [DrinkStats] = []
        
        for hour in 0..<24 {
            let hourDate = calendar.date(byAdding: .hour, value: hour, to: dayStart)!
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: hourDate)!
            
            let hourRecords = beverageRecords.filter { record in
                record.timestamp >= hourDate && record.timestamp < nextHour
            }
            
            let coffeeCount = hourRecords.filter { $0.beverageType == .coffee }.reduce(0) { $0 + $1.quantity }
            let teaCount = hourRecords.filter { $0.beverageType == .tea }.reduce(0) { $0 + $1.quantity }
            let lemonTeaCount = hourRecords.filter { $0.beverageType == .lemonTea }.reduce(0) { $0 + $1.quantity }
            let bottledCount = hourRecords.filter { $0.beverageType == .bottled }.reduce(0) { $0 + $1.quantity }
            
            if coffeeCount > 0 || teaCount > 0 || lemonTeaCount > 0 || bottledCount > 0 {
                hourlyStats.append(DrinkStats(
                    date: hourDate,
                    coffeeCount: coffeeCount,
                    teaCount: teaCount,
                    lemonTeaCount: lemonTeaCount,
                    bottledCount: bottledCount
                ))
            }
        }
        
        return hourlyStats
    }
    
    // 获取周统计
    func getWeekStats() -> [DrinkStats] {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        
        var dailyStats: [DrinkStats] = []
        
        for day in 0..<7 {
            let dayDate = calendar.date(byAdding: .day, value: day, to: weekStart)!
            let dayStart = calendar.startOfDay(for: dayDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayRecords = beverageRecords.filter { record in
                record.timestamp >= dayStart && record.timestamp < dayEnd
            }
            
            let coffeeCount = dayRecords.filter { $0.beverageType == .coffee }.reduce(0) { $0 + $1.quantity }
            let teaCount = dayRecords.filter { $0.beverageType == .tea }.reduce(0) { $0 + $1.quantity }
            let lemonTeaCount = dayRecords.filter { $0.beverageType == .lemonTea }.reduce(0) { $0 + $1.quantity }
            let bottledCount = dayRecords.filter { $0.beverageType == .bottled }.reduce(0) { $0 + $1.quantity }
            
            dailyStats.append(DrinkStats(
                date: dayDate,
                coffeeCount: coffeeCount,
                teaCount: teaCount,
                lemonTeaCount: lemonTeaCount,
                bottledCount: bottledCount
            ))
        }
        
        return dailyStats
    }
    
    // 获取月统计
    func getMonthStats() -> [DrinkStats] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let monthStart = calendar.date(from: components)!
        
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        let daysInMonth = range.count
        
        var monthlyStats: [DrinkStats] = []
        
        for day in 1...daysInMonth {
            var dayComponents = DateComponents()
            dayComponents.year = components.year
            dayComponents.month = components.month
            dayComponents.day = day
            
            let dayDate = calendar.date(from: dayComponents)!
            let dayStart = calendar.startOfDay(for: dayDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayRecords = beverageRecords.filter { record in
                record.timestamp >= dayStart && record.timestamp < dayEnd
            }
            
            let coffeeCount = dayRecords.filter { $0.beverageType == .coffee }.reduce(0) { $0 + $1.quantity }
            let teaCount = dayRecords.filter { $0.beverageType == .tea }.reduce(0) { $0 + $1.quantity }
            let lemonTeaCount = dayRecords.filter { $0.beverageType == .lemonTea }.reduce(0) { $0 + $1.quantity }
            let bottledCount = dayRecords.filter { $0.beverageType == .bottled }.reduce(0) { $0 + $1.quantity }
            
            monthlyStats.append(DrinkStats(
                date: dayDate,
                coffeeCount: coffeeCount,
                teaCount: teaCount,
                lemonTeaCount: lemonTeaCount,
                bottledCount: bottledCount
            ))
        }
        
        return monthlyStats
    }
    
    // 导航到上一个周期
    func moveToPrevious() {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .day:
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        case .week:
            currentDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)!
        case .month:
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        }
    }
    
    // 导航到下一个周期
    func moveToNext() {
        let calendar = Calendar.current
        let today = Date()
        
        var nextDate: Date
        
        switch selectedPeriod {
        case .day:
            nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        case .week:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
        case .month:
            nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }
        
        // 不允许导航到未来
        if nextDate <= today {
            currentDate = nextDate
        }
    }
}

// MARK: - 预览
#Preview {
    StatisticsView()
        .modelContainer(for: BeverageRecord.self, inMemory: true)
}

// 预览样本数据
@MainActor
struct PreviewSampleData {
    static var container: ModelContainer = {
        let schema = Schema([BeverageRecord.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            // 添加一些示例数据
            let context = container.mainContext
            
            // 今天的记录
            let today = Date()
            let coffee1 = BeverageRecord(timestamp: today.addingTimeInterval(-3600), type: .coffee)
            let tea1 = BeverageRecord(timestamp: today.addingTimeInterval(-7200), type: .tea)
            
            // 昨天的记录
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            let coffee2 = BeverageRecord(timestamp: yesterday, type: .coffee)
            let lemonTea = BeverageRecord(timestamp: yesterday.addingTimeInterval(3600), type: .lemonTea, quantity: 2)
            
            // 三天前的记录
            let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
            let bottled = BeverageRecord(timestamp: threeDaysAgo, type: .bottled, quantity: 3)
            
            context.insert(coffee1)
            context.insert(tea1)
            context.insert(coffee2)
            context.insert(lemonTea)
            context.insert(bottled)
            
            return container
        } catch {
            fatalError("无法创建预览模型容器: \(error)")
        }
    }()
} 
