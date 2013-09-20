//
//  LAConnect/LASession.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAMeasure.h"
#import "LAMessage.h"
#import "LAError.h"

extern NSString *const ConnectManagerDidRecieveSessionEvent;


@protocol LASesionDelegate <NSObject>

- (void)sessionDidStart;
- (void)sessionDidFinishWithMeasure:(LAMeasure *)measure;
- (void)sessionDidFinishWithError:(LAError *)error;

- (void)sessionDidUpdatePressureAndAlcohol;
- (void)sessionDidRecieveDeviceID;
- (void)sessionDidRecieveBatteryLevel;
- (void)sessionDidUpdateDuration;

@end


@interface LASession : NSObject

@property int deviceID;
@property float alcohol;
@property float pressure;
@property float batteryLevel;
@property float duration;
@property NSObject <LASesionDelegate> *delegate;

// flags
@property (readonly) BOOL pressureGotToAcceptableRange;

- (void)updateWithMessage:(LAMessage *)message;
- (void)start;
- (void)stop;

@end
