//
//  LAConnect/LAMeasure.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LAMeasure.h"


@implementation LAMeasure


- (id)initWithAlcohol:(float)alcohol date:(NSDate *)date isAccurate:(BOOL)isAccurate {
	if ((self = [super init])) {
		_alcohol = alcohol;
		_date = date;
		_isAccurate = isAccurate;
	}
	return self;
}


@end
