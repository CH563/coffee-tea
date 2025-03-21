import Foundation
import SwiftData
import SwiftUI
import AppKit

enum BeverageType: String, Codable {
    case coffee = "coffee"
    case tea = "tea"
    case lemonTea = "lemonTea"
    
    var displayName: String {
        switch self {
        case .coffee:
            return "咖啡"
        case .tea:
            return "奶茶" 
        case .lemonTea:
            return "柠檬茶"
        }
    }
    
    var iconName: String {
        switch self {
        case .coffee:
            return "cup.and.saucer.fill"
        case .tea:
            return "mug.fill"
        case .lemonTea:
            return "cup.and.saucer"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .coffee:
            return .brown
        case .tea:
            return .purple
        case .lemonTea:
            return .yellow
        }
    }
    
    var emoji: String {
        switch self {
        case .coffee:
            return "☕️"
        case .tea:
            return "🧋"
        case .lemonTea:
            return "🍋"
        }
    }
}

@Model
final class BeverageRecord {
    var timestamp: Date
    var type: String // "coffee"、"tea"或"lemonTea"
    var quantity: Int
    
    init(timestamp: Date, type: BeverageType, quantity: Int = 1) {
        self.timestamp = timestamp
        self.type = type.rawValue
        self.quantity = quantity
    }
    
    var beverageType: BeverageType {
        return BeverageType(rawValue: type) ?? .coffee
    }
    
    var emoji: String {
        switch beverageType {
        case .coffee:
            return "☕️"
        case .tea:
            return "🧋"
        case .lemonTea:
            return "🍋"
        }
    }
} 