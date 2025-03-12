//
//  Item.swift
//  CoffeeTea
//
//  Created by Liwen on 2025/3/12.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
