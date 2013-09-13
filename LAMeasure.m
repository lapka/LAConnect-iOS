//
//  LAConnect/LAMeasure.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LAMeasure.h"


@implementation LAMeasure


- (id)initWithAlcohol:(float)alcohol date:(NSDate *)date {
	if ((self = [super init])) {
		_alcohol = alcohol;
		_date = date;
	}
	return self;
}


@end
