//
//  WahooTrainerCharacteristic.swift
//  SwiftySensorsTrainers
//
//  https://github.com/kinetic-fit/sensors-swift-trainers
//
//  Copyright © 2017 Kinetic. All rights reserved.
//

import CoreBluetooth
import SwiftySensors

extension CyclingPowerService {
    
    /// Adds a Wahoo Trainer Characteristic Property to the Cycling Power Service
    public var wahooTrainer: WahooTrainer? { return characteristic() }
    
    /**
     Wahoo's Trainer Characteristic is not publicly documented.
     
     Nuances: after writing an ERG mode target watts, the trainer takes about 2 seconds for adjustments to be made.
     -> Delay all writes.
     
     Must call WahooTrainer.activate() to ensure that this characteristic will be instantiated if available on a Cycling Power Service
    */
    open class WahooTrainer: Characteristic {
        
        /// Wahoo Trainer Characteristic UUID
        public static let uuid: String = "A026E005-0A7D-4AB3-97FA-F1500F9FEB8B"
        
        /// Inserts this Characteristic's type onto the Cycling Power Service's known Characteristic types.
        public static func activate() { CyclingPowerService.characteristicTypes[uuid] = WahooTrainer.self }
        
        /**
         Initializes a Wahoo Trainer Characteristic, turns on notifications and unlocks the Trainer.
         
         - parameter service: The Cycling Power Service
         - parameter cbc: The backing CoreBluetooth Characteristic
         */
        required public init(service: Service, cbc: CBCharacteristic) {
            super.init(service: service, cbc: cbc)
            
            cbCharacteristic.notify(true)
            
            // Wahoo Trainers have to be "unlocked" before they will respond to messages
            cbCharacteristic.write(Data(bytes: WahooTrainerSerializer.unlockCommand()), writeType: .withResponse)
        }
        
        override open func valueUpdated() {
            // ToDo: ... ?
            super.valueUpdated()
        }
        
        // Minimum interval between ERG writes to the trainer to give it time to react and apply a new setting.
        private static let ErgWriteDelay: TimeInterval = 2
        
        /**
         Put the trainer into ERG mode and set the target wattage.
         This will delay the write if a write already occurred within the last `ErgWriteDelay` seconds.
         
         - parameter watts: The target wattage.
         */
        open func setResistanceErg(_ watts: UInt16) {
            ergWriteWatts = watts
            if ergWriteTimer == nil {
                writeErgWatts()
                ergWriteTimer = Timer.scheduledTimer(timeInterval: WahooTrainer.ErgWriteDelay, target: self, selector: #selector(WahooTrainer.writeErgWatts), userInfo: nil, repeats: true)
            }
        }
        
        /**
         Put the trainer into Level mode.
         
         - parameter level: The target level.
         */
        open func setResistanceLevel(_ level: UInt8) {
            ergWriteTimer?.invalidate()
            ergWriteTimer = nil
            
            cbCharacteristic.write(Data(bytes: WahooTrainerSerializer.setResistanceModeLevel(level)), writeType: .withResponse)
        }
        
        
        private var ergWriteWatts: UInt16?
        private var ergWriteTimer: Timer?
        /// Private function to execute an ERG write
        @objc func writeErgWatts() {
            if let watts = ergWriteWatts {
                // ToDo: detect if the sensor has disconnected before trying to write to it (object deallocated?)
                cbCharacteristic.write(Data(bytes: WahooTrainerSerializer.setResistanceModeErg(watts)), writeType: .withResponse)
                ergWriteWatts = nil
            } else {
                ergWriteTimer?.invalidate()
                ergWriteTimer = nil
            }
        }
    }
    
}
