//
//  LAConnect/LAMessage.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "Airlift.h"


@interface LAMessage : NSObject
@property NSDate *time;
- (id)initWithAirMessage:(AirMessage *)airMessage;
@end


@interface LAStartMessage : LAMessage
@property int deviceID;
@property int batteryLevel;
- (float)batteryLevelInVolts;
@end


@interface LAMeasureMessage : LAMessage
@property float pressure;
@property float alcohol;
@end