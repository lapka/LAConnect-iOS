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
			
		case LAErrorCodeSessionDidMissFinish:
			localizedDescription = NSLocalizedString(@"Session did miss finish.", "LAConnect Error Description");
			break;
			
		case LAErrorCodeFinalPressureBelowAcceptableThreshold:
			localizedDescription = NSLocalizedString(@"Final pressure is below acceptable threshold.", "LAConnect Error Description");
			break;
			
		case LAErrorCodeSessionDidFalseStart:
			localizedDescription = NSLocalizedString(@"Session did false start.", "LAConnect Error Description");
			break;
			
		default:
			break;
	}
	
	return localizedDescription;
}


@end
