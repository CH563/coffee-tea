//
//  AppDelegate.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import AppKit
import SwiftUI
import SwiftData

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var popover = NSPopover()
    var modelContext: ModelContext!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏主窗口
        NSApp.setActivationPolicy(.accessory)
        
        setupModelContext()
        setupStatusBar()
        setupPopover()
        setupNotifications()
        
        NSApplication.shared.windows.forEach { window in
            window.contentView?.wantsLayer = true
        }
    }
    
    private func setupModelContext() {
        let schema = Schema([BeverageRecord.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func setupStatusBar() {
        // 创建状态栏图标
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            // 设置图标
            let icon = NSImage(named: "StatusBarIcon") ?? NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Coffee Tea")!
            icon.size = NSSize(width: 18, height: 18)
            button.image = icon
            
            // 点击事件
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // 长按事件
            let longPressGesture = NSPressGestureRecognizer(target: self, action: #selector(handleLongPress))
            longPressGesture.minimumPressDuration = 0.5
            button.addGestureRecognizer(longPressGesture)
        }
    }
    
    private func setupPopover() {
        // 配置弹出窗
        popover.contentSize = NSSize(width: 280, height: 400)
        popover.behavior = .transient
        
        // 设置背景色 - 修复错误
        popover.appearance = NSAppearance(named: .aqua) // 使用系统默认外观
        
        // 创建 SwiftUI 视图并传入 ModelContext
        let contentView = PopoverContentView()
            .environment(\.modelContext, modelContext)
        
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    private func setupNotifications() {
        // 监听饮品添加事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDrinkAdded),
            name: Notification.Name("DrinkAdded"),
            object: nil
        )
    }
    
    @objc func togglePopover(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        if event?.type == .rightMouseUp {
            // 显示右键菜单
            showContextMenu()
        } else {
            // 显示/隐藏弹出窗
            if popover.isShown {
                popover.performClose(nil)
            } else {
                // 在显示 Popover 前更新日期
                updateCurrentDate()
                popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            }
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: NSPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            showTodayConsumption()
        }
    }
    
    @objc func handleDrinkAdded() {
        // 添加成功动画：图标旋转
        animateStatusBarIcon()
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "快速记录咖啡", action: #selector(quickAddCoffee), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "快速记录奶茶", action: #selector(quickAddTea), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "今日消费", action: #selector(showTodayConsumptionFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
        
        // 使用完后清除菜单，以便下次点击可以触发 action
        DispatchQueue.main.async {
            self.statusBarItem.menu = nil
        }
    }
    
    @objc func showTodayConsumptionFromMenu() {
        showTodayConsumption()
    }
    
    private func showTodayConsumption() {
        // 获取今日消费数据
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<BeverageRecord> { record in
            record.timestamp >= today && record.timestamp < tomorrow
        }
        
        let descriptor = FetchDescriptor<BeverageRecord>(predicate: predicate)
        
        do {
            let todayRecords = try modelContext.fetch(descriptor)
            let coffeeCount = todayRecords.filter { $0.beverageType == .coffee }.reduce(0) { $0 + $1.quantity }
            let teaCount = todayRecords.filter { $0.beverageType == .tea }.reduce(0) { $0 + $1.quantity }
            
            // 显示今日消费
            let message = "今日：\(coffeeCount) 咖啡 \(teaCount) 奶茶"
            
            if statusBarItem.button != nil {
                let alert = NSAlert()
                alert.messageText = message
                alert.addButton(withTitle: "确定")
                alert.runModal()
            }
        } catch {
            print("获取今日消费数据失败: \(error)")
        }
    }
    
    private func animateStatusBarIcon() {
        guard let button = statusBarItem.button else { return }
        
        // 保存原始位置
        let originalFrame = button.frame
        
        // 创建晃动动画
        let animation = CAKeyframeAnimation(keyPath: "position.x")
        animation.values = [
            originalFrame.origin.x,                  // 原始位置
            originalFrame.origin.x - 3,              // 左移3点
            originalFrame.origin.x + 3,              // 右移3点
            originalFrame.origin.x - 2,              // 左移2点
            originalFrame.origin.x + 2,              // 右移2点
            originalFrame.origin.x                   // 回到原始位置
        ]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1.0]
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // 应用动画到按钮的图层
        button.layer?.add(animation, forKey: "shake")
    }
    
    @objc func quickAddCoffee() {
        addQuickDrink(type: BeverageType.coffee)
    }
    
    @objc func quickAddTea() {
        addQuickDrink(type: BeverageType.tea)
    }
    
    private func addQuickDrink(type: BeverageType) {
        // 检查当天饮料数量
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<BeverageRecord> { record in
            record.timestamp >= today && record.timestamp < tomorrow
        }
        
        let descriptor = FetchDescriptor<BeverageRecord>(predicate: predicate)
        
        do {
            let todayRecords = try modelContext.fetch(descriptor)
            let totalDrinks = todayRecords.reduce(0) { $0 + $1.quantity }
            
            if totalDrinks >= 2 {
                // 已经喝了2杯或更多，显示提示
                showDrinkWarning(type: type)
            } else {
                // 直接添加记录
                addDrinkRecord(type: type)
            }
        } catch {
            print("获取今日饮料数据失败: \(error)")
            // 出错时也添加记录
            addDrinkRecord(type: type)
        }
    }
    
    private func showDrinkWarning(type: BeverageType) {
        let alert = NSAlert()
        
        // 随机选择一条诙谐提示语
        let warningMessages = [
            "今天的咖啡因已经超标啦！饮料好喝莫贪杯，不如来杯清水润润肺？",
            "又来一杯？您的肾脏正在抗议：'主人，我已经很努力了！'",
            "多喝热水，少喝甜饮，医生微笑，肾脏感谢！",
            "今日糖分摄入已达小熊维尼级别，确定要继续吗？",
            "您的身体正在组织一场名为'抗糖联盟'的集会，要不要考虑喝杯水？"
        ]
        
        let randomIndex = Int.random(in: 0..<warningMessages.count)
        alert.messageText = warningMessages[randomIndex]
        alert.icon = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: nil)
        
        // 添加两个按钮
        let drinkButton = alert.addButton(withTitle: "就要喝 ☕️")
        _ = alert.addButton(withTitle: "喝水去 💧")
        
        // 设置按钮样式
        drinkButton.hasDestructiveAction = true
        
        // 显示警告并处理结果
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // 用户选择"就要喝"
            addDrinkRecord(type: type)
        } else {
            // 用户选择"喝水去"，不添加记录
            print("用户选择不添加饮料记录")
        }
    }
    
    private func addDrinkRecord(type: BeverageType) {
        let newRecord = BeverageRecord(timestamp: Date(), type: type)
        modelContext.insert(newRecord)
        
        // 触发动画
        handleDrinkAdded()
    }
    
    // 添加更新日期的方法
    private func updateCurrentDate() {
        // 获取 PopoverContentView 实例
        if popover.contentViewController is NSHostingController<PopoverContentView> {
            // 直接发送通知，不需要类型转换
            DispatchQueue.main.async {
                // 通过通知中心发送更新日期的通知
                NotificationCenter.default.post(
                    name: Notification.Name("UpdateCurrentDate"),
                    object: nil
                )
            }
        }
    }
}

extension NSImage {
    func rotate(byDegrees degrees: CGFloat) {
        let imageRect = NSRect(origin: .zero, size: size)
        let rotatedImage = NSImage(size: size)
        
        rotatedImage.lockFocus()
        NSGraphicsContext.current?.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
        NSGraphicsContext.current?.cgContext.rotate(by: degrees * CGFloat.pi / 180)
        NSGraphicsContext.current?.cgContext.translateBy(x: -size.width / 2, y: -size.height / 2)
        draw(in: imageRect)
        rotatedImage.unlockFocus()
        
        self.lockFocus()
        rotatedImage.draw(in: imageRect, from: .zero, operation: .copy, fraction: 1.0)
        self.unlockFocus()
    }
}
