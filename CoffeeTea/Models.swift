import Foundation
import SwiftData

enum BeverageType: String, Codable {
    case coffee = "coffee"
    case tea = "tea"
    case lemonTea = "lemonTea"
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