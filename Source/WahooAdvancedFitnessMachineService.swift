//
//  WahooAdvancedFitnessMachineService.swift
//  SwiftySensorsTrainers iOS
//
//  Created by Josh Levine on 5/9/18.
//  Copyright © 2018 Kinetic. All rights reserved.
//

import CoreBluetooth
import SwiftySensors
import Signals

open class WahooAdvancedFitnessMachineService: Service, ServiceProtocol {
    
    public static var uuid: String { return "A026EE0B-0A7D-4AB3-97FA-F1500F9FEB8B" }
    
    public static var characteristicTypes: Dictionary<String, Characteristic.Type> = [
        WahooAdvancedTrainerControlPoint.uuid: WahooAdvancedTrainerControlPoint.self
    ]
    
    public var controlPoint: WahooAdvancedTrainerControlPoint? { return characteristic() }
    
    open class WahooAdvancedTrainerControlPoint: Characteristic {
        
        public static var uuid: String { return "A026E037-0A7D-4AB3-97FA-F1500F9FEB8B" }
        
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
        }
    }
    
    open func getHubHeight() {
        let command = WahooAdvancedFitnessMachineSerializer.getHubHeight()
        controlPoint?.cbCharacteristic.write(command.data, writeType: .withoutResponse)
    }
    
    open func setHubHeight(millimeters: Int) {
        let command = WahooAdvancedFitnessMachineSerializer.setHubHeight(millimeters: UInt16(millimeters))
        controlPoint?.cbCharacteristic.write(command.data, writeType: .withoutResponse)
    }
    
    open func getWheelBase() {
        let command = WahooAdvancedFitnessMachineSerializer.getHubHeight()
        controlPoint?.cbCharacteristic.write(command.data, writeType: .withoutResponse)
    }
    
    open func setWheelBase(millimeters: Int) {
        let command = WahooAdvancedFitnessMachineSerializer.setWheelBase(millimeters: UInt16(millimeters))
        controlPoint?.cbCharacteristic.write(command.data, writeType: .withoutResponse)
    }
    
    open func getTargetTilt() {
        let command = WahooAdvancedFitnessMachineSerializer.getTargetTilt()
        controlPoint?.cbCharacteristic.write(command.data, writeType: .withoutResponse)
    }
    
    open func setTargetTilt(grade: Double) {
        let command = WahooAdvancedFitnessMachineSerializer.setTargetTilt(grade: grade)
        controlPoint?.cbCharacteristic.write(command.data, writeType: .withoutResponse)
    }
    
    open func getTiltMode() {
        let command = WahooAdvancedFitnessMachineSerializer.getTiltMode()
        controlPoint?.cbCharacteristic.write(command.data, writeType: .withoutResponse)
    }
    
    open func getTiltLimits() {
        let command = WahooAdvancedFitnessMachineSerializer.getTiltLimits()
        controlPoint?.cbCharacteristic.write(command.data, writeType: .withoutResponse)
    }
}
