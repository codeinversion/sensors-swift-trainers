# Bike Trainers Plugin for Swifty Sensors
![iOS](https://img.shields.io/badge/iOS-8.2%2B-blue.svg)
![macOS](https://img.shields.io/badge/macOS-10.11%2B-blue.svg)
![Swift 3.0](https://img.shields.io/badge/swift-3.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
[![CocoaPods](https://cocoapod-badges.herokuapp.com/v/SwiftySensorsTrainers/badge.svg)](https://cocoapods.org/pods/SwiftySensorsTrainers)

This [Swifty Sensor](https://github.com/kinetic-fit/sensors-swift/) plugin adds Services and Characteristics for various Bike Trainers.


## Installation
### CocoaPods
```
use_frameworks!
pod 'SwiftySensors'
pod 'SwiftySensorsTrainers'
```
### Manual
Copy all of the swift files in the `Sources` directory into you project. Also copy the Headers and Libraries directories. Include the appropriate libs for your project. You may need to add some includes to the header files in your **Bridging Header** *(and create one if you don't have one)*.

### Swift Package Manager
This library is not compatible with Swift Package Manager **yet**. It relies upon some Objective C SDK libraries and Objective C libs are not supported in the SPM yet.

## Usage
When setting up your SensorManager, simply add the various Trainer Services to the scan list.
```
import SwiftySensors
import SwiftySensorsTrainers

// Customize what services you want to scan for
SensorManager.instance.setServicesToScanFor([
    CyclingPowerService.self,
    ...
    InRide2Service.self,
    SmartControlService.self,
    CycleOpsService.self
])

## Known bugs
None.

## ToDos

