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
        case unlock         = 32
        case setLevelMode   = 65
        case setErgMode     = 66
        case setSimMode     = 67
    }
    
    open static func unlockCommand() -> [UInt8] {
        return [
            WahooTrainerSerializer.OperationCode.unlock.rawValue,
            0xee,   // unlock code
            0xfc    // unlock code
        ]
    }
    
    open static func setResistanceModeLevel(_ level: UInt8) -> [UInt8] {
        return [
            WahooTrainerSerializer.OperationCode.setLevelMode.rawValue,
            level
        ]
    }
    
    open static func setResistanceModeErg(_ watts: UInt16) -> [UInt8] {
        return [
            WahooTrainerSerializer.OperationCode.setErgMode.rawValue,
            UInt8(watts & 0xFF),
            UInt8(watts >> 8)
        ]
        // response: 0x01 0x42 0x01 0x00 watts1 watts2
    }
    
    open static func readReponse(_ data: Data) -> Response? {
        let bytes = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
        let result = bytes[0]   // 01 = success
        let opCodeRaw = bytes[1]
        if let opCode = WahooTrainerSerializer.OperationCode(rawValue: opCodeRaw) {
            
            let response: Response
            
            switch opCode {
            case .setLevelMode:
                response = Response()
            case .setErgMode:
                response = Response()
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
        
        return nil
    }
    
}
