//
//  LAConnect/LAMessage.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "Airlift.h"


typedef enum {
	LAMessageInfoByteTypeOne,
	LAMessageInfoByteTypeTwo,
	LAMessageInfoByteTypeThree
} LAMessageInfoByteType;


@interface LAMessage : NSObject

@property NSDate *time;
@property float pressure;
@property float alcohol;

@property BIT_ARRAY *infoByte;
@property LAMessageInfoByteType infoByteType;

- (id)initWithAirMessage:(AirMessage *)airMessage;

@end
