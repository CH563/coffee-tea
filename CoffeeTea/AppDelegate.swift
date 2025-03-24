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
    var dailyCheckTimer: Timer?  // 新增：每日检查定时器
    var originalIcon: NSImage?   // 新增：保存原始图标
    
    // 保持对统计视图窗口控制器的强引用
    private var statisticsWindowController: NSWindowController?
    
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
        
        // 应用启动时检查今天是否已经有饮料记录
        checkTodayDrinkRecords()
        
        // 设置每日凌晨检查定时器
        setupDailyCheckTimer()
    }
    
    // MARK: - 设置方法
    
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
            originalIcon = icon.copy() as? NSImage  // 保存原始图标
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
        
        // 设置背景色
        popover.appearance = NSAppearance(named: .aqua)
        
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
            name: Notification.Name.drinkAdded,
            object: nil
        )
        
        // 监听饮品移除事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkTodayDrinkRecords),
            name: Notification.Name.drinkRemoved,
            object: nil
        )
    }
    
    // MARK: - 事件处理
    
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
            showStatisticsView()
        }
    }
    
    @objc func handleDrinkAdded() {
        // 添加成功动画：图标旋转
        animateStatusBarIcon()
        
        // 设置状态栏图标倾斜
        tiltStatusBarIcon()
    }
    
    // MARK: - 菜单和工具方法
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "快速记录咖啡", action: #selector(quickAddCoffee), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "快速记录奶茶", action: #selector(quickAddTea), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "快速记录柠檬茶", action: #selector(quickAddLemonTea), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "快速记录三得利", action: #selector(quickAddBottled), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "饮料统计", action: #selector(showTodayConsumptionFromMenu), keyEquivalent: ""))
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
        showStatisticsView()
    }
    
    private func showStatisticsView() {
        // 如果窗口控制器已经存在，则将其窗口前置显示
        if let windowController = statisticsWindowController {
            windowController.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建统计视图窗口
        let statisticsView = StatisticsView()
            .environment(\.modelContext, modelContext)
        
        let hostingController = NSHostingController(rootView: statisticsView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "饮料统计"
        window.center()
        window.contentViewController = hostingController
        
        // 创建窗口控制器
        let windowController = NSWindowController(window: window)
        windowController.shouldCascadeWindows = true
        
        // 保存窗口控制器的引用
        statisticsWindowController = windowController
        
        // 设置窗口关闭时的回调
        window.delegate = self
        
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func animateStatusBarIcon() {
        guard let button = statusBarItem.button else { return }
        
        // 创建晃动动画
        let animation = CAKeyframeAnimation(keyPath: "position.x")
        animation.values = [
            button.frame.origin.x,     // 原始位置
            button.frame.origin.x - 3, // 左移3点
            button.frame.origin.x + 3, // 右移3点
            button.frame.origin.x - 2, // 左移2点
            button.frame.origin.x + 2, // 右移2点
            button.frame.origin.x      // 回到原始位置
        ]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1.0]
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // 应用动画到按钮的图层
        button.layer?.add(animation, forKey: "shake")
    }
    
    // MARK: - 快速添加饮料
    
    @objc func quickAddCoffee() {
        addQuickDrink(type: .coffee)
    }
    
    @objc func quickAddTea() {
        addQuickDrink(type: .tea)
    }

    @objc func quickAddLemonTea() {
        addQuickDrink(type: .lemonTea)
    }
    
    @objc func quickAddBottled() {
        addQuickDrink(type: .bottled)
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
            "您的身体正在组织一场名为'抗糖联盟'的集会，要不要考虑喝杯水？",
            "瓶装饮料虽方便，但塑料瓶对环境不太友好哦，考虑下可重复使用的杯子？"
        ]
        
        let randomIndex = Int.random(in: 0..<warningMessages.count)
        alert.messageText = warningMessages[randomIndex]
        
        // 设置图标为水滴表情符号
        let emojiAttributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 24)]
        let emoji = NSAttributedString(string: "💧", attributes: emojiAttributes)
        
        let emojiImage = NSImage(size: NSSize(width: 30, height: 30))
        emojiImage.lockFocus()
        emoji.draw(at: NSPoint(x: 3, y: 3))
        emojiImage.unlockFocus()
        
        alert.icon = emojiImage
        
        // 添加两个按钮
        let button1 = alert.addButton(withTitle: "就要喝 \(type.emoji)")
        button1.font = NSFont.systemFont(ofSize: 12)
        
        // 设置按钮为蓝底白字
        if let cell = button1.cell as? NSButtonCell {
            cell.backgroundColor = NSColor.systemBlue
            button1.contentTintColor = NSColor.white
        }
        
        let button2 = alert.addButton(withTitle: "喝水去 💧")
        button2.font = NSFont.systemFont(ofSize: 12)
        
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
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name.updateCurrentDate,
                object: nil
            )
        }
    }
    
    // 新增：设置每日检查定时器，在凌晨重置图标
    private func setupDailyCheckTimer() {
        // 计算到下一个凌晨的时间
        let now = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.day = (components.day ?? 0) + 1
        components.hour = 0
        components.minute = 0
        components.second = 1
        
        guard let nextMidnight = calendar.date(from: components) else { return }
        
        // 创建定时器，每天凌晨触发
        dailyCheckTimer = Timer.scheduledTimer(
            withTimeInterval: nextMidnight.timeIntervalSince(now),
            repeats: false
        ) { [weak self] _ in
            self?.resetStatusBarIcon()
            // 重新设置下一天的定时器
            self?.setupDailyCheckTimer()
        }
    }
    
    // 新增：倾斜状态栏图标
    private func tiltStatusBarIcon() {
        guard let button = statusBarItem.button, let icon = button.image else { return }
        
        // 创建倾斜45度的图标
        let tiltedIcon = icon.copy() as! NSImage
        tiltedIcon.rotate(byDegrees: 45)
        
        // 设置倾斜的图标
        button.image = tiltedIcon
    }
    
    // 新增：重置状态栏图标为正常状态
    private func resetStatusBarIcon() {
        guard let button = statusBarItem.button, let originalIcon = self.originalIcon else { return }
        button.image = originalIcon.copy() as? NSImage
    }
    
    // 新增：检查今天是否有饮料记录，有则倾斜图标，无则重置图标
    @objc func checkTodayDrinkRecords() {
        // 获取今日记录
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<BeverageRecord> { record in
            record.timestamp >= today && record.timestamp < tomorrow
        }
        
        let descriptor = FetchDescriptor<BeverageRecord>(predicate: predicate)
        
        do {
            let todayRecords = try modelContext.fetch(descriptor)
            if todayRecords.isEmpty {
                // 今天没有记录，重置图标
                resetStatusBarIcon()
            } else {
                // 今天有记录，倾斜图标
                tiltStatusBarIcon()
            }
        } catch {
            print("检查今日饮料记录失败: \(error)")
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

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // 如果是统计视图窗口，则清除窗口控制器引用
        if window === statisticsWindowController?.window {
            statisticsWindowController = nil
        }
    }
}
