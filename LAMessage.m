//
//  LAConnect/LAMessage.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LAMessage.h"

#define battery_level_bits_count 4
#define device_id_bits_count 20
#define pressure_bits_count 10
#define alcohol_bits_count 12

#define battery_level_bits_data_index 28
#define device_id_bits_data_index 8
#define pressure_bits_data_index 20
#define alcohol_bits_data_index 8

#define word8_length   8
#define word16_length 16
#define word32_length 32

@implementation LAMessage

- (id)initWithAirMessage:(AirMessage *)airMessage {
	if ((self = [super init])) {
		
		// this class is abstract, so nothing is here
	}
	return self;
}

@end


@implementation LAStartMessage

- (id)initWithAirMessage:(AirMessage *)airMessage {
	if ((self = [super init])) {
		
		BIT_ARRAY *data = [airMessage data];
		
		BIT_ARRAY* device_id_bits = bit_array_create(word32_length);
		BIT_ARRAY* battery_level_bits = bit_array_create(word8_length);
		
		bit_array_copy(device_id_bits, 0, data, device_id_bits_data_index, device_id_bits_count);
		bit_array_copy(battery_level_bits, 0, data, battery_level_bits_data_index, battery_level_bits_count);
		
		_deviceID = bit_array_get_word32(device_id_bits, 0);
		_batteryLevel = bit_array_get_word8(battery_level_bits, 0);
		
	}
	return self;
}

- (float)batteryLevelInVolts {
	
	float batteryLevelInVolts = _batteryLevel * 0.1 + 3.0;
	return batteryLevelInVolts;
}

@end


@implementation LAMeasureMessage

- (id)initWithAirMessage:(AirMessage *)airMessage {
	if ((self = [super init])) {
		
		BIT_ARRAY *data = [airMessage data];
		
		BIT_ARRAY* pressure_bits = bit_array_create(word16_length);
		BIT_ARRAY* alcohol_bits = bit_array_create(word16_length);
		
		bit_array_copy(pressure_bits, 0, data, pressure_bits_data_index, pressure_bits_count);
		bit_array_copy(alcohol_bits, 0, data, alcohol_bits_data_index, alcohol_bits_count);
		
		_pressure = bit_array_get_word16(pressure_bits, 0);
		_alcohol = bit_array_get_word16(alcohol_bits, 0);
	}
	return self;
}


@end