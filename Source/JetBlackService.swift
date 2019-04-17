//
//  JetBlackService.swift
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
open class JetBlackService: Service, ServiceProtocol {
    
    public static var uuid: String { return "C4630001-003F-4CEC-8994-E489B04D857E" }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        SlowChange.uuid:    SlowChange.self,
        FastChange.uuid:    FastChange.self
    ]
    
    public var slowChange: SlowChange? { return characteristic(SlowChange.uuid) }
    public var fastChange: FastChange? { return characteristic(FastChange.uuid) }
    
    open class SlowChange: Characteristic {
        
        public static var uuid: String { return "C4632B01-003F-4CEC-8994-E489B04D857E" }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        public var data: JetBlackSerializer.SlowChangeData?
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                data = JetBlackSerializer.readSlowChange(value)
            }
            super.valueUpdated()
        }
    }
    
    open class FastChange: Characteristic {
        
        public static var uuid: String { return "C4632B02-003F-4CEC-8994-E489B04D857E" }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        public var data: JetBlackSerializer.FastChangeData?
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                data = JetBlackSerializer.readFastChange(value)
            }
            super.valueUpdated()
        }
        
    }
    
    @discardableResult open func setTargetPower(_ watts: UInt16) -> [UInt8] {
        let bytes = JetBlackSerializer.setTargetPower(watts)
        slowChange?.cbCharacteristic.write(Data(bytes), writeType: SlowChange.writeType)
        return bytes
    }
    
    @discardableResult open func setRiderWeight(_ weight: UInt16) -> [UInt8] {
        let bytes = JetBlackSerializer.setRiderWeight(weight)
        slowChange?.cbCharacteristic.write(Data(bytes), writeType: SlowChange.writeType)
        return bytes
    }
    
    @discardableResult open func setSimulationParameters(rollingResistance: Float, windResistance: Float, grade: Float, windSpeed: Float, draftingFactor: Float) -> [UInt8] {
        let bytes = JetBlackSerializer.setSimulationParameters(rollingResistance: rollingResistance,
                                                               windResistance: windResistance,
                                                               grade: grade,
                                                               windSpeed: windSpeed,
                                                               draftingFactor: draftingFactor)
        fastChange?.cbCharacteristic.write(Data(bytes), writeType: FastChange.writeType)
        return bytes
    }
}

