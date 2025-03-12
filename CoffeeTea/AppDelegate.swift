//
//  AppDelegate.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏图标
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // 设置图标（临时使用系统图标，后续替换）
        statusBarItem.button?.image = NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: nil)
        
        // 点击事件
        statusBarItem.button?.action = #selector(togglePopover)
        
        // 配置弹出窗
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverContentView())
    }
    
    @objc func togglePopover() {
        guard let button = statusBarItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
