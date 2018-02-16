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
public class JetBlackSerializer {
    
    public struct SlowChangeData {
        fileprivate(set) public var targetPower: UInt16?
        fileprivate(set) public var userWeight: UInt16?
    }
    
    public struct FastChangeData {
        fileprivate(set) public var speed: UInt16?
        fileprivate(set) public var cadence: UInt8?
        fileprivate(set) public var power: UInt16?
    }
    
    public static func setTargetPower(_ watts: UInt16) -> [UInt8] {
        return [0xFF, 0xFF, UInt8(watts & 0xFF), UInt8(watts >> 8 & 0xFF), 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
    }
    
    public static func setRiderWeight(_ weight: UInt16) -> [UInt8] {
        return [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, UInt8(weight & 0xFF), UInt8(weight >> 8 & 0xFF), 0xFF, 0xFF, 0xFF,
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
    }
    
    public static func setSimulationParameters(rollingResistance: Float, windResistance: Float, grade: Float, windSpeed: Float, draftingFactor: Float) -> [UInt8] {
        // need to convert params to ANT+ units
        
        // wind res = Product of Frontal Surface Area, Drag Coefficient and Air Density. Use default value: 0xFF.
        //      (units 0.01kg/m) (range 0-1.86 kg/m)
        let cwrN = UInt8(windResistance * 100)
        
        // wind speed = range (-127 to 127)
        let windSpeedN = UInt8(Int(windSpeed) & 0xFF)
        
        // drafting factor = range (0 - 1.0) units (0.01)
        let dfN = UInt8(Int(draftingFactor * 100) & 0xFF)
        
        // grade = units(0.01), range (-200 to 200)
        let gradeN = Int16(grade * 100)
        
        // crr = units (5E-5) range (0 = 0.0127)
        let crrN = UInt8(Int(rollingResistance / (5 * pow(10.0, -5))) & 0xFF)
        
        return [
            0xFF, // elapsed time
            0xFF, // distance travelled
            0xFF, 0xFF, //speed
            0xFF, //cadence
            0xFF, 0xFF, // power
            0xFF, // resistance
            cwrN, // wind resistance
            windSpeedN, // wind speed
            dfN, // drafting factor
            UInt8(gradeN & 0xFF), UInt8(gradeN >> 8 & 0xFF), // grade
            crrN, // rolling coefficient
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
    }
    
    public static func readFastChange(_ data: Data) -> FastChangeData {
        let bytes = data.map { $0 }
        var fast = FastChangeData()
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
            fast.speed = UInt16(bytes[2]) | UInt16(bytes[3]) << 8
        }
        if data.count >= 5 {
            fast.cadence = bytes[4]
        }
        if data.count >= 7 {
            fast.power = UInt16(bytes[5]) | UInt16(bytes[6]) << 8
        }
        return fast
    }
    
    public static func readSlowChange(_ data: Data) -> SlowChangeData {
        let bytes = data.map { $0 }
        var slow = SlowChangeData()
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
            slow.targetPower = UInt16(bytes[2]) | UInt16(bytes[3]) << 8
        }
        if data.count >= 7 {
            slow.userWeight = UInt16(bytes[5]) | UInt16(bytes[6]) << 8
        }
        return slow
    }
}

