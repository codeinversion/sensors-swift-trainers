//
//  KineticSDK
//

#import <Foundation/Foundation.h>

/*! API Key Status. Defaults to Authorized. Will only be "Rejected" if explicitly disabled via the https://developer.kinetic.fit portal. */
typedef NS_ENUM (NSUInteger, KineticAPIStatus)
{
    /*! Status is unknown. SDK will continue to operate. */
    KineticAPIStatusUnknown,
    /*! API key has been Authorized or is pending Authorization. */
    KineticAPIStatusAuthorized,
    /*! API key was explicitly disabled. The SDK will return NSErrors (code 102). */
    KineticAPIStatusRejected
};

@interface KineticSDK : NSObject

/*!
 Required initialization of the SDK. Call this funcation ASAP in the Application's lifecycle.
 
 API Keys can be generated at https://developer.kinetic.fit
 
 @param apiKey API Key generated from the Developer Portal.
 */
+ (void)launch:(NSString *)apiKey;

/*! API Status */
+ (KineticAPIStatus)status;

/*! SDK Version */
+ (NSString *)version;

@end
