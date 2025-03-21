//
//  PopoverContentView.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import SwiftData
import SwiftUI
import AppKit

// 主要视图
struct PopoverContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var beverageRecords: [BeverageRecord]
    
    @StateObject private var dateObserver = DateUpdateObserver()
    
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

    // 检查是否选择了未来日期
    var isFutureDate: Bool {
        return selectedDate > Date()
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 顶部标题栏
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
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                
                Divider().padding(.vertical, 0)
                
                // 日期详情视图
                DateDetailView(
                    date: selectedDate, 
                    records: recordsForDate(selectedDate)
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                
                Divider()
                
                // 底部快速添加按钮
                HStack(spacing: 12) {
                    Spacer()
                    
                    // 咖啡按钮
                    createBeverageButton(
                        type: .coffee,
                        action: { addRecord(type: .coffee) }
                    )
                    
                    // 奶茶按钮
                    createBeverageButton(
                        type: .tea,
                        action: { addRecord(type: .tea) }
                    )
                    
                    // 柠檬茶按钮
                    createBeverageButton(
                        type: .lemonTea,
                        action: { addRecord(type: .lemonTea) }
                    )
                    
                    // 瓶装饮料按钮
                    createBeverageButton(
                        type: .bottled,
                        action: { addRecord(type: .bottled) }
                    )
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .frame(width: 280)
            .background(Color(.textBackgroundColor))
            .onChange(of: dateObserver.lastUpdateTime) {
                selectedDate = Date()
                currentMonth = Date()
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
    
    // 创建饮料按钮
    private func createBeverageButton(type: BeverageType, action: @escaping () -> Void) -> some View {
        Button(action: { 
            withAnimation {
                selectedBeverageType = type
                addedAnimation = true
            }
            action()
            
            // 重置动画状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    addedAnimation = false
                }
            }
        }) {
            VStack(spacing: 2) {
                Image(systemName: type.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(type.themeColor)
                Text(type.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.primary)
            }
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(type.themeColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(type.themeColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(selectedBeverageType == type && addedAnimation ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .disabled(isFutureDate)
        .opacity(isFutureDate ? 0.5 : 1.0)
        .onLongPressGesture {
            if !isFutureDate {
                selectedBeverageType = type
                showingCustomQuantityInput = true
            }
        }
    }

    // 添加饮料记录
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

    // 显示饮料警告
    private func showDrinkWarning(type: BeverageType, quantity: Int) {
        // 随机选择一条诙谐提示语
        let warningMessages = [
            "今天的咖啡因已经超标啦！饮料好喝莫贪杯，不如来杯清水润润肺？",
            "又来一杯？您的肾脏正在抗议：'主人，我已经很努力了！'",
            "多喝热水，少喝甜饮，医生微笑，肾脏感谢！",
            "今日糖分摄入已达小熊维尼级别，确定要继续吗？",
            "您的身体正在组织一场名为'抗糖联盟'的集会，要不要考虑喝杯水？",
            "瓶装饮料虽方便，但塑料瓶对环境不太友好哦，考虑下可重复使用的杯子？"
        ]
        
        let randomIndex = Int.random(in: 0..<warningMessages.count)
        warningMessage = warningMessages[randomIndex]
        warningType = type
        warningQuantity = quantity
        
        withAnimation(.spring(response: 0.3)) {
            showingDrinkWarning = true
        }
    }

    // 添加饮料记录到数据库
    private func addDrinkRecord(type: BeverageType, quantity: Int) {
        let newRecord = BeverageRecord(timestamp: selectedDate, type: type, quantity: quantity)
        modelContext.insert(newRecord)

        NotificationCenter.default.post(
            name: Notification.Name.drinkAdded,
            object: nil)
    }

    // 获取指定日期的记录
    private func recordsForDate(_ date: Date) -> [BeverageRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return beverageRecords.filter { record in
            record.timestamp >= startOfDay && record.timestamp < endOfDay
        }
    }
}
