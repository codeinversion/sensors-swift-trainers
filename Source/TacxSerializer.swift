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
        let type: FECPacketType
        let channel: UInt8
        let message: Data
    }
    
    public enum FECPacketType: UInt8 {
        case calibrationCommand  = 1
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
    
    open static func identifyPacket(_ data: Data) -> FECPacket? {
        let bytes = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
        
        let packetLength = data.count
        if data.count >= 5 {
            if bytes[0] == 0xA4 {
                let checksum = bytes[packetLength - 1]
                var packetXOR: UInt8 = 0
                for i in 0 ..< packetLength - 1 {
                    packetXOR ^= bytes[i]
                }
                if checksum == packetXOR, let type = FECPacketType(rawValue: bytes[2]) {
                    let channel = bytes[3]
                    let messageLength = Int(bytes[1])
                    let message = data.subdata(in: Range(uncheckedBounds: (4, messageLength)))
                    return FECPacket(type: type, channel: channel, message: message)
                }
            }
        }
        return nil
    }
    
    open static func readCalibrationCommand(_ data: Data) -> CalibrationResult {
        let bytes = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
        
        var result = CalibrationResult()
        result.spindownSuccess = bytes[0] & 0x01 == 0x01
        
        
        return result
    }
    
    static private let SyncByte: UInt8 = 0xA4
    static private let MessageTypeAck: UInt8 = 0x4F
    static private let DefaultChannel: UInt8 = 0x05
    
    
    open static func startCalibrationCommand(_ spindown: Bool, zeroOffset: Bool) -> [UInt8] {
        let mode: UInt8 = (spindown ? 0x40 : 0x00) | (zeroOffset ? 0x80 : 0x00)
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
