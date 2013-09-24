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
	LAAlcoholPart_high,
	LAAlcoholPart_middle,
	LAAlcoholPart_low
} LAAlcoholPartType;


@protocol LASesionDelegate <NSObject>

- (void)sessionDidStart;
- (void)sessionDidFinishWithMeasure:(LAMeasure *)measure;
- (void)sessionDidFinishWithError:(LAError *)error;

- (void)sessionDidUpdatePressure;
- (void)sessionDidUpdateAlcohol;

@end


@interface LASession : NSObject

@property float alcohol;
@property float pressure;
@property float duration;
@property NSObject <LASesionDelegate> *delegate;

// flags
@property (readonly) BOOL pressureGotToAcceptableRange;

- (void)updateWithPressure:(float)pressure;
- (void)updateWithAlcoholPartValue:(uint8_t)alcoholPartValue forPartType:(LAAlcoholPartType)alcoholPartType;
- (void)start;
- (void)stop;

@end
