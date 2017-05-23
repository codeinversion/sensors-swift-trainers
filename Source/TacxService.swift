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
                        
                    case .basicResistance:
                        break
                        
                    case .calibrationCommand:
                        let _ = TacxSerializer.readCalibrationCommand(packet.message)
                        
                    case .calibrationStatus:
                        break
                        
                    case .commandStatus:
                        break
                        
                    case .feCapabilities:
                        break
                        
                    case .generalFE:
                        break
                        
                    case .generalSettings:
                        break
                        
                    case .manufactererData:
                        break
                        
                    case .productInformation:
                        break
                        
                    case .requestData:
                        break
                        
                    case .targetPower:
                        break
                        
                    case .trackResistance:
                        break
                        
                    case .trainerData:
                        break
                        
                    case .userConfiguration:
                        break
                        
                    case .windResistance:
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
    
    
}
