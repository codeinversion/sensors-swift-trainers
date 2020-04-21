//
//  CyclingPowerSerializer.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import Foundation

/// :nodoc:
open class TacxSerializer {
    
    public struct FECPacket {
        public let type: FECPacketType
        public let channel: UInt8
        public let message: Data
    }
    
    public enum FECPacketType: UInt8 {
        case calibrationCommand = 1
        case calibrationStatus  = 2
        case generalFE          = 16
        case generalSettings    = 17
        case trainerData        = 25
        case basicResistance    = 48
        case targetPower        = 49
        case windResistance     = 50
        case trackResistance    = 51
        case feCapabilities     = 54
        case userConfiguration  = 55
        case requestData        = 70
        case commandStatus      = 71
        case manufactererData   = 80
        case productInformation = 81
    }
    
    public struct CalibrationResult {
        public var spindownSuccess: Bool = false
//        public var zeroOffsetCalibrationResponse
//        public var temperatureResponseDegC
//        public var zeroOffsetResponse
//        public var spinDownTimeResponseSeconds
    }
    
    public static func identifyPacket(_ data: Data) -> FECPacket? {
        let bytes = data.map { $0 }
        
        let packetLength = data.count
        if data.count >= 5 {
            if bytes[0] == 0xA4 {
                let checksum = bytes[packetLength - 1]
                var packetXOR: UInt8 = 0
                for i in 0 ..< packetLength - 1 {
                    packetXOR ^= bytes[i]
                }
                if checksum == packetXOR, let type = FECPacketType(rawValue: bytes[4]) {
                    let channel = bytes[3]
                    let messageLength = Int(bytes[1])
                    let message = data.subdata(in: Range(uncheckedBounds: (4, 4 + messageLength)))
                    return FECPacket(type: type, channel: channel, message: message)
                }
            }
        }
        return nil
    }
    
    public static func readCalibrationCommand(_ data: Data) -> CalibrationResult {
        let bytes = data.map { $0 }
        
        var result = CalibrationResult()
        result.spindownSuccess = bytes[0] & 0x01 == 0x01
        
        
        return result
    }
    
    static private let SyncByte: UInt8 = 0xA4
    static private let MessageTypeAck: UInt8 = 0x4F
    static private let DefaultChannel: UInt8 = 0x05
    
    
    static public func startCalibrationCommand(_ spindown: Bool, zeroOffset: Bool) -> [UInt8] {
        let mode: UInt8 = (spindown ? 0x80 : 0x00) | (zeroOffset ? 0x40 : 0x00)
        let message: [UInt8] = [
            DefaultChannel,
            FECPacketType.calibrationCommand.rawValue,
            mode,
            0x00,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            0xFF
        ]
        var packet = packetHeader(message.count, MessageTypeAck)
        packet.append(contentsOf: message)
        packet.append(checksum(packet))
        return packet
    }
    
    public static func sendBasicResistance(_ percent: Double) -> [UInt8] {
        let resistance = UInt8(percent * 50)    // ???
        let message: [UInt8] = [
            DefaultChannel,
            FECPacketType.basicResistance.rawValue,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            resistance
        ]
        var packet = packetHeader(message.count, MessageTypeAck)
        packet.append(contentsOf: message)
        packet.append(checksum(packet))
        return packet
    }
    
    public static func sendTargetPower(_ watts: Int16) -> [UInt8] {
        let target = Int16(Double(watts) * 4)    // ???
        let message: [UInt8] = [
            DefaultChannel,
            FECPacketType.targetPower.rawValue,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            UInt8(target & 0xFF),       // LSB
            UInt8(target >> 8 & 0xFF)   // MSB
        ]
        var packet = packetHeader(message.count, MessageTypeAck)
        packet.append(contentsOf: message)
        packet.append(checksum(packet))
        return packet
    }
    
    public static func sendWindResistance(_ cwrKgM: Double, windSpeedKPH: Double, draftingFactor: Double) -> [UInt8] {
        let cwrN = UInt8(cwrKgM / 0.01)
        let windSpeedN = UInt8(windSpeedKPH + 127.0)
        let dfN = UInt8(draftingFactor / 0.01)
        let message: [UInt8] = [
            DefaultChannel,
            FECPacketType.windResistance.rawValue,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            cwrN,
            windSpeedN,
            dfN
        ]
        var packet = packetHeader(message.count, MessageTypeAck)
        packet.append(contentsOf: message)
        packet.append(checksum(packet))
        return packet
    }
    
    static public func sendTrackResistance(_ grade: Double, crr: Double) -> [UInt8] {
        let crrN = UInt8(crr / (5 * pow(10.0, -5)))
        let gradeN = Int16((grade + 200.0) / 0.01)
        let message: [UInt8] = [
            DefaultChannel,
            FECPacketType.trackResistance.rawValue,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            UInt8(gradeN & 0xFF),
            UInt8(gradeN >> 8 & 0xFF),
            crrN
        ]
        var packet = packetHeader(message.count, MessageTypeAck)
        packet.append(contentsOf: message)
        packet.append(checksum(packet))
        return packet
    }
    
    static public func sendPageRequest(_ page: UInt8) -> [UInt8] {
        let message: [UInt8] = [
            DefaultChannel,
            FECPacketType.requestData.rawValue,
            0xFF,
            0xFF,
            0xFF,
            0xFF,
            page,
            0x01,
        ]
        var packet = packetHeader(message.count, MessageTypeAck)
        packet.append(contentsOf: message)
        packet.append(checksum(packet))
        return packet
    }
    
    static private func packetHeader(_ messageLength: Int, _ messageType: UInt8) -> [UInt8] {
        return [SyncByte, UInt8(messageLength), messageType]
    }
    
    static private func checksum(_ bytes: [UInt8]) -> UInt8 {
        var checksum: UInt8 = 0
        for i in 0 ..< bytes.count - 1 {
            checksum ^= bytes[i]
        }
        return checksum
    }
}
