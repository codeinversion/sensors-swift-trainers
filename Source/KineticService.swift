//
//  KineticService.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import CoreBluetooth
import SwiftySensors

open class KineticService: Service, ServiceProtocol {
    public static var uuid: String { return "E9410300-B434-446B-B5CC-36592FC4C724" }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        Configuration.uuid:     Configuration.self,
        ControlPoint.uuid:      ControlPoint.self,
        Debug.uuid:             Debug.self,
        SystemWeight.uuid:      SystemWeight.self
    ]
    
    
    public var configuration: Configuration? { return characteristic() }
    
    public var controlPoint: ControlPoint? { return characteristic() }
    
    public var debug: Debug? { return characteristic() }
    
    public var systemWeight: SystemWeight? { return characteristic() }
    
    
    open class Configuration: Characteristic {
        public static let uuid: String = "E9410301-B434-446B-B5CC-36592FC4C724"
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.read()
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {

            }
            super.valueUpdated()
        }
    }
    
    
    open class ControlPoint: Characteristic {
        public static let uuid: String = "E9410302-B434-446B-B5CC-36592FC4C724"
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.read()
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                
            }
            super.valueUpdated()
        }
    }
    
    open class Debug: Characteristic {
        public static let uuid: String = "E9410303-B434-446B-B5CC-36592FC4C724"
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.read()
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                
            }
            super.valueUpdated()
        }
    }
    
    open class SystemWeight: Characteristic {
        public static let uuid: String = "E9410304-B434-446B-B5CC-36592FC4C724"
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.read()
        }
        
        private(set) var weight: UInt8 = 0
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value, value.count > 0 {
                value.copyBytes(to: &weight, count: 1)
            }
            super.valueUpdated()
        }
    }
}
