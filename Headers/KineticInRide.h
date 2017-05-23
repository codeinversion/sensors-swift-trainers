//
//  KineticSDK
//

#import <Foundation/Foundation.h>

/*! UUID for the Power Service of the Kinetic inRide Sensor */
extern NSString * _Nonnull const KineticInRidePowerServiceUUID;

/*! UUID for the Power Characteristic of the Kinetic inRide Sensor */
extern NSString * _Nonnull const KineticInRidePowerServicePowerUUID;

/*! UUID for the Configuration Characteristic of the Kinetic inRide Sensor */
extern NSString * _Nonnull const KineticInRidePowerServiceConfigUUID;

/*! UUID for the Control Point Characteristic of the Kinetic inRide Sensor */
extern NSString * _Nonnull const KineticInRidePowerServiceControlPointUUID;


/*! UUID for the Device Information Service (0x180A) of the Kinetic inRide Sensor */
extern NSString * _Nonnull const KineticInRideDeviceInformationUUID;

/*! UUID for the System ID (0x2A23) of the Kinetic inRide Sensor */
extern NSString * _Nonnull const KineticInRideDeviceInformationSystemIDUUID;


/*! 1 packet every X milliseconds. */
typedef NS_ENUM (uint16_t, KineticInRideUpdateRate)
{
    /*! 1 packet / second. */
    KineticInRideUpdateRateMillis1000   = 0x20,
    /*! 2 packets / second. */
    KineticInRideUpdateRateMillis500    = 0x10,
    /*! 4 packets / second. */
    KineticInRideUpdateRateMillis250    = 0x08
};


/*!
 The Power Data will indicate what state the sensor is in. The sensor is typically in the "Normal" state.
 
 During Calibration, the state will transition through Spindown Idle, Ready, Active then back to Normal.
 */
typedef NS_ENUM (uint8_t, KineticInRideSensorState)
{
    /*! Default State. */
    KineticInRideSensorStateNormal          = 0x00,
    /*! Rider needs to accelerate to over ~20mph. */
    KineticInRideSensorStateSpindownIdle    = 0x10,
    /*! Rider shoud start coasting and NOT PEDAL (if they pedal, it will be detected and the process restarted). */
    KineticInRideSensorStateSpindownReady   = 0x20,
    /*! Coasting. Once the time interval is calculated from ~19mph to ~11mph, the time is checked. */
    KineticInRideSensorStateSpindownActive  = 0x30,
    KineticInRideSensorStateUnknown         = 0xFF
};

/*!
 The Power Data will indicate the Calibration Result (too slow, too fast, successful, "middle").
 
 The Pro Flywheel is auto-detected. It is very, very difficult to have a too slow result with a normal flywheel.
 */
typedef NS_ENUM (uint8_t, KineticInRideSensorCalibrationResult)
{
    KineticInRideSensorCalibrationResultUnknown = 0x00,
    /*! Calibration was successful. */
    KineticInRideSensorCalibrationResultSuccess = 0x01,
    /*! Rider needs to loosen the roller and restart the calibration process. */
    KineticInRideSensorCalibrationResultTooFast = 0x02,
    /*! Rider needs to tighten the roller and restart the calibration process. */
    KineticInRideSensorCalibrationResultTooSlow = 0x03,
    /*! If they have a pro flywheel, the Rider should loosen the roller. If not, they need to tighten the roller. Restart the calibration process. */
    KineticInRideSensorCalibrationResultMiddle  = 0x04
};

/*!
 The Power Data will indicate the result of the most recent Command written to the Control Point Characteristic.
 */
typedef NS_ENUM (uint8_t, KineticInRideSensorCommandResult)
{
    KineticInRideSensorCommandResultNone                = 0x00,
    /*! Command was successful. */
    KineticInRideSensorCommandResultSuccess             = 0x01,
    /*! Command is not supported by this device. */
    KineticInRideSensorCommandResultNotSupported        = 0x02,
    /*! Command is invalid. */
    KineticInRideSensorCommandResultInvalidRequest      = 0x03,
    /*! This packet contains a calibration result. */
    KineticInRideSensorCommandResultCalibrationResult   = 0x0A,
    /*! Something went terribly wrong. */
    KineticInRideSensorCommandResultUnknownError        = 0x0F
};


@interface KineticInRidePowerData: NSObject

/*! Timestamp of when this data was processed */
@property (readonly) double timestamp;

/*! Current State of the Sensor (Normal / Calibrating) */
@property (readonly) KineticInRideSensorState state;

/*! Current Power */
@property (readonly) NSInteger power;

/*! Current Speed (KPH) */
@property (readonly) double speedKPH;

/*! Current Roller RPM */
@property (readonly) double rollerRPM;

/*! Current Cadence (Virtual) */
@property (readonly) double cadenceRPM;

/*! Is the rider coasting? */
@property (readonly) bool coasting;

/*! Current Spindown Time being applied to the Power Calculation */
@property (readonly) double spindownTime;

/*! Current resistance the roller is using for Power Calculations due to tire tension => Normalized spindownTime (0..1) */
@property (readonly) double rollerResistance;

/*! Most recent Calibration Result */
@property (readonly) KineticInRideSensorCalibrationResult calibrationResult;

/*! Most recent Spidown Time (may be an invalid time) */
@property (readonly) double lastSpindownResultTime;

/*! Is a Pro Flywheel currently attached? (detected by spindown time) */
@property (readonly) bool proFlywheel;

/*! Most recent Command Result */
@property (readonly) KineticInRideSensorCommandResult commandResult;

@end


@interface KineticInRideConfigData: NSObject

/*! Is a Pro Flywheel currently attached? (detected by spindown time) */
@property (readonly) bool proFlywheel;

/*! Current Spindown Time being applied to the Power Calculation */
@property (readonly) double currentSpindownTime;

/*! Current Data Update Rate */
@property (readonly) KineticInRideUpdateRate updateRate;

@end


@interface KineticInRide: NSObject

/*!
 Deserializes the Configuration data.
 
 @param data The "value" property of the Configuration CBCharacteristic. (20 bytes)
 
 @return The current configuration of the inRide Sensor.
 */
+ (KineticInRideConfigData * _Nullable)processConfigurationData:(NSData * _Nonnull)data error:(NSError * _Nullable * _Nullable)error;

/*!
 Deserializes the Power data.
 
 @param data The "value" property of the Power CBCharacteristic. (20 bytes)
 @param systemId The "value" property of the SystemID CBCharacteristic. (6 bytes)
 
 @return The current power, speed, cadence and other properties of the inRide Sensor.
 */
+ (KineticInRidePowerData * _Nullable)processPowerData:(NSData * _Nonnull)data systemId:(NSData * _Nonnull)systemId error:(NSError * _Nullable * _Nullable)error;

/*!
 Creates the Command to start the calibration process on the inRide Sensor.
 
 @param systemId The "value" property of the SystemID CBCharacteristic. (6 bytes)
 
 @return Write this NSData to the CBPeripheral's Control Point CBCharacteristic (w/ response)
 */
+ (NSData * _Nullable)startCalibrationCommandData:(NSData * _Nonnull)systemId error:(NSError * _Nullable * _Nullable)error;

+ (double)calibrationReadySpeedKPH;

/*!
 Creates the Command to stop the calibration process on the inRide Sensor.
 
 @param systemId The "value" property of the SystemID CBCharacteristic. (6 bytes)
 
 @return Write this NSData to the CBPeripheral's Control Point CBCharacteristic (w/ response)
 */
+ (NSData * _Nullable)stopCalibrationCommandData:(NSData * _Nonnull)systemId error:(NSError * _Nullable * _Nullable)error;

/*!
 Creates the Command to change the update rate of the inRide Sensor.
 
 @param systemId The "value" property of the SystemID CBCharacteristic. (6 bytes)
 @param rate The desired update rate when in the Normal state.
 
 @return Write this NSData to the CBPeripheral's Control Point CBCharacteristic (w/ response)
 */
+ (NSData * _Nullable)configureSensorCommandData:(NSData * _Nonnull)systemId updateRate:(KineticInRideUpdateRate)rate error:(NSError * _Nullable * _Nullable)error;

/*!
 Creates the Command to change the broadcasted name of the inRide Sensor.
 
 @param systemId The "value" property of the SystemID CBCharacteristic. (6 bytes)
 @param sensorName The new sensor name. Must be between 3 and 8 characters.
 
 @return Write this NSData to the CBPeripheral's Control Point CBCharacteristic (w/ response)
 */
+ (NSData * _Nullable)setPeripheralNameCommandData:(NSData * _Nonnull)systemId name:(NSString * _Nonnull)sensorName error:(NSError * _Nullable * _Nullable)error;


/*! Utility function to convert an inRide System ID to a NSString */
+ (NSString * _Nonnull)systemIdToString:(NSData * _Nonnull)systemId;

@end
