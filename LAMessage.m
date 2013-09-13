//
//  LAConnect/LAMessage.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LAMessage.h"


@implementation LAMessage

- (id)initWithAirMessage:(AirMessage *)airMessage {
	if ((self = [super init])) {
		
		// this class is abstract, so nothing is here
	}
	return self;
}

@end


@implementation LAStartMessage

- (id)initWithAirMessage:(AirMessage *)airMessage {
	if ((self = [super init])) {
		
		#warning init start message
	}
	return self;
}

@end


@implementation LAMeasureMessage

- (id)initWithAirMessage:(AirMessage *)airMessage {
	if ((self = [super init])) {
		
		#warning init measure message
	}
	return self;
}

@end