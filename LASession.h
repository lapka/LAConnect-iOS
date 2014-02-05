//
//  LAConnect/LASession.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAMeasure.h"
#import "LAError.h"
#import "bit_array.h"


extern NSString *const ConnectManagerDidRecieveSessionEvent;


typedef enum {
	LAConnectProtocolVersionUnknown = 0,
	LAConnectProtocolVersion_1 = 1,
	LAConnectProtocolVersion_2
} LAConnectProtocolVersion;


@protocol LASesionDelegate <NSObject>

- (void)sessionDidStart;
- (void)sessionDidFinishWithMeasure:(LAMeasure *)measure;
- (void)sessionDidFinishWithDeviceID;
- (void)sessionDidFinishWithError:(LAError *)error;

- (void)sessionDidUpdateCountdown;
- (void)sessionDidUpdatePressure;
- (void)sessionDidUpdateAlcohol;
- (void)sessionDidUpdateDeviceID;
- (void)sessionDidUpdateShortDeviceID;
- (void)sessionDidUpdateBatteryLevel;
- (void)sessionDidUpdateProtocolVersion;

@end


@interface LASession : NSObject

@property float alcohol;
@property int rawAlcohol;
@property int pressure;
@property int deviceID;
@property int shortDeviceID;
@property int batteryLevel;
@property float countdown;
@property float duration; // refactor: remove since we have countdown?

@property NSObject <LASesionDelegate> *delegate;

@property float alcoholToPromilleCoefficient;
@property float pressureCorrectionCoefficient;
@property float standardPressureForCorrection;

// should-not-really-be-public properties
@property LAConnectProtocolVersion protocolVersion;
@property (readonly) BOOL protocolVersionIsRecognized;

- (void)updateWithCountdown:(float)countdown;
- (void)updateWithPressure:(int)pressure;
- (void)updateWithRawAlcohol:(int)rawAlcohol;
- (void)updateWithDeviceID:(int)deviceID;
- (void)updateWithShortDeviceID:(int)shortDeviceID;
- (void)updateWithBatteryLevel:(int)batteryLevel;
- (void)updateWithProtocolVersion:(LAConnectProtocolVersion)protocolVersion;
- (void)start;
- (void)stop;

- (void)restartMissedMessageTimer;

@end
