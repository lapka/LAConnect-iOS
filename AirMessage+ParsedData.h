//
//  AirMessage+ParsedData.h
//  BAM
//
//  Created by Sergey Filippov on 10/31/13.
//  Copyright (c) 2013 Lapka. All rights reserved.
//

#import "AirListener.h"



@interface AirMessage (ParsedData)

@property (readonly) int deviceID_part;
@property (readonly) int deviceID_v1;

@property (readonly) int pressure;
@property (readonly) int alcohol;
@property (readonly) int batteryLevel;
@property (readonly) BOOL finalPressureIsSufficient;

- (BOOL)passedAdditionalIntegrityControl;

@end
