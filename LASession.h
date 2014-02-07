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
- (void)sessionDidCancel;
- (void)sessionDidFinishWithMeasure:(LAMeasure *)measure;
- (void)sessionDidFinishWithDeviceID;
- (void)sessionDidFinishWithError:(LAError *)error;

- (void)sessionDidUpdateDuration;
- (void)sessionDidUpdatePressure;
- (void)sessionDidUpdateAlcohol;
- (void)sessionDidUpdateDeviceID;
- (void)sessionDidUpdateBatteryLevel;
- (void)sessionDidUpdateProtocolVersion;
- (void)sessionDidUpdateFinalPressureFlag;
- (void)sessionDidUpdateDeviceIDPart:(BIT_ARRAY *)deviceIDPart;

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
@property BOOL finalPressureIsSufficient;

@property float alcoholToPromilleCoefficient;
@property float pressureCorrectionCoefficient;
@property float standardPressureForCorrection;

// should-not-really-be-public properties
@property LAConnectProtocolVersion protocolVersion;
@property (readonly) BOOL protocolVersionIsRecognized;

- (void)start;
- (void)cancel;
- (void)finishWithMeasure;
- (void)finishWithDeviceID;
- (void)finishWithLowBlowError;
- (void)finishWithError:(LAError *)error;

- (void)updateWithPressure:(int)pressure;
- (void)updateWithRawAlcohol:(int)rawAlcohol;
- (void)updateWithDeviceID:(int)deviceID;
- (void)updateWithDeviceIDPart:(BIT_ARRAY *)deviceIDPart;
- (void)updateWithBatteryLevel:(int)batteryLevel;
- (void)updateWithProtocolVersion:(LAConnectProtocolVersion)protocolVersion;
- (void)updateWithFinalPressureFlag:(BOOL)finalPressureIsSufficient;
- (void)incrementFramesCounter;

@end
