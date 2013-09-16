//
//  LAConnect/LASession.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAMeasure.h"
#import "LAMessage.h"
#import "LAError.h"


@protocol LASesionDelegate <NSObject>

- (void)sessionDidStart;
- (void)sessionDidFinishWithMeasure:(LAMeasure *)measure;
- (void)sessionDidFinishWithError:(LAError *)error;

- (void)sessionDidUpdatePressureAndAlcohol;
- (void)sessionDidUpdateDuration;

@end


@interface LASession : NSObject

@property int deviceID;
@property float pressure;
@property float alcohol;
@property float duration;
@property NSObject <LASesionDelegate> *delegate;

// flags
@property (readonly) BOOL pressureGotToAcceptableRange;

- (id)initWithStartMessage:(LAStartMessage *)startMessage;
- (void)updateWithMeasureMessage:(LAMeasureMessage *)measureMessage;
- (void)start;

@end
