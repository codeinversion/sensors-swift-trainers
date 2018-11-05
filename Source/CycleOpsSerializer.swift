//
//  CycleOpsSerializer.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import Foundation
import SwiftySensors

/// :nodoc:
open class CycleOpsSerializer {
    
    public class Response {
        fileprivate(set) var mode: ControlMode = .headless
        fileprivate(set) var status: ControlStatus = .speedOkay
        fileprivate(set) var parameter1: Int16 = 0
        fileprivate(set) var parameter2: Int16 = 0
    }
    
    public enum ControlMode: UInt8 {
        case headless           = 0x00
        case manualPower        = 0x01
        case manualSlope        = 0x02
        case powerRange         = 0x03
        case warmUp             = 0x04
        case rollDown           = 0x05
    }
    
    public enum ControlStatus: UInt8 {
        case speedOkay              = 0x00
        case speedUp                = 0x01
        case speedDown              = 0x02
        case rollDownInitializing   = 0x03
        case rollDownInProcess      = 0x04
        case rollDownPassed         = 0x05
        case rollDownFailed         = 0x06
    }
    
    
    
    public static func setControlMode(_ mode: ControlMode, parameter1: Int16 = 0, parameter2: Int16 = 0) -> [UInt8] {
        return [
            0x00, 0x10,
            mode.rawValue,
            UInt8(parameter1 & 0xFF), UInt8(parameter1 >> 8 & 0xFF),
            UInt8(parameter2 & 0xFF), UInt8(parameter2 >> 8 & 0xFF),
            0x00, 0x00, 0x00
        ]
    }
    
    public static func readReponse(_ data: Data) -> Response? {
        let bytes = data.map { $0 }
        var index: Int = 0
        if bytes.count > 9 {
            let _ = UInt16(bytes[index++=]) | UInt16(bytes[index++=]) << 8 //  response code
            let commandIdRaw = UInt16(bytes[index++=]) | UInt16(bytes[index++=]) << 8
            if commandIdRaw == 0x1000 {
                let controlRaw = bytes[index++=]
                let parameter1 = Int16(bytes[index++=]) | Int16(bytes[index++=]) << 8
                let parameter2 = Int16(bytes[index++=]) | Int16(bytes[index++=]) << 8
                let statusRaw = bytes[index++=]
                if let controlMode = CycleOpsSerializer.ControlMode(rawValue: controlRaw) {
                    if let status = CycleOpsSerializer.ControlStatus(rawValue: statusRaw) {
                        let response = Response()
                        response.mode = controlMode
                        response.status = status
                        response.parameter1 = parameter1
                        response.parameter2 = parameter2
                        return response
                    }
                }
            }
        }
        return nil
    }
    
}
