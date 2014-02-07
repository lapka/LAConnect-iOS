//
//  LAConnect/LASession.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAMeasure.h"
#import "LADeviceID.h"
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

- (void)sessionDidUpdateDuration;
- (void)sessionDidUpdatePressure;
- (void)sessionDidUpdateAlcohol;
- (void)sessionDidUpdateDeviceID;
- (void)sessionDidUpdateBatteryLevel;
- (void)sessionDidUpdateProtocolVersion;

@end


@interface LASession : NSObject

@property float alcohol;
@property int rawAlcohol;
@property int pressure;
@property int deviceID;
@property int batteryLevel;
@property float duration;
@property float framesSinceStart;
@property float framesFrequency;

@property NSObject <LASesionDelegate> *delegate;
@property LADeviceID *compositeDeviceID;

@property float alcoholToPromilleCoefficient;
@property float pressureCorrectionCoefficient;
@property float standardPressureForCorrection;

// should-not-really-be-public properties
@property LAConnectProtocolVersion protocolVersion;
@property (readonly) BOOL protocolVersionIsRecognized;

- (void)updateWithPressure:(int)pressure;
- (void)updateWithRawAlcohol:(int)rawAlcohol;
- (void)updateWithDeviceID:(int)deviceID;
- (void)updateWithDeviceIDPart:(BIT_ARRAY *)deviceIDPart;
- (void)updateWithBatteryLevel:(int)batteryLevel;
- (void)updateWithProtocolVersion:(LAConnectProtocolVersion)protocolVersion;
- (void)incrementFramesCounter;
- (void)start;
- (void)stop;

- (void)restartMissedMessageTimer;

@end
