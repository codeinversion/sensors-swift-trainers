//
//  InRide2Service.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import CoreBluetooth
import SwiftySensors
import Signals

open class InRide2Service: Service, ServiceProtocol {
    
    public static var uuid: String { return KineticInRidePowerServiceUUID }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        Measurement.uuid:   Measurement.self,
        Configuration.uuid: Configuration.self,
        ControlPoint.uuid:  ControlPoint.self
    ]
    
    public var measurement: Measurement? { return characteristic() }
    
    public var configuration: Configuration? { return characteristic() }
    
    public var controlPoint: ControlPoint? { return characteristic() }
    
    open class Measurement: Characteristic {
        
        public static let uuid: String = KineticInRidePowerServicePowerUUID
        
        open private(set) var powerData: KineticInRidePowerData? {
            didSet {
                guard let inRide = (service as? InRide2Service) else { return }
                guard let data = powerData else { return }
                
                if data.calibrationResult == .success {
                    inRide.lastSuccessfulSpindownDuration = data.spindownTime
                }
                
                if data.state == .normal && inRide.lastSpindownDuration != data.lastSpindownResultTime {
                    inRide.lastSpindownDuration = data.lastSpindownResultTime
                    inRide.onCalibrationResult => (inRide, data.lastSpindownResultTime, data.calibrationResult)
                }
            }
        }
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
            
            service.sensor.onServiceFeaturesIdentified => (service.sensor, service)
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value, let systemId = (service as? InRide2Service)?.systemId {
                do {
                    powerData = try KineticInRide.processPowerData(value, systemId: systemId)
                } catch let error as NSError {
                    SensorManager.logSensorMessage?(error.localizedDescription)
                }
            }
            super.valueUpdated()
        }
        
    }
    
    open class Configuration: Characteristic {
        
        public static let uuid: String = KineticInRidePowerServiceConfigUUID
        
        open private(set) var configData: KineticInRideConfigData?
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.read()
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                do {
                    configData = try KineticInRide.processConfigurationData(value)
                } catch let error as NSError {
                    SensorManager.logSensorMessage?(error.localizedDescription)
                }
            }
            super.valueUpdated()
        }
        
    }
    
    open class ControlPoint: Characteristic {
        
        public static let uuid: String = KineticInRidePowerServiceControlPointUUID
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
        }
        
        override open func valueUpdated() {
            // TODO: Process this response
            super.valueUpdated()
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
    
    
    public let onCalibrationStarted = Signal<InRide2Service>()
    
    public let onCalibrationResult = Signal<(InRide2Service, Double, KineticInRideSensorCalibrationResult)>()
    
    public let onCalibrationFinished = Signal<InRide2Service>()
    
    public private(set) var lastSuccessfulSpindownDuration: Double = 0
    
    public private(set) var lastSpindownDuration: Double = 0
    
    public var lastSpindownResult: KineticInRideSensorCalibrationResult {
        return measurement?.powerData?.calibrationResult ?? .unknown
    }
    
    public var inRideState: KineticInRideSensorState {
        return measurement?.powerData?.state ?? .normal
    }
    
    @discardableResult open func stopCalibration() -> Bool {
        onCalibrationFinished => self
        if let systemId = systemId, let controlPoint = controlPoint, inRideState != .normal {
            do {
                let command = try KineticInRide.stopCalibrationCommand(systemId)
                controlPoint.cbCharacteristic.write(command, writeType: .withResponse)
                return true
            } catch let error as NSError {
                SensorManager.logSensorMessage?(error.localizedDescription)
            }
        }
        return false
    }
    
    @discardableResult open func startCalibration() -> Bool {
        if let systemId = systemId, let controlPoint = controlPoint, inRideState == .normal {
            do {
                let command = try KineticInRide.startCalibrationCommand(systemId)
                controlPoint.cbCharacteristic.write(command, writeType: .withResponse)
                onCalibrationStarted => self
                return true
            } catch let error as NSError {
                SensorManager.logSensorMessage?(error.localizedDescription)
            }
        }
        return false
    }
    
    @discardableResult open func setUpdateRate(_ rate: KineticInRideUpdateRate) -> Bool {
        guard let systemId = systemId else { return false }
        guard let controlPoint = controlPoint else { return false }
        
        do {
            let command = try KineticInRide.configureSensorCommand(systemId, updateRate: rate)
            controlPoint.cbCharacteristic.write(command, writeType: ControlPoint.writeType)
            return true
        } catch let error as NSError {
            SensorManager.logSensorMessage?(error.localizedDescription)
        }
        
        return false
    }
    
    open func writeSensorName(_ newName: String) {
        guard let systemId = systemId else { return }
        do {
            let command = try KineticInRide.setPeripheralNameCommand(systemId, name: newName)
            controlPoint?.cbCharacteristic.write(command, writeType: ControlPoint.writeType)
        } catch let error as NSError {
            SensorManager.logSensorMessage?(error.localizedDescription)
        }
    }
    
    
}

