//
//  Item.swift
//  Comic Archiv
//
//  Created by Igor Stein on 27.01.26.
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
