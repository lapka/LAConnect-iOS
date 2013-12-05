//
//  LAConnect/LASession.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAMeasure.h"
#import "LAError.h"
#import "bit_array.h"

extern NSString *const ConnectManagerDidRecieveSessionEvent;

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

- (void)updateWithCountdown:(float)countdown;
- (void)updateWithPressure:(int)pressure;
- (void)updateWithRawAlcohol:(int)rawAlcohol;
- (void)updateWithDeviceID:(int)deviceID;
- (void)updateWithShortDeviceID:(int)shortDeviceID;
- (void)updateWithBatteryLevel:(int)batteryLevel;
- (void)start;
- (void)stop;

- (void)restartMissedMessageTimer;

@end
