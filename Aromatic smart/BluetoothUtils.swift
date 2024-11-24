//
//  BluetoothUtils.swift
//  aromatic-app
//
//  Created by عارف on 17/11/2024.
//

// Utilities/BluetoothUtils.swift
import Foundation

struct BluetoothUtils {
    static func formatPeripheralName(_ name: String?) -> String {
        return name ?? "Unnamed Device"
    }
}
