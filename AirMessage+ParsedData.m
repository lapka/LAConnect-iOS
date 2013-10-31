//
//  AirMessage+ParsedData.m
//  BAM
//
//  Created by Sergey Filippov on 10/31/13.
//  Copyright (c) 2013 Lapka. All rights reserved.
//

#import "AirMessage+ParsedData.h"


@implementation AirMessage (ParsedData)


- (int)pressure {
	
	return bit_array_get_word8(_data, 0);
}


- (int)alcohol {
	
	BIT_ARRAY *alcohol_bits = bit_array_create(12);
	bit_array_copy(alcohol_bits, 0, _data, 8, 12);
	int alcohol = bit_array_get_word16(alcohol_bits, 0);
	bit_array_free(alcohol_bits);
	
	return alcohol;
}


- (int)deviceID {
	
	BIT_ARRAY *device_id_bits = bit_array_create(18);
	bit_array_copy(device_id_bits, 0, _data, 2, 18);
	int deviceID = bit_array_get_word32(device_id_bits, 0);
	bit_array_free(device_id_bits);
	
	return deviceID;
}


- (int)shortDeviceID {
	
	BIT_ARRAY *short_device_id_bits = bit_array_create(6);
	bit_array_copy(short_device_id_bits, 0, _data, 2, 6);
	int shortDeviceID = bit_array_get_word8(short_device_id_bits, 0);
	bit_array_free(short_device_id_bits);
	
	return shortDeviceID;
}


- (int)batteryLevel {
	
	BIT_ARRAY *battery_bits = bit_array_create(2);
	bit_array_copy(battery_bits, 0, _data, 0, 2);
	int batteryLevel = bit_array_get_word8(battery_bits, 0);
	bit_array_free(battery_bits);
	
	return batteryLevel;
}


@end
