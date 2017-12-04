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
    
    open static func setTargetPower(_ watts: UInt16) -> [UInt8] {
        let clamped = min(watts, 4000)
        return [0x00, UInt8(clamped & 0xFF), UInt8(clamped >> 8)]
    }
    
    open static func setBrakeLevel(_ level: Double) -> [UInt8] {
        let clamped = max(min(level, 1), 0)
        let normalized = UInt8(round(clamped * 200))
        return [0x01, normalized]
    }
    
    open static func setSimulationMode(_ grade: Double, crr: Double, wrc: Double, windSpeedKPH: Double = 0, draftingFactor: Double = 1) -> [UInt8] {
        let gradeN = UInt16(((grade * 100) + 200) * 100)
        let crrN = UInt8(crr / 0.00005)
        let wrcN = UInt8(wrc / 0.01)
        let windSpeed = UInt8(max(-127, min(windSpeedKPH, 128)) + 127)
        let draftN = UInt8(draftingFactor / 0.01)
        return [0x02, UInt8(gradeN & 0xFF), UInt8(gradeN >> 8), crrN, wrcN, windSpeed, draftN]
    }
    
    open static func readOutOfRangeValue(_ data: Data) -> Bool? {
        let bytes = (data as NSData).bytes.bindMemory(to: Int8.self, capacity: data.count)
        if data.count > 0 {
            if bytes[0] == -1 {
                return true
            }
            return false
        }
        return nil
    }
    
}
