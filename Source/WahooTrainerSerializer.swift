//
//  WahooTrainerSerializer.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import Foundation
import SwiftySensors

/**
 Message Serializer / Deserializer for Wahoo Trainers.
 
 Work In Progress!
 */
open class WahooTrainerSerializer {
    
    open class Response {
        fileprivate(set) var operationCode: OperationCode!
    }
    
    public enum OperationCode: UInt8 {
        case unlock                     = 32
        case setResistanceMode          = 64
        case setStandardMode            = 65
        case setErgMode                 = 66
        case setSimMode                 = 67
        case setSimCRR                  = 68
        case setSimWindResistance       = 69
        case setSimGrade                = 70
        case setSimWindSpeed            = 71
        case setWheelCircumference      = 72
    }
    
    public static func unlockCommand() -> [UInt8] {
        return [
            WahooTrainerSerializer.OperationCode.unlock.rawValue,
            0xee,   // unlock code
            0xfc    // unlock code
        ]
    }
    
    public static func setResistanceMode(_ resistance: Float) -> [UInt8] {
        let norm = UInt16((1 - resistance) * 16383)
        return [
            WahooTrainerSerializer.OperationCode.setResistanceMode.rawValue,
            UInt8(norm & 0xFF),
            UInt8(norm >> 8 & 0xFF)
        ]
    }
    
    public static func setStandardMode(level: UInt8) -> [UInt8] {
        return [
            WahooTrainerSerializer.OperationCode.setStandardMode.rawValue,
            level
        ]
    }
    
    public static func seErgMode(_ watts: UInt16) -> [UInt8] {
        return [
            WahooTrainerSerializer.OperationCode.setErgMode.rawValue,
            UInt8(watts & 0xFF),
            UInt8(watts >> 8 & 0xFF)
        ]
        // response: 0x01 0x42 0x01 0x00 watts1 watts2
    }
    
    public static func seSimMode(weight: Float, rollingResistanceCoefficient: Float, windResistanceCoefficient: Float) -> [UInt8] {
        // Weight units are Kg
        // TODO: Throw Error if weight, rrc or wrc are not within "sane" values
        let weightN = UInt16(max(0, min(655.35, weight)) * 100)
        let rrcN = UInt16(max(0, min(65.535, rollingResistanceCoefficient)) * 1000)
        let wrcN = UInt16(max(0, min(65.535, windResistanceCoefficient)) * 1000)
        return [
            WahooTrainerSerializer.OperationCode.setSimMode.rawValue,
            UInt8(weightN & 0xFF),
            UInt8(weightN >> 8 & 0xFF),
            UInt8(rrcN & 0xFF),
            UInt8(rrcN >> 8 & 0xFF),
            UInt8(wrcN & 0xFF),
            UInt8(wrcN >> 8 & 0xFF)
        ]
    }
    
    public static func setSimCRR(_ rollingResistanceCoefficient: Float) -> [UInt8] {
        // TODO: Throw Error if rrc is not within "sane" value range
        let rrcN = UInt16(max(0, min(65.535, rollingResistanceCoefficient)) * 1000)
        return [
            WahooTrainerSerializer.OperationCode.setSimCRR.rawValue,
            UInt8(rrcN & 0xFF),
            UInt8(rrcN >> 8 & 0xFF)
        ]
    }
    
    public static func setSimWindResistance(_ windResistanceCoefficient: Float) -> [UInt8] {
        // TODO: Throw Error if wrc is not within "sane" value range
        let wrcN = UInt16(max(0, min(65.535, windResistanceCoefficient)) * 1000)
        return [
            WahooTrainerSerializer.OperationCode.setSimWindResistance.rawValue,
            UInt8(wrcN & 0xFF),
            UInt8(wrcN >> 8 & 0xFF)
        ]
    }
    
    public static func setSimGrade(_ grade: Float) -> [UInt8] {
        // TODO: Throw Error if grade is not between -1 and 1
        let norm = UInt16((min(1, max(-1, grade)) + 1.0) * 65535 / 2.0)
        return [
            WahooTrainerSerializer.OperationCode.setSimGrade.rawValue,
            UInt8(norm & 0xFF),
            UInt8(norm >> 8 & 0xFF)
        ]
    }
    
    public static func setSimWindSpeed(_ metersPerSecond: Float) -> [UInt8] {
        let norm = UInt16((max(-32.767, min(32.767, metersPerSecond)) + 32.767) * 1000)
        return [
            WahooTrainerSerializer.OperationCode.setSimWindSpeed.rawValue,
            UInt8(norm & 0xFF),
            UInt8(norm >> 8 & 0xFF)
        ]
    }
    
    public static func setWheelCircumference(_ millimeters: Float) -> [UInt8] {
        let norm = UInt16(max(0, millimeters) * 10)
        return [
            WahooTrainerSerializer.OperationCode.setWheelCircumference.rawValue,
            UInt8(norm & 0xFF),
            UInt8(norm >> 8 & 0xFF)
        ]
    }
    
    public static func readReponse(_ data: Data) -> Response? {
        let bytes = data.map { $0 }
        if bytes.count > 1 {
            let result = bytes[0]   // 01 = success
            let opCodeRaw = bytes[1]
            if let opCode = WahooTrainerSerializer.OperationCode(rawValue: opCodeRaw) {
                let response: Response
                switch opCode {
                default:
                    response = Response()
                }
                response.operationCode = opCode
                return response
            } else {
                SensorManager.logSensorMessage?("Unrecognized Operation Code: \(opCodeRaw)")
            }
            if result == 1 {
                SensorManager.logSensorMessage?("Success for operation: \(opCodeRaw)")
            }
        }
        return nil
    }
}
