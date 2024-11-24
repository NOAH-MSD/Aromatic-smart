//
//  Diffuser.swift
//  aromatic-app
//
//  Created by عارف on 17/11/2024.
//

import Foundation
import SwiftData



@Model
class Diffuser: Identifiable {
    var id = UUID()
    var name: String
    var isConnected: Bool
    var modelNumber: String
    var serialNumber: String
    var timerSetting: Int
    
    
    init(name: String, isConnected: Bool, modelNumber: String, serialNumber: String, timerSetting: Int) {
        self.name = name
        self.isConnected = isConnected
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.timerSetting = timerSetting
    }
}
