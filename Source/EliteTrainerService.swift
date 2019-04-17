//
//  EliteTrainerService.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import CoreBluetooth
import SwiftySensors
import Signals

/// :nodoc:
open class EliteTrainerService: Service, ServiceProtocol {

    public static var uuid: String { return "347B0001-7635-408B-8918-8FF3949CE592" }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        ControlPoint.uuid:          ControlPoint.self,
        OutOfRange.uuid:            OutOfRange.self,
        SystemWeight.uuid:          SystemWeight.self,
        TrainerCapabilities.uuid:   TrainerCapabilities.self
    ]
    
    public var controlPoint: ControlPoint? { return characteristic() }
    public var systemWeight: SystemWeight? { return characteristic() }
    
    open class ControlPoint: Characteristic {
        
        public static var uuid: String { return "347B0010-7635-408B-8918-8FF3949CE592" }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            // TODO: Needed?
            //cbCharacteristic.notify(true)
        }
    }
    
    open class OutOfRange: Characteristic {
        
        public static var uuid: String { return "347B0011-7635-408B-8918-8FF3949CE592" }
        
        var outOfRange: Bool = false
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                if let oor = EliteTrainerSerializer.readOutOfRangeValue(value) {
                    outOfRange = oor
                }
            }
            super.valueUpdated()
        }
        
    }

    open class SystemWeight: Characteristic {
        
        public static var uuid: String { return "347B0018-7635-408B-8918-8FF3949CE592" }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
        }
    }
    
    open class TrainerCapabilities: Characteristic {
        
        public static var uuid: String { return "347B0019-7635-408B-8918-8FF3949CE592" }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
        }
    }
    
    
    
    @discardableResult open func setTargetPower(_ watts: UInt16) -> [UInt8] {
        let bytes = EliteTrainerSerializer.setTargetPower(watts)
        controlPoint?.cbCharacteristic.write(Data(bytes), writeType: ControlPoint.writeType)
        return bytes
    }
    
    @discardableResult open func setBrakeLevel(_ level: Double) -> [UInt8] {
        let bytes = EliteTrainerSerializer.setBrakeLevel(level)
        controlPoint?.cbCharacteristic.write(Data(bytes), writeType: ControlPoint.writeType)
        return bytes
    }
    
    @discardableResult open func setSimulationMode(_ grade: Double, crr: Double, wrc: Double, windSpeedKPH: Double = 0, draftingFactor: Double = 1) -> [UInt8] {
        let bytes = EliteTrainerSerializer.setSimulationMode(grade, crr: crr, wrc: wrc, windSpeedKPH: windSpeedKPH, draftingFactor: draftingFactor)
        controlPoint?.cbCharacteristic.write(Data(bytes), writeType: ControlPoint.writeType)
        return bytes
    }
    
    @discardableResult open func setRiderWeight(_ riderKG: UInt8, bikeKG: UInt8) -> [UInt8] {
        let bytes = [riderKG, bikeKG]
        systemWeight?.cbCharacteristic.write(Data(bytes), writeType: SystemWeight.writeType)
        return bytes
    }
    
}
