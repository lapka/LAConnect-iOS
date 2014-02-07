//
//  LAConnect/LASession.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LASession.h"
#import "LASessionEvent.h"

#define minAcceptablePressure 3.0
#define maxAcceptablePressure 6.0
#define finishTime 10.0

#define framesPerDeviceIDParts 3

#define battery_level_info_byte_start_index 4
#define battery_level_bits_count 4
#define alcohol_bits_count 12
#define alcohol_part_bits_count 4

#define byte_length    8
#define word4_length   4
#define word8_length   8
#define word16_length 16
#define word32_length 32


NSString *const ConnectManagerDidRecieveSessionEvent = @"ConnectManagerDidRecieveSessionEvent";


@implementation LASession


#pragma mark -
#pragma mark Lifecycle


- (id)init {
	if ((self = [super init])) {
		NSLog(@"LASession init");
		
		_alcohol = 0;
		_pressure = 0;
		_duration = 0;
		_framesSinceStart = 0;
		_framesFrequency = 10;
		
		_protocolVersion = LAConnectProtocolVersionUnknown;
		_compositeDeviceID = [LADeviceID new];
	}
	return self;
}


- (void)dealloc {
	NSLog(@"LASession dealloc");
}




#pragma mark -
#pragma mark Start / Finish


- (void)start {
	NSLog(@"LASession start");
	[self.delegate sessionDidStart];
}


- (void)cancel {
	NSLog(@"LASession cancel");
	[self.delegate sessionDidCancel];
}


- (void)finishWithMeasure {
	
	LAMeasure *measure = [[LAMeasure alloc] initWithAlcohol:_alcohol date:[NSDate date]];
	[self.delegate sessionDidFinishWithMeasure:measure];
}


- (void)finishWithDeviceID {
	
	[self.delegate sessionDidFinishWithDeviceID];
}


- (void)finishWithLowBlowError {
	
	LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeFinalPressureBelowAcceptableThreshold userInfo:nil];
	[self finishWithError:error];
}


- (void)finishWithError:(LAError *)error {
	printf("\n");
	NSLog(@"LASession finishWithError: %@", [error localizedDescription]);
	
	[self.delegate sessionDidFinishWithError:error];
}




#pragma mark -
#pragma mark Update


- (void)updateWithPressure:(int)pressure {
	
	_pressure = pressure;
	[self.delegate sessionDidUpdatePressure];
}


- (void)updateWithRawAlcohol:(int)rawAlcohol {
	
	_rawAlcohol = rawAlcohol;
	_alcohol = [self bacValueFromRawAlcohol:rawAlcohol withPressure:_pressure];
	[self.delegate sessionDidUpdateAlcohol];
}


- (void)updateWithDeviceID:(int)deviceID {
	
	_deviceID = deviceID;
	[self.delegate sessionDidUpdateDeviceID];
}


- (void)updateWithDeviceIDPart:(BIT_ARRAY *)deviceIDPart {
	
	LADeviceIDPartDescription partDescription = [self deviceIDPartDescriptionForFramesSinceStart:_framesSinceStart];
	printf("\n{%d,%d}\n", partDescription.deviceIDIndex, partDescription.partIndex);
	[_compositeDeviceID addDeviceIDPart:deviceIDPart withPartDescription:partDescription];
	[self.delegate sessionDidUpdateDeviceIDPart:deviceIDPart];
	
	if (_compositeDeviceID.isComplete) {
		printf("\nCompositeDeviceID is complete\n\n%s\n\n", _compositeDeviceID.description.UTF8String);
		if (_compositeDeviceID.isCoincided) {
			[self updateWithDeviceID:_compositeDeviceID.intValue];
		}
	}
}


- (void)updateWithBatteryLevel:(int)batteryLevel {
	
	_batteryLevel = batteryLevel;
	[self.delegate sessionDidUpdateBatteryLevel];
}


- (void)updateWithProtocolVersion:(LAConnectProtocolVersion)protocolVersion {
	
	if (protocolVersion == _protocolVersion) return;
	
	_protocolVersion = protocolVersion;
	[self.delegate sessionDidUpdateProtocolVersion];
}


- (void)incrementFramesCounter {
	
	_framesSinceStart++;
	[self updateDuration];
	[self checkIfStillValid];
}


- (void)updateDuration {
	_duration = _framesSinceStart / _framesFrequency;
	[self.delegate sessionDidUpdateDuration];
}




#pragma mark -
#pragma mark Session Validation


- (void)checkIfStillValid {
	
	if (![self isStartConfirmed]) {
		
		LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeSessionDidFalseStart userInfo:nil];
		[self finishWithError:error];
		
	} else if ([self isMissedFinalMessage]) {
		
		LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeSessionDidMissFinish userInfo:nil];
		[self finishWithError:error];
	}
}


- (BOOL)isStartConfirmed {
	
	BOOL confirmed = YES;
	
	int onePartReceived = 1;
	int maximumFramesToReceiveThirdDeviceIDPart = 10;
	if (_compositeDeviceID.receivedPartsCount <= onePartReceived && _framesSinceStart > maximumFramesToReceiveThirdDeviceIDPart) {
		confirmed = NO;
	}
	
	return confirmed;
}


- (BOOL)isMissedFinalMessage {
	
	int framesPerShortMessage = 3;
	int framesPerLongMessage = 9;
	int maxShortMessagesDeviceCanSend = 13;
	int safeFramesBuffer = 2;
	
	int maxFramesToReceiveThirdFinalMessage = 3 * framesPerLongMessage + maxShortMessagesDeviceCanSend * framesPerShortMessage + safeFramesBuffer;
	int maxFramesToReceiveFifthFinalMessage = 5 * framesPerLongMessage + maxShortMessagesDeviceCanSend * framesPerShortMessage + safeFramesBuffer;
	
	int maxFramesSinceStart = (_protocolVersion == LAConnectProtocolVersion_2) ? maxFramesToReceiveThirdFinalMessage : maxFramesToReceiveFifthFinalMessage;
	
	BOOL isSessionMissedFinalMessage = (_framesSinceStart > maxFramesSinceStart);
	return isSessionMissedFinalMessage;
}




#pragma mark -
#pragma mark Protocol Version


- (BOOL)protocolVersionIsRecognized {
	
	return (_protocolVersion != LAConnectProtocolVersionUnknown);
}




#pragma mark -
#pragma mark Utilities


- (float)bacValueFromRawAlcohol:(int)rawAlcohol withPressure:(int)pressure {
	
	int RAW = rawAlcohol;
	float COEF = _alcoholToPromilleCoefficient;
	float K = _pressureCorrectionCoefficient;
	int P = _pressure;
	int P0 = _standardPressureForCorrection;
	
	float alcoholInPromille = (RAW / COEF) / (1 + K * (P - P0));
	
	float alcoholInBAC = alcoholInPromille / 10;
	return alcoholInBAC;
}


- (LADeviceIDPartDescription)deviceIDPartDescriptionForFramesSinceStart:(float)framesSinceStart {
	
	int deviceIDPartsSinceStart = round(framesSinceStart / framesPerDeviceIDParts);
	int partIndexSinceStart = deviceIDPartsSinceStart - 1;
	
	LADeviceIDPartDescription partDescription;
	partDescription.partIndex = partIndexSinceStart % deviceIDPartsPerID;
	partDescription.deviceIDIndex = floor(partIndexSinceStart / deviceIDPartsPerID);
	
	return partDescription;
}


@end
