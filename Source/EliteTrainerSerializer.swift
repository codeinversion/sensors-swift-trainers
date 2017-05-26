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
