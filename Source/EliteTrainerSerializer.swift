//
//  EliteTrainerSerializer.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import Foundation
import SwiftySensors

/// :nodoc:
open class EliteTrainerSerializer {
    
    public static func setTargetPower(_ watts: UInt16) -> [UInt8] {
        let clamped = min(watts, 4000)
        return [0x00, UInt8(clamped & 0xFF), UInt8(clamped >> 8 & 0xFF)]
    }
    
    public static func setBrakeLevel(_ level: Double) -> [UInt8] {
        let clamped = max(min(level, 1), 0)
        let normalized = UInt8(round(clamped * 200))
        return [0x01, normalized]
    }
    
    public static func setSimulationMode(_ grade: Double, crr: Double, wrc: Double, windSpeedKPH: Double = 0, draftingFactor: Double = 1) -> [UInt8] {
        let gradeN = UInt16(((grade * 100) + 200) * 100)
        let crrN = UInt8(Int(crr / 0.00005) & 0xFF)
        let wrcN = UInt8(Int(wrc / 0.01) & 0xFF)
        let windSpeed = UInt8(max(-127, min(windSpeedKPH, 128)) + 127)
        let draftN = UInt8(Int(draftingFactor / 0.01) & 0xFF)
        return [0x02, UInt8(gradeN & 0xFF), UInt8(gradeN >> 8 & 0xFF), crrN, wrcN, windSpeed, draftN]
    }
    
    public static func readOutOfRangeValue(_ data: Data) -> Bool? {
        let bytes = data.map { $0 }
        if data.count > 0 {
            if Int8(bitPattern: bytes[0]) == -1 {
                return true
            }
            return false
        }
        return nil
    }
    
}
