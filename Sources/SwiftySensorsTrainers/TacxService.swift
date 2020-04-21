//
//  SmartControlService.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import CoreBluetooth
import SwiftySensors

open class TacxService: Service, ServiceProtocol {
    
    public static var uuid: String { return "6E40FEC1-B5A3-F393-E0A9-E50E24DCCA9E" }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        FECRead.uuid: FECRead.self,
        FECWrite.uuid: FECWrite.self
    ]
    
    public var read: FECRead? { return characteristic() }
    
    public var write: FECWrite? { return characteristic() }
    
    open class FECRead: Characteristic {
        
        public static var uuid: String { return "6E40FEC2-B5A3-F393-E0A9-E50E24DCCA9E" }
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
            cbCharacteristic.read()
        }
        
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                if let packet = TacxSerializer.identifyPacket(value) {
                    switch packet.type {
                        
                    case .calibrationCommand:
                        let _ = TacxSerializer.readCalibrationCommand(packet.message)
                        // spindown response
                        // zero offset response
                        // temp C
                        // zero offset
                        // spindown time
                        break
                        
                    case .calibrationStatus:
                        // spindown status
                        // zero offset status
                        // speed condition
                        // temp condition
                        // temp C
                        // target speed kph
                        // target spindown time
                        break
                        
                    case .generalFE:
                        // capabilities
                        // --> virtual speed?
                        // equpiment type
                        // elapsed time
                        // distance traveled
                        // speed KPH
                        // heart rate
                        break
                        
                    case .generalSettings:
                        // cycle length
                        // incline percent
                        // resistance level percent
                        break
                        
                    case .trainerData:
                        // update event count
                        // cadence RPM
                        // accumulated power
                        // instant power
                        break
                        
                    case .basicResistance:
                        // total resistance percent
                        break
                        
                    case .targetPower:
                        // target power
                        break
                        
                    case .windResistance:
                        // cwr
                        // wind speed
                        // drafting factor
                        break
                        
                    case .trackResistance:
                        // grade
                        // crr
                        break
                        
                    case .feCapabilities:
                        // max resistance
                        // capabilities mask
                        break
                        
                    case .userConfiguration:
                        // user weight
                        // wheel diameter offset
                        // bike weight
                        // wheel diameter
                        // gear ratio
                        break
                        
                    case .requestData:
                        break
                        
                    case .commandStatus:
                        // last recieved command
                        // seq #
                        // command status
                        // extra data ...
                        break
                        
                    case .manufactererData:
                        // HW REvision
                        // Manufacturer ID
                        // Model Number
                        break
                        
                    case .productInformation:
                        // SW Revision Supplemental
                        // SW Revision Main
                        // Serial Number
                        break
                        
                    }
                }
            }
            
            super.valueUpdated()
        }
        
    }
    
    open class FECWrite: Characteristic {
        public static var uuid: String { return "6E40FEC3-B5A3-F393-E0A9-E50E24DCCA9E" }

        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
        }
        
        override open func valueUpdated() {
            if let _ = cbCharacteristic.value {
                
            }
            super.valueUpdated()
        }
    }
    
    @discardableResult open func sendWindResistance(crwKgM: Double, windSpeedKPH: Double, draftingFactor: Double) -> [UInt8] {
        let bytes = TacxSerializer.sendWindResistance(crwKgM, windSpeedKPH: windSpeedKPH, draftingFactor: draftingFactor)
        write?.cbCharacteristic.write(Data(bytes), writeType: .withResponse)
        return bytes
    }
    
    @discardableResult open func sendTrackResistance(grade: Double, crr: Double) -> [UInt8] {
        let bytes = TacxSerializer.sendTrackResistance(grade, crr: crr)
        write?.cbCharacteristic.write(Data(bytes), writeType: .withResponse)
        return bytes
    }
    
    @discardableResult open func sendTargetPower(watts: Int16) -> [UInt8] {
        let bytes = TacxSerializer.sendTargetPower(watts)
        write?.cbCharacteristic.write(Data(bytes), writeType: .withResponse)
        return bytes
    }
    
    @discardableResult open func sendBasicResistance(percent: Double) -> [UInt8] {
        let bytes = TacxSerializer.sendBasicResistance(percent)
        write?.cbCharacteristic.write(Data(bytes), writeType: .withResponse)
        return bytes
    }
    
}
