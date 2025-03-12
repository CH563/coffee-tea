//
//  PopoverContentView.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import SwiftUI

struct PopoverContentView: View {
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack {
            // 日历组件
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
            
            // 添加记录按钮
            HStack {
                Button("咖啡") { addRecord(type: .coffee) }
                Button("奶茶") { addRecord(type: .tea) }
            }
        }
        .padding()
    }
    
    private func addRecord(type: DrinkType) {
        // 后续实现存储逻辑
        print("Added \(type) at \(selectedDate)")
    }
}

enum DrinkType {
    case coffee, tea
}
