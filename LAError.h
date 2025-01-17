//
//  LAError.h
//  AlcoDemo
//
//  Created by Sergey Filippov on 9/14/13.
//  Copyright (c) 2013 Sergey Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
	LAErrorCodeSessionDidFalseStart,
	LAErrorCodeSessionDidMissFinish,
	LAErrorCodeFinalPressureBelowAcceptableThreshold,
} LAErrorCode;


@interface LAError : NSError

@end
