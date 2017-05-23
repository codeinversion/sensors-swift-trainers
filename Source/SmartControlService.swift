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
import Signals

open class SmartControlService: Service, ServiceProtocol {
    
    public static var uuid: String { return KineticControlPowerServiceUUID }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        Measurement.uuid:   Measurement.self,
        Configuration.uuid: Configuration.self,
        ControlPoint.uuid:  ControlPoint.self,
        DebugData.uuid:     DebugData.self
    ]
    
    public var measurement: Measurement? { return characteristic() }
    
    public var configuration: Configuration? { return characteristic() }
    
    public var controlPoint: ControlPoint? { return characteristic() }
    
    public var debugData: DebugData? { return characteristic() }
    
    
    open class Measurement: Characteristic {
        
        public static var uuid: String { return KineticControlPowerServicePowerUUID }
        
        open private(set) var powerData: KineticControlPowerData? {
            didSet {
                if let powerData = powerData, let targetWatts = (service as? SmartControlService)?.targetWatts {
                    if powerData.mode == .ERG && powerData.targetResistance != targetWatts {
                        (service as? SmartControlService)?.targetWatts = targetWatts
                    } else {
                        (service as? SmartControlService)?.targetWatts = nil
                    }
                }
            }
        }
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
            
            service.sensor.onServiceFeaturesIdentified => (service.sensor, service)
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value, let systemId = (service as? SmartControlService)?.systemId {
                do {
                    powerData = try KineticControl.processData(value, systemId: systemId)
                } catch let error as NSError {
                    SensorManager.logSensorMessage?(error.localizedDescription)
                }
            }
            super.valueUpdated()
        }
        
    }
    
    open class Configuration: Characteristic {
        
        public static var uuid: String { return KineticControlPowerServiceConfigUUID }
        
        open private(set) var configData: KineticControlConfigData?
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
            cbCharacteristic.read()
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                do {
                    configData = try KineticControl.processConfig(value)
                } catch let error as NSError {
                    SensorManager.logSensorMessage?(error.localizedDescription)
                }
            }
            super.valueUpdated()
        }
        
    }
    
    open class ControlPoint: Characteristic {
        
        public static var uuid: String { return KineticControlPowerServiceControlPointUUID }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
        }
        
    }
    
    open class DebugData: Characteristic {
        
        public static var uuid: String { return KineticControlPowerServiceDebugUUID }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
        }
        
    }
    
    public let onSystemId = Signal<Data>()
    
    private var _systemIdCache: Data? = nil
    
    public var systemId: Data? {
        if _systemIdCache == nil {
            if let sysIdChar = sensor.service(DeviceInformationService.uuid)?.characteristic(DeviceInformationService.SystemID.uuid) {
                _systemIdCache = sysIdChar.value
                if _systemIdCache == nil {
                    sysIdChar.cbCharacteristic.read()
                } else {
                    onSystemId => _systemIdCache!
                }
            }
        }
        return _systemIdCache
    }
    
    open func setResistanceFluid(_ level: UInt8) {
        targetWatts = nil
        if let controlPoint = controlPoint {
            do {
                let command = try KineticControl.setResistanceFluid(level)
                controlPoint.cbCharacteristic.write(command, writeType: .withResponse)
                SensorManager.logSensorMessage?("Setting Fluid (\(level))")
            } catch let error as NSError {
                SensorManager.logSensorMessage?(error.localizedDescription)
            }
        }
    }
    
    open func setResistanceErg(_ targetWatts: UInt16) {
        if self.targetWatts == targetWatts {
            return
        }
        self.targetWatts = targetWatts
    }
    
    open func setResistanceBrake(_ percent: Float) {
        targetWatts = nil
        if let controlPoint = controlPoint {
            do {
                let command = try KineticControl.setResistanceBrake(percent)
                controlPoint.cbCharacteristic.write(command, writeType: .withResponse)
                SensorManager.logSensorMessage?("Setting Brake (\(percent))")
            } catch let error as NSError {
                SensorManager.logSensorMessage?(error.localizedDescription)
            }
        }
    }
    
    open func setSimulationMode(_ weight:Float, rollingResistance: Float, windResistance: Float, grade: Float, windSpeed: Float) {
        targetWatts = nil
        if let controlPoint = controlPoint {
            do {
                let command = try KineticControl.setSimulationWeight(weight, rollingResistance: rollingResistance, windResistance: windResistance, grade: grade, windSpeedMPS: windSpeed)
                controlPoint.cbCharacteristic.write(command, writeType: .withResponse)
            } catch let error as NSError {
                SensorManager.logSensorMessage?(error.localizedDescription)
            }
        }
    }
    
    
    public let onCalibrationStarted = Signal<SmartControlService>()
    
    public let onCalibrationFinished = Signal<SmartControlService>()
    
    @discardableResult open func stopCalibration() -> Bool {
        onCalibrationFinished => self
        if let controlPoint = controlPoint {
            do {
                let command = try KineticControl.stopCalibration()
                controlPoint.cbCharacteristic.write(command, writeType: .withResponse)
                return true
            } catch let error as NSError {
                SensorManager.logSensorMessage?(error.localizedDescription)
            }
        }
        return false
    }
    
    @discardableResult open func startCalibration(brake: Bool = false) -> Bool {
        if let controlPoint = controlPoint {
            do {
                let command = try KineticControl.startCalibration(brake)
                controlPoint.cbCharacteristic.write(command, writeType: .withResponse)
                onCalibrationStarted => self
                return true
            } catch let error as NSError {
                SensorManager.logSensorMessage?(error.localizedDescription)
            }
        }
        return false
    }
    
    open func writeSensorName(_ deviceName: String) {
        if let controlPoint = controlPoint {
            do {
                let command = try KineticControl.setDeviceName(deviceName)
                controlPoint.cbCharacteristic.write(command, writeType: .withResponse)
            } catch let error as NSError {
                SensorManager.logSensorMessage?(error.localizedDescription)
            }
        }
    }
    
    private var targetWatts: UInt16? {
        didSet {
            if let targetWatts = targetWatts {
                if let controlPoint = controlPoint {
                    do {
                        let command = try KineticControl.setResistanceERG(targetWatts)
                        controlPoint.cbCharacteristic.write(command, writeType: .withResponse)
                        SensorManager.logSensorMessage?("Setting ERG (\(targetWatts))")
                    } catch let error as NSError {
                        SensorManager.logSensorMessage?(error.localizedDescription)
                    }
                }
            }
        }
    }
    
}
