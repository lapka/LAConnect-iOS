//
//  LAConnect/LASession.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LASession.h"


@implementation LASession


- (id)initWithStartMessage:(LAStartMessage *)startMessage {
	if ((self = [super init])) {
		
		_deviceID = startMessage.deviceID;
		
	}
	return self;
}


- (void)updateWithMeasureMessage:(LAMeasureMessage *)measureMessage {
	
	_pressure = measureMessage.pressure;
	_alcohol = measureMessage.alcohol;
}

@end
