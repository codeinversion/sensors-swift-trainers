//
//  CoreBluetooth.swift
//  SwiftySensors
//
//  https://github.com/kinetic-fit/sensors-swift
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import CoreBluetooth

extension CBCharacteristic {
    
    /**
     Enable / Disable Notifications for Characteristic
     
     - parameter enabled: Notification Flag
     */
    public func notify(_ enabled: Bool) {
        service.peripheral.setNotifyValue(enabled, for: self)
    }
    
    /// Read the value of the Characteristic
    public func read() {
        service.peripheral.readValue(for: self)
    }
    
    /**
     Write Data to the Characteristic
     
     - parameter data: Data to write
     - parameter writeType: BLE Write Type
     */
    public func write(_ data: Data, writeType: CBCharacteristicWriteType) {
        service.peripheral.writeValue(data, for: self, type: writeType)
    }
    
}
