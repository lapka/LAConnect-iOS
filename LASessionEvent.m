//
//  LASessionEvent.m
//  AlcoDemo
//
//  Created by Sergey Filippov on 9/19/13.
//  Copyright (c) 2013 Sergey Filippov. All rights reserved.
//

#import "LASessionEvent.h"

@implementation LASessionEvent

+ (LASessionEvent *)eventWithDescription:(NSString *)description time:(float)time {
	LASessionEvent *event = [LASessionEvent new];
	event.eventDescription = description;
	event.time = time;
	return event;
}

@end
