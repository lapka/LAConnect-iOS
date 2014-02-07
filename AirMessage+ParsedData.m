//
//  AirMessage+ParsedData.m
//  BAM
//
//  Created by Sergey Filippov on 10/31/13.
//  Copyright (c) 2013 Lapka. All rights reserved.
//

#import "AirMessage+ParsedData.h"


#define framesToXORForAdditionalCRC 4
#define additionalCRCFrameIndex 1
#define frameLength 4


@implementation AirMessage (ParsedData)


- (int)deviceID_part {
	
	return bit_array_get_word8(_data, 0);
}


- (int)pressure {
	
	BIT_ARRAY *pressure_bits = bit_array_create(4);
	bit_array_copy(pressure_bits, 0, _data, 20, 4);
	int pressure = bit_array_get_word16(pressure_bits, 0);
	bit_array_free(pressure_bits);
	
	return pressure;
}


- (int)alcohol {
	
	BIT_ARRAY *alcohol_bits = bit_array_create(12);
	bit_array_copy(alcohol_bits, 0, _data, 8, 12);
	int alcohol = bit_array_get_word16(alcohol_bits, 0);
	bit_array_free(alcohol_bits);
	
	return alcohol;
}


- (int)deviceID_v1 {
	
	BIT_ARRAY *device_id_bits = bit_array_create(22);
	bit_array_copy(device_id_bits, 0, _data, 2, 22);
	int deviceID = bit_array_get_word32(device_id_bits, 0);
	bit_array_free(device_id_bits);
	
	return deviceID;
}


- (int)batteryLevel {
	
	BIT_ARRAY *battery_bits = bit_array_create(2);
	bit_array_copy(battery_bits, 0, _data, 0, 2);
	int batteryLevel = bit_array_get_word8(battery_bits, 0);
	bit_array_free(battery_bits);
	
	return batteryLevel;
}


- (BOOL)finalPressureIsAboveAcceptableThreshold {
	
	uint8_t finalPressureIsAboveAcceptableThreshold_flag = bit_array_get_bit(_data, 2);
	BOOL finalPressureIsAboveAcceptableThreshold = (finalPressureIsAboveAcceptableThreshold_flag == 1);
	
	return finalPressureIsAboveAcceptableThreshold;
}


- (BOOL)passedAdditionalIntegrityControl {
	
	printf("\n\nAdditional CRC check:\n");
	
	uint8_t calculated_crc = 0;
	
	for (int frameIndex = (longMessageLengthInFrames - 1); frameIndex > (longMessageLengthInFrames - framesToXORForAdditionalCRC - 1); frameIndex--) {
		
		BIT_ARRAY *word_array = bit_array_create(4);
		bit_array_copy(word_array, 0, _data, frameIndex * frameLength, frameLength);
		uint8_t word = bit_array_get_word8(word_array, 0);
		
		// trace word
		char *word_str = malloc(sizeof(char) * frameLength);
		bit_array_to_str_rev(word_array, word_str);
		printf("%s\n", word_str);
		free(word_str);
		
		bit_array_free(word_array);
		
		calculated_crc ^= word;
	}
	
	// trace calculated crc
	BIT_ARRAY *calculated_crc_array = bit_array_create(frameLength);
	bit_array_set_word4(calculated_crc_array, 0, calculated_crc);
	char *calculated_crc_str = malloc(sizeof(char) * frameLength);
	bit_array_to_str_rev(calculated_crc_array, calculated_crc_str);
	printf("----\n%s (calculated)\n", calculated_crc_str);
	bit_array_free(calculated_crc_array);
	free(calculated_crc_str);
	
	
	BIT_ARRAY *crc_array = bit_array_create(4);
	bit_array_copy(crc_array, 0, _data, additionalCRCFrameIndex * frameLength, frameLength);
	uint8_t received_crc = bit_array_get_word8(crc_array, 0);
	
	// trace
	char *crc_str = malloc(sizeof(char) * frameLength);
	bit_array_to_str_rev(crc_array, crc_str);
	printf("%s (received)\n\n", crc_str);
	free(crc_str);
	
	bit_array_free(crc_array);
	
	BOOL passedAdditionalIntegrityControl = (calculated_crc == received_crc);
	return passedAdditionalIntegrityControl;
}


@end
