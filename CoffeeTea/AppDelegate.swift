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
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        
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
        
        menu.addItem(NSMenuItem(title: "快速记录咖啡", action: #selector(quickAddCoffee), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "快速记录奶茶", action: #selector(quickAddTea), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "打开日历", action: #selector(togglePopover), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
        
        // 使用完后清除菜单，以便下次点击可以触发 action
        DispatchQueue.main.async {
            self.statusBarItem.menu = nil
        }
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
        guard let button = statusBarItem.button, let image = button.image else { return }
        
        // 保存原始图像
        let originalImage = image
        
        // 创建旋转动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            button.image?.rotate(byDegrees: 15)
        }, completionHandler: {
            // 动画完成后恢复原始图像
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                button.image = originalImage
            })
        })
    }
    
    @objc func quickAddCoffee() {
        addQuickDrink(type: BeverageType.coffee)
    }
    
    @objc func quickAddTea() {
        addQuickDrink(type: BeverageType.tea)
    }
    
    private func addQuickDrink(type: BeverageType) {
        let newRecord = BeverageRecord(timestamp: Date(), type: type)
        modelContext.insert(newRecord)
        
        // 触发动画
        handleDrinkAdded()
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
