//
//  JetBlackSerializer.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import Foundation
import SwiftySensors

/// :nodoc:
/// Based on ANT+ FE-C standard (::groan::)
open class JetBlackSerializer {
    
    open class SlowChangeData {
        var targetPower: UInt16?
        var userWeight: UInt16?
    }
    
    open class FastChangeData {
        var speed: UInt16?
        var cadence: UInt8?
        var power: UInt16?
    }
    
    open static func setTargetPower(_ watts: UInt16) -> [UInt8] {
        return [0xFF, 0xFF, UInt8(watts & 0xFF), UInt8(watts >> 8), 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
    }
    
    open static func setRiderWeight(_ weight: UInt16) -> [UInt8] {
        return [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, UInt8(weight & 0xFF), UInt8(weight >> 8), 0xFF, 0xFF, 0xFF,
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
    }
    
    open static func setSimulationParameters(rollingResistance: Float, windResistance: Float, grade: Float, windSpeed: Float, draftingFactor: Float) -> [UInt8] {
        // need to convert params to ANT+ units
        return [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
    }
    
    open static func readFastChange(_ data: Data) -> FastChangeData {
        let bytes = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
        let fast = FastChangeData()
        // Included Data:
        // Elapsed Time
        // Distance Travelled
        // Speed
        // Cadence
        // Instantaneous Power
        // Resistance
        // Wind Coefficient
        // Wind Speed
        // Drafting Factor
        // Grade
        // Rolling Coefficient
        
        if data.count >= 4 {
            fast.speed = (UInt16)(bytes[2]) | ((UInt16)(bytes[3]) << 8)
        }
        if data.count >= 5 {
            fast.cadence = bytes[4]
        }
        if data.count >= 7 {
            fast.power = (UInt16)(bytes[5]) | ((UInt16)(bytes[6]) << 8)
        }
        return fast
    }
    
    open static func readSlowChange(_ data: Data) -> SlowChangeData {
        let bytes = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
        let slow = SlowChangeData()
        // Included Data:
        // FE State
        // Capabilities
        // Equipment Type
        // Target Power
        // Cycle Length
        // User Weight
        // Wheel Diameter Offset
        // Bike Weight
        // Wheel Diameter
        // Gear Ratio
        
        if data.count >= 4 {
            slow.targetPower = (UInt16)(bytes[2]) | ((UInt16)(bytes[3]) << 8)
        }
        if data.count >= 7 {
            slow.userWeight = (UInt16)(bytes[5]) | ((UInt16)(bytes[6]) << 8)
        }
        return slow
    }
}
