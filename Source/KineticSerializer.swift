//
//  KineticSerializer.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import Foundation

/// :nodoc:
open class KineticSerializer {

    public struct KineticConfig {
        fileprivate(set) public var systemStatus: UInt16 = 0
        fileprivate(set) public var calibrationState: UInt8 = 0
        fileprivate(set) public var spindownTime: UInt16 = 0
        fileprivate(set) public var firmwareUpdateState: UInt8 = 0
        fileprivate(set) public var bleRevision: UInt8 = 0
        fileprivate(set) public var antirattleRamp: UInt8 = 0
    }
    
    public struct KineticControlPointResponse {
        fileprivate(set) public var requestCode: UInt8 = 0
        fileprivate(set) public var result: UInt8 = 0
    }
    
    public static func setDeviceName(_ deviceName: String) -> [UInt8] {
        var bytes = deviceName.utf8.map { $0 }
        bytes.insert(0x09, at: 0)
        return bytes
    }
    
    public static func readConfig(_ data: Data) -> KineticConfig? {
        let bytes = data.map { $0 }
        if bytes.count > 7 {
            var config = KineticConfig()
            config.systemStatus = UInt16(bytes[0]) | UInt16(bytes[1]) << 8
            config.calibrationState = bytes[2]
            config.spindownTime = UInt16(bytes[3]) | UInt16(bytes[4]) << 8
            config.firmwareUpdateState = bytes[5]
            config.bleRevision = bytes[6]
            config.antirattleRamp = bytes[7]
            return config
        }
        return nil
    }

    public static func readControlPointResponse(_ data: Data) -> KineticControlPointResponse? {
        let bytes = data.map { $0 }
        if bytes.count > 2 {
            var response = KineticControlPointResponse()
            response.requestCode = bytes[1]
            response.result = bytes[2]
            return response
        }
        return nil
    }
    
    public enum KineticMode: UInt8 {
        case erg = 0
        case position = 1
        case simulation = 2
    }
    
    public struct KineticDebugData {
        fileprivate(set) public var mode: KineticMode = .erg
        fileprivate(set) public var targetResistance: UInt16 = 0
        fileprivate(set) public var actualResistance: UInt16 = 0
        fileprivate(set) public var targetPosition: UInt16 = 0
        fileprivate(set) public var actualPosition: UInt16 = 0
        fileprivate(set) public var tempSensorVal: Int16 = 0
        fileprivate(set) public var tempDieVal: Int16 = 0
        fileprivate(set) public var tempCalculated: UInt16 = 0
        fileprivate(set) public var homeAccuracy: Int16 = 0
        fileprivate(set) public var bleBuild: UInt8 = 0
    }
    
    public static func readDebugData(_ data: Data) -> KineticDebugData? {
        let bytes = data.map { $0 }
        if bytes.count > 17 {
            var debugData = KineticDebugData()
            debugData.mode = KineticMode(rawValue: bytes[0]) ?? .erg
            debugData.targetResistance = UInt16(bytes[1]) | UInt16(bytes[2]) << 8
            debugData.actualResistance = UInt16(bytes[3]) | UInt16(bytes[4]) << 8
            debugData.targetPosition = UInt16(bytes[5]) | UInt16(bytes[6]) << 8
            debugData.actualPosition = UInt16(bytes[7]) | UInt16(bytes[8]) << 8
            debugData.tempSensorVal = Int16(bytes[9]) | Int16(bytes[10]) << 8
            debugData.tempDieVal = Int16(bytes[11]) | Int16(bytes[12]) << 8
            debugData.tempCalculated = UInt16(bytes[13]) | UInt16(bytes[14]) << 8
            debugData.homeAccuracy = Int16(bytes[15]) | Int16(bytes[16]) << 8
            debugData.bleBuild = bytes[17]
            return debugData
        }
        return nil
    }

    
    
    
    
    
    public class USBPacket {
        public let identifier: KineticControlUSBCharacteristic
        public let type: UInt8
        public let data: Data?
        
        init(identifier: KineticControlUSBCharacteristic, type: UInt8, data: Data?) {
            self.identifier = identifier
            self.type = type
            self.data = data
        }
    }
    
    private static let USBPacketDelimiter: UInt8 = 0xE5
    private static let USBPacketEscape: UInt8 = 0xE6
    private static let USBPacketEscapeXOR: UInt8 = 0x80
    
    public static func usbRequestRead(_ read: Bool, write: Bool, id: KineticControlUSBCharacteristic, data: Data? = nil) -> Data {
        var crcData: [UInt8] = []
        crcData.append(UInt8(id.rawValue & 0xFF))
        crcData.append(UInt8(id.rawValue >> 8 & 0xFF))
        var type: UInt8 = 0x00
        if read {
            type |= 0x01
        }
        if write {
            type |= 0x02
        }
        crcData.append(type)
        if let data = data {
            crcData.append(contentsOf: data.map { $0 })
        }
        let crc = crc8WithSeed(0, buffer: crcData, length: crcData.count)
        crcData.append(crc)
        var usbData = usbEscapeBytes(crcData)
        usbData.insert(USBPacketDelimiter, at: 0)
        usbData.append(USBPacketDelimiter)
        return usbData
    }
    
    static func usbProcessData(_ data: Data) -> [USBPacket] {
        var packets: [USBPacket] = []
        
        let bytes = data.map { $0 }
        
        var rxPacket: [UInt8] = []
        var rxLastByteWasEscape = false
        
        var index = 0
        for _ in 0 ..< bytes.count {
            if rxPacket.count == 24 && (rxLastByteWasEscape || bytes[index] != USBPacketDelimiter) {
                rxLastByteWasEscape = false
                repeat {
                    index += 1
                } while index < bytes.count && bytes[index] != USBPacketDelimiter
                if index >= bytes.count {
                    break
                }
            }
            if rxLastByteWasEscape {
                rxPacket.append(bytes[index] ^ USBPacketEscapeXOR)
                rxLastByteWasEscape = false
            } else {
                switch bytes[index] {
                case USBPacketDelimiter:
                    if rxPacket.count >= 4 {
                        if crc8WithSeed(0, buffer: rxPacket, length: rxPacket.count - 1) == rxPacket.last! {
                            let identifier = UInt16(rxPacket.removeFirst()) << 8 | UInt16(rxPacket.removeFirst())
                            if let id = KineticControlUSBCharacteristic(rawValue: identifier) {
                                let type = rxPacket.removeFirst()
                                rxPacket.removeLast()
                                var data: Data?
                                if rxPacket.count > 3 {
                                    data = Data(rxPacket)
                                }
                                packets.append(USBPacket(identifier: id, type: type, data: data))
                            }
                        }
                    }
                    rxPacket.removeAll()
                    break
                case USBPacketEscape:
                    rxLastByteWasEscape = false
                    break
                default:
                    rxPacket.append(bytes[index])
                    break
                }
            }
        }
        return packets
    }
    
    
    
    
    
    
    
    private static func usbEscapeBytes(_ bytes: [UInt8]) -> Data {
        var escaped = Data()
        var crc: UInt8 = 0
        for byte in bytes {
            let tmp = byte
            crc = crc8WithSeed(crc, buffer: [tmp], length: 1)
            if tmp == USBPacketDelimiter || tmp == USBPacketEscape {
                escaped.append(USBPacketEscape)
                escaped.append(tmp ^ USBPacketEscapeXOR)
            } else {
                escaped.append(tmp)
            }
        }
        return escaped
    }
    
    
    private static let CRC8Table: [UInt8] = [
        0x00, 0x91, 0xe3, 0x72, 0x07, 0x96, 0xe4, 0x75,
        0x0e, 0x9f, 0xed, 0x7c, 0x09, 0x98, 0xea, 0x7b,
        0x1c, 0x8d, 0xff, 0x6e, 0x1b, 0x8a, 0xf8, 0x69,
        0x12, 0x83, 0xf1, 0x60, 0x15, 0x84, 0xf6, 0x67,
        0x38, 0xa9, 0xdb, 0x4a, 0x3f, 0xae, 0xdc, 0x4d,
        0x36, 0xa7, 0xd5, 0x44, 0x31, 0xa0, 0xd2, 0x43,
        0x24, 0xb5, 0xc7, 0x56, 0x23, 0xb2, 0xc0, 0x51,
        0x2a, 0xbb, 0xc9, 0x58, 0x2d, 0xbc, 0xce, 0x5f,
        0x70, 0xe1, 0x93, 0x02, 0x77, 0xe6, 0x94, 0x05,
        0x7e, 0xef, 0x9d, 0x0c, 0x79, 0xe8, 0x9a, 0x0b,
        0x6c, 0xfd, 0x8f, 0x1e, 0x6b, 0xfa, 0x88, 0x19,
        0x62, 0xf3, 0x81, 0x10, 0x65, 0xf4, 0x86, 0x17,
        0x48, 0xd9, 0xab, 0x3a, 0x4f, 0xde, 0xac, 0x3d,
        0x46, 0xd7, 0xa5, 0x34, 0x41, 0xd0, 0xa2, 0x33,
        0x54, 0xc5, 0xb7, 0x26, 0x53, 0xc2, 0xb0, 0x21,
        0x5a, 0xcb, 0xb9, 0x28, 0x5d, 0xcc, 0xbe, 0x2f,
        0xe0, 0x71, 0x03, 0x92, 0xe7, 0x76, 0x04, 0x95,
        0xee, 0x7f, 0x0d, 0x9c, 0xe9, 0x78, 0x0a, 0x9b,
        0xfc, 0x6d, 0x1f, 0x8e, 0xfb, 0x6a, 0x18, 0x89,
        0xf2, 0x63, 0x11, 0x80, 0xf5, 0x64, 0x16, 0x87,
        0xd8, 0x49, 0x3b, 0xaa, 0xdf, 0x4e, 0x3c, 0xad,
        0xd6, 0x47, 0x35, 0xa4, 0xd1, 0x40, 0x32, 0xa3,
        0xc4, 0x55, 0x27, 0xb6, 0xc3, 0x52, 0x20, 0xb1,
        0xca, 0x5b, 0x29, 0xb8, 0xcd, 0x5c, 0x2e, 0xbf,
        0x90, 0x01, 0x73, 0xe2, 0x97, 0x06, 0x74, 0xe5,
        0x9e, 0x0f, 0x7d, 0xec, 0x99, 0x08, 0x7a, 0xeb,
        0x8c, 0x1d, 0x6f, 0xfe, 0x8b, 0x1a, 0x68, 0xf9,
        0x82, 0x13, 0x61, 0xf0, 0x85, 0x14, 0x66, 0xf7,
        0xa8, 0x39, 0x4b, 0xda, 0xaf, 0x3e, 0x4c, 0xdd,
        0xa6, 0x37, 0x45, 0xd4, 0xa1, 0x30, 0x42, 0xd3,
        0xb4, 0x25, 0x57, 0xc6, 0xb3, 0x22, 0x50, 0xc1,
        0xba, 0x2b, 0x59, 0xc8, 0xbd, 0x2c, 0x5e, 0xcf
    ]
    
    private static func hash8WithSeed(_ seed: UInt8, buffer: [UInt8], length: Int) -> UInt8 {
        var hash = seed
        for i in 0 ..< length {
            hash = CRC8Table[Int(hash ^ buffer[i])]
        }
        return hash
    }
    
    private static func crc8WithSeed(_ crc: UInt8, buffer: [UInt8], length: Int) -> UInt8 {
        return hash8WithSeed(crc ^ 0xFF, buffer: buffer, length:length) ^ 0xFF
    }
    
    
}

