//
//  LAConnect/LADeviceID.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LADeviceID.h"


@implementation LADeviceID


- (id)init {
	if ((self = [super init])) {
		_deviceID_buffer_1 = bit_array_create(deviceIDBitsCount);
		_deviceID_buffer_2 = bit_array_create(deviceIDBitsCount);
		
		_receivedPartsCount = 0;
	}
	return self;
}


- (void)dealloc {
	bit_array_free(_deviceID_buffer_1);
	bit_array_free(_deviceID_buffer_2);
}


- (void)addDeviceIDPart:(BIT_ARRAY *)part withPartDescription:(LADeviceIDPartDescription)partDescription {
	
	if (partDescription.deviceIDIndex < 0 || partDescription.deviceIDIndex > 1) return;
	
	BIT_ARRAY *deviceID_buffer = (partDescription.deviceIDIndex == 0) ? _deviceID_buffer_1 : _deviceID_buffer_2;
	int destination_index = deviceIDBitsCount - (partDescription.partIndex + 1) * deviceIDPartLength;
	bit_array_copy(deviceID_buffer, destination_index, part, 0, deviceIDPartLength);
	
	_receivedPartsCount++;
}


- (int)intValue {
	
	int intValue = bit_array_get_word32(_deviceID_buffer_1, 0);
	return intValue;
}


- (BOOL)isCoincided {
	
	int intValue_1 = bit_array_get_word32(_deviceID_buffer_1, 0);
	int intValue_2 = bit_array_get_word32(_deviceID_buffer_2, 0);
	
	BOOL isCoincided = (intValue_1 == intValue_2);
	return isCoincided;
}


- (BOOL)isComplete {
	
	int deviceID_buffers_count = 2;
	int maxReceivedParts = deviceIDPartsPerID * deviceID_buffers_count;
	
	BOOL isComplete = (_receivedPartsCount == maxReceivedParts);
	return isComplete;
}


- (NSString *)description {
	
	char *buffer1 = malloc(sizeof(char) * deviceIDBitsCount);
	char *buffer2 = malloc(sizeof(char) * deviceIDBitsCount);
	
	bit_array_to_str_rev(_deviceID_buffer_1, buffer1);
	bit_array_to_str_rev(_deviceID_buffer_2, buffer2);
	
	char *complete = self.isComplete ? "YES" : "NO";
	char *coincided = self.isCoincided ? "YES" : "NO";
	
	NSString *description = [NSString stringWithFormat:@"<LADeviceID\n  buffer1 = %s\n  buffer2 = %s\n  complete = %s\n  coincided = %s\n  value = %d\n>", buffer1, buffer2, complete, coincided, self.intValue];
	
	free(buffer1);
	free(buffer2);
	
	return description;
}


@end
