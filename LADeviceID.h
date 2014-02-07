//
//  LAConnect/LADeviceID.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "Airlift.h"
#include "bit_array.h"


#define deviceIDBitsCount 24
#define deviceIDPartLength 4
#define deviceIDPartsPerID (deviceIDBitsCount / deviceIDPartLength)


typedef struct {
	int partIndex;
	int deviceIDIndex;
} LADeviceIDPartDescription;


@interface LADeviceID : NSObject {
	BIT_ARRAY *_deviceID_buffer_1;
	BIT_ARRAY *_deviceID_buffer_2;
}

@property (readonly) int intValue;
@property (readonly) int receivedPartsCount;

@property (readonly) BOOL isCoincided;
@property (readonly) BOOL isComplete;

- (void)addDeviceIDPart:(BIT_ARRAY *)part withPartDescription:(LADeviceIDPartDescription)partDescription;

@end
