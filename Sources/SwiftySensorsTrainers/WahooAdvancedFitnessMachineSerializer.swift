//
//  WahooAdvancedFitnessMachineSerializer.swift
//  SwiftySensorsTrainers iOS
//
//  Created by Josh Levine on 5/9/18.
//  Copyright © 2018 Kinetic. All rights reserved.
//

import Foundation

func decodeTilt(lsb: UInt8, msb: UInt8) -> Double {
    let unsignedValue = UInt16(msb) << 8 | UInt16(lsb)
    let signedValue = Int16(bitPattern: unsignedValue)
    return Double(signedValue) / 100
}

open class WahooAdvancedFitnessMachineSerializer {
    public enum OpCode: UInt8 {
        case getHubHeight = 1
        case setHubHeight = 2
        case getWheelBase = 3
        case setWheelBase = 4
        case getTargetTilt = 101
        case setTargetTilt = 102
        case getTiltMode = 103
        case getCurrentTilt = 104
        case getTiltLimits = 105
        case eventPacket = 253 // Not a command op code - used in event packets to indicate the packet is an event
        case responsePacket = 254 // Not a command op code - used in response packets to indicate the packet is a response
    }
    
    public enum ResponseCode: UInt8 {
        case success = 1
        case opCodeNotSupported = 2
        case invalidParameter = 3
        case operationFailed = 4
        case deviceNotAvailable = 5
    }
    
    public enum EventCode: UInt8 {
        case hubHeightChanged = 1
        case wheelBaseChanged = 2
        case targetTiltChanged = 50
        case tiltModechanged = 51
        case currentTiltChanged = 52
        case tiltLimitsChanged = 53
        case tiltLimitsAvailable = 54
    }
    
    public enum TiltMode: UInt8 {
        case unlocked = 0
        case locked = 1
        case unknown = 255 // Unknown/invalid (tilt feature not available)
    }
    
    public struct CommandPacket {
        public let opCode: OpCode
        public let message: [UInt8]
        
        public var bytes: [UInt8] { return [opCode.rawValue] + message }
        
        public var data: Data { return Data(bytes) }
    }

    public struct ResponsePacket {
        public let opCode: OpCode
        public let responseCode: ResponseCode
        public let bytes: [UInt8]

        public static func parse(packet: [UInt8]) -> ResponsePacket? {
            if packet.count < 3 || packet[0] != OpCode.responsePacket.rawValue {
                return nil
            }
            guard let opCode = OpCode.init(rawValue: packet[1]), let responseCode = ResponseCode.init(rawValue: packet[2]) else {
                return nil
            }
            let bytes = Array(packet.dropFirst(3))
            return ResponsePacket(opCode: opCode, responseCode: responseCode, bytes: bytes)
        }
        
        public var hubHeight: UInt16? {
            if [OpCode.getHubHeight, .setHubHeight].contains(opCode) && bytes.count >= 2 {
                return UInt16(bytes[1]) << 8 | UInt16(bytes[0])
            }
            return nil
        }
        
        public var wheelBase: UInt16? {
            if [OpCode.getWheelBase, .setWheelBase].contains(opCode) && bytes.count >= 2 {
                return UInt16(bytes[1]) << 8 | UInt16(bytes[0])
            }
            return nil
        }
        
        public var targetTilt: Double? {
            if [OpCode.getTargetTilt, .setTargetTilt].contains(opCode) && bytes.count >= 2 {
                return Double(UInt16(bytes[1]) << 8 | UInt16(bytes[0])) / 100
            }
            return nil
        }
        
        public var tiltMode: TiltMode? {
            if opCode == .getTiltMode && bytes.count >= 1 {
                return TiltMode.init(rawValue: bytes[0])
            }
            return nil
        }
        
        public var currentTilt: Double? {
            if opCode == .getCurrentTilt && bytes.count >= 1 {
                return Double(UInt16(bytes[1]) << 8 | UInt16(bytes[0])) / 100
            }
            return nil
        }
    }
    
    public struct EventPacket {
        public let eventCode: EventCode
        public let bytes: [UInt8]
        
        public static func parse(packet: [UInt8]) -> EventPacket? {
            if packet.count < 2 || packet[0] != OpCode.eventPacket.rawValue {
                return nil
            }
            guard let eventCode = EventCode.init(rawValue: packet[1]) else {
                return nil
            }
            let bytes = Array(packet.dropFirst(2))
            return EventPacket(eventCode: eventCode, bytes: bytes)
        }
        
        public var hubHeight: UInt16? {
            if eventCode == .hubHeightChanged && bytes.count >= 2 {
                return UInt16(bytes[1]) << 8 | UInt16(bytes[0])
            }
            return nil
        }
        
        public var wheelBase: UInt16? {
            if eventCode == .wheelBaseChanged && bytes.count >= 2 {
                return UInt16(bytes[1]) << 8 | UInt16(bytes[0])
            }
            return nil
        }
        
        public var targetTilt: Double? {
            if eventCode == .targetTiltChanged && bytes.count >= 2 {
                return decodeTilt(lsb: bytes[0], msb: bytes[1])
            }
            return nil
        }
        
        public var tiltMode: TiltMode? {
            if eventCode == .tiltModechanged && bytes.count >= 1 {
                return TiltMode.init(rawValue: bytes[0])
            }
            return nil
        }
        
        public var currentTilt: Double? {
            if eventCode == .currentTiltChanged && bytes.count >= 2 {
                return decodeTilt(lsb: bytes[0], msb: bytes[1])
            }
            return nil
        }
        
        public var minimumTilt: Double? {
            if [EventCode.tiltLimitsAvailable, .tiltLimitsChanged].contains(eventCode) && bytes.count >= 2 {
                return decodeTilt(lsb: bytes[0], msb: bytes[1])
            }
            return nil
        }
        
        public var maximumTilt: Double? {
            if [EventCode.tiltLimitsAvailable, .tiltLimitsChanged].contains(eventCode) && bytes.count >= 4 {
                return decodeTilt(lsb: bytes[0], msb: bytes[1])
            }
            return nil
        }
    }
    
    public static func getHubHeight() -> CommandPacket {
        return CommandPacket(opCode: .getHubHeight, message: [])
    }
    
    public static func setHubHeight(millimeters: UInt16) -> CommandPacket {
        let data = [
            UInt8(millimeters & 0xFF),
            UInt8(millimeters >> 8 & 0xFF)
        ]
        return CommandPacket(opCode: .setHubHeight, message: data)
    }
    
    public static func getWheelBase() -> CommandPacket {
        return CommandPacket(opCode: .getWheelBase, message: [])
    }
    
    public static func setWheelBase(millimeters: UInt16) -> CommandPacket {
        let data = [
            UInt8(millimeters & 0xFF),
            UInt8(millimeters >> 8 & 0xFF)
        ]
        return CommandPacket(opCode: .setWheelBase, message: data)
    }
    
    public static func getTargetTilt() -> CommandPacket {
        return CommandPacket(opCode: .getTargetTilt, message: [])
    }
    
    public static func setTargetTilt(grade: Double) -> CommandPacket {
        let targetTilt = UInt16(bitPattern: Int16(grade * 100))
        let data = [
            UInt8(targetTilt & 0xFF),
            UInt8(targetTilt >> 8 & 0xFF)
        ]
        return CommandPacket(opCode: .setTargetTilt, message: data)
    }
    
    public static func getTiltMode() -> CommandPacket {
        return CommandPacket(opCode: .getTiltMode, message: [])
    }
    
    public static func getCurrentTilt() -> CommandPacket {
        return CommandPacket(opCode: .getCurrentTilt, message: [])
    }
    
    public static func getTiltLimits() -> CommandPacket {
        return CommandPacket(opCode: .getTiltLimits, message: [])
    }
}
