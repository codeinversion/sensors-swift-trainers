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

    public static var uuid: String { return "347B-0001–7635–408B–8918–8FF3949CE592" }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        ControlPoint.uuid:  ControlPoint.self,
        OutOfRange.uuid:    OutOfRange.self
    ]
    
    public var controlPoint: ControlPoint? { return characteristic() }
    
    open class ControlPoint: Characteristic {
        
        public static var uuid: String { return "347B-0010–7635–408B–8918–8FF3949CE592" }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            // TODO: Needed?
            //cbCharacteristic.notify(true)
        }
    }
    
    open class OutOfRange: Characteristic {
        
        public static var uuid: String { return "347B-0011–7635–408B–8918–8FF3949CE592" }
        
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

    
    open func setTargetPower(_ watts: UInt16) {
        controlPoint?.cbCharacteristic.write(Data(bytes: EliteTrainerSerializer.setTargetPower(watts)), writeType: ControlPoint.writeType)
    }
    
    open func setBrakeLevel(_ level: Double) {
        controlPoint?.cbCharacteristic.write(Data(bytes: EliteTrainerSerializer.setBrakeLevel(level)), writeType: ControlPoint.writeType)
    }
    
}
