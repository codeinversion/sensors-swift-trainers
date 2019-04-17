//
//  CycleOpsService.swift
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
open class CycleOpsService: Service, ServiceProtocol {
    
    public static var uuid: String { return "C0F4013A-A837-4165-BAB9-654EF70747C6" }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        ControlPoint.uuid:  ControlPoint.self
    ]
    
    public var controlPoint: ControlPoint? { return characteristic() }
    
    open class ControlPoint: Characteristic {
        
        public static var uuid: String { return "CA31A533-A858-4DC7-A650-FDEB6DAD4C14" }
        
        public static let writeType = CBCharacteristicWriteType.withResponse
        
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
        }
        
        override open func valueUpdated() {
            if let value = cbCharacteristic.value {
                if let response = CycleOpsSerializer.readReponse(value) {
                    switch response.status {
                    case .speedOkay:
                        break
                    case .speedUp:
                        break
                    case .speedDown:
                        break
                    case .rollDownInitializing:
                        break
                    case .rollDownInProcess:
                        break
                    case .rollDownPassed:
                        break
                    case .rollDownFailed:
                        break
                    }
                }
            }
            super.valueUpdated()
        }
    }
    
    required public init(sensor: Sensor, cbs: CBService) {
        super.init(sensor: sensor, cbs: cbs)
        
        sensor.onStateChanged.subscribe(with: self) { [weak self] sensor in
            if sensor.peripheral.state == .disconnected {
                self?.updateTargetWattTimer?.invalidate()
            }
        }
    }
    
    open func setHeadlessMode() {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(CycleOpsSerializer.setControlMode(.headless)), writeType: .withResponse)
    }
    
    
    // CycleOps trainers require ~3 seconds between manual target messages
    // -- they also take 4-5 seconds for the brake to actually engage and track towared the target.
    private let MinimumWriteInterval: TimeInterval = 3
    private var updateTargetWattTimer: Timer?
    private var targetWatts: Int16?
    
    @objc private func writeTargetWatts(_ timer: Timer? = nil) {
        if let writeWatts = targetWatts, let controlPoint = controlPoint, controlPoint.cbCharacteristic.write(Data(CycleOpsSerializer.setControlMode(.manualPower, parameter1: writeWatts)), writeType: .withResponse) {
            targetWatts = nil
        } else {
            updateTargetWattTimer?.invalidate()
        }
    }
    
    open func setManualPower(_ targetWatts: Int16) {
        self.targetWatts = targetWatts
        
        if updateTargetWattTimer == nil || !updateTargetWattTimer!.isValid {
            writeTargetWatts()
            updateTargetWattTimer = Timer(timeInterval: MinimumWriteInterval, target: self, selector: #selector(writeTargetWatts(_:)), userInfo: nil, repeats: true)
            RunLoop.main.add(updateTargetWattTimer!, forMode: .common)
        }
    }
    
    // weight = kg * 100, grade = % * 10
    open func setManualSlope(_ riderWeight: Int16, _ gradePercent: Int16) {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(CycleOpsSerializer.setControlMode(.manualSlope, parameter1: riderWeight, parameter2: gradePercent)), writeType: .withResponse)
    }
    
    open func setPowerRange(_ lowerTargetWatts: Int16, _ upperTargetWatts: Int16) {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(CycleOpsSerializer.setControlMode(.powerRange, parameter1: lowerTargetWatts, parameter2: upperTargetWatts)), writeType: .withResponse)
    }
    
    open func setWarmUp() {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(CycleOpsSerializer.setControlMode(.warmUp)), writeType: .withResponse)
    }
    
    open func setRollDown() {
        updateTargetWattTimer?.invalidate()
        controlPoint?.cbCharacteristic.write(Data(CycleOpsSerializer.setControlMode(.rollDown)), writeType: .withResponse)
    }
    
    open func setWheelCircumference(_ tenthsMillimeter: UInt16) {
        
    }
    
}
