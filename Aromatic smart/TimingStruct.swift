//
//  TimingStruct.swift
//  Aromatic smart
//
//  Created by عارف on 11/12/2024.
//

import Foundation

struct Timing: Identifiable {
    let id = UUID()
    let number: Int
    let powerOn: String
    let powerOff: String
    let daysOfOperation: [String]
    let gradeMode: String
    let grade: Int
    let customWorkTime: Int
    let customPauseTime: Int
}
