//
//  LASessionEvent.h
//  AlcoDemo
//
//  Created by Sergey Filippov on 9/19/13.
//  Copyright (c) 2013 Sergey Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LASessionEvent : NSObject
@property (strong) NSString *eventDescription;
@property float time;

+ (LASessionEvent *)eventWithDescription:(NSString *)description time:(float)time;

@end
