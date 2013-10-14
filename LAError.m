//
//  LAError.m
//  AlcoDemo
//
//  Created by Sergey Filippov on 9/14/13.
//  Copyright (c) 2013 Sergey Filippov. All rights reserved.
//

#import "LAError.h"

@implementation LAError


- (NSString *)localizedDescription {
	NSString *localizedDescription;
	
	switch (self.code) {
			
		case LAErrorCodeNotEnoughPressureToStartMeasure:
			localizedDescription = NSLocalizedString(@"Not enough pressure to start measure.", "LAConnect Error Description");
			break;
			
		case LAErrorCodeNotEnoughPressureToFinishMeasure:
			localizedDescription = NSLocalizedString(@"Not enough pressure to finish measure.", "LAConnect Error Description");
			break;
			
		case LAErrorCodeMoreMissedMessagesThenAcceptable:
			localizedDescription = NSLocalizedString(@"More missed messages then acceptable.", "LAConnect Error Description");
			break;
			
		default:
			break;
	}
	
	return localizedDescription;
}


@end
