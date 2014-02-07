//
//  LAConnect/LASession.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LASession.h"
#import "LASessionEvent.h"

#define minAcceptablePressure 3.0
#define maxAcceptablePressure 6.0
#define missedMessageDelay 0.3
#define maxAcceptableMissedMessagesInARow 10
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


@interface LASession ()
@property (strong) NSTimer *missedMessageTimer;
@property (strong) NSDate *startTime;
@property int missedMessagesInARow;

@end


@implementation LASession


- (id)init {
	if ((self = [super init])) {
		NSLog(@"LASession init");
		
		_alcohol = 0;
		_pressure = 0;
		_duration = 0;
		_framesSinceStart = 0;
		_framesFrequency = 10;
		
		_missedMessagesInARow = 0;
		
		_protocolVersion = LAConnectProtocolVersionUnknown;
		
		_compositeDeviceID = [LADeviceID new];
	}
	return self;
}


- (void)dealloc {
	NSLog(@"LASession dealloc");
}


- (void)start {
	NSLog(@"LASession start");
	
	[self scheduleTimers];
	self.startTime = [NSDate date];
	
	[self.delegate sessionDidStart];
}


- (void)stop {
	NSLog(@"LASession stop");
	
	[self invalidateTimers];
}


- (void)updateWithPressure:(int)pressure {
	
	[self restartMissedMessageTimer];
	_missedMessagesInARow = 0;
	
	_pressure = pressure;
	[self.delegate sessionDidUpdatePressure];
}


- (void)updateWithRawAlcohol:(int)rawAlcohol {
	
	[self restartMissedMessageTimer];
	_missedMessagesInARow = 0;
	
	_rawAlcohol = rawAlcohol;
	_alcohol = [self bacValueFromRawAlcohol:rawAlcohol withPressure:_pressure];
	[self.delegate sessionDidUpdateAlcohol];
	
	[self finishWithMeasure];
}


- (void)updateWithDeviceID:(int)deviceID {
	
	[self restartMissedMessageTimer];
	_missedMessagesInARow = 0;
	
	_deviceID = deviceID;
	[self.delegate sessionDidUpdateDeviceID];
	
	[self finishWithDeviceID];
}


- (void)updateWithDeviceIDPart:(BIT_ARRAY *)deviceIDPart {
	
	LADeviceIDPartDescription partDescription = [self deviceIDPartDescriptionForFramesSinceStart:_framesSinceStart];
	printf("\n{%d,%d}\n", partDescription.deviceIDIndex, partDescription.partIndex);
	[_compositeDeviceID addDeviceIDPart:deviceIDPart withPartDescription:partDescription];
	
	if (_compositeDeviceID.isComplete) {
		printf("\nCompositeDeviceID is complete\n%s\n", _compositeDeviceID.description.UTF8String);
	}
}


- (void)updateWithBatteryLevel:(int)batteryLevel {
	
	[self restartMissedMessageTimer];
	_missedMessagesInARow = 0;
	
	_batteryLevel = batteryLevel;
	[self.delegate sessionDidUpdateBatteryLevel];
}


- (void)updateWithProtocolVersion:(LAConnectProtocolVersion)protocolVersion {
	
	_protocolVersion = protocolVersion;
	[self.delegate sessionDidUpdateProtocolVersion];
}


- (void)incrementFramesCounter {
	
	_framesSinceStart++;
	[self updateDuration];
}


- (void)updateDuration {
	_duration = _framesSinceStart / _framesFrequency;
	[self.delegate sessionDidUpdateDuration];
}


- (void)finishWithMeasure {
	
	[self invalidateTimers];
	
	LAMeasure *measure = [[LAMeasure alloc] initWithAlcohol:_alcohol date:[NSDate date]];
	[self.delegate sessionDidFinishWithMeasure:measure];
}


- (void)finishWithDeviceID {
	
	[self invalidateTimers];
	[self.delegate sessionDidFinishWithDeviceID];
}


- (void)finishWithError:(LAError *)error {
	printf("\n");
	NSLog(@"LASession finishWithError: %@", [error localizedDescription]);
	
	[self invalidateTimers];
	[self.delegate sessionDidFinishWithError:error];
}


#pragma mark - Timers


- (void)scheduleTimers {
	
}


- (void)invalidateTimers {
	
	[self.missedMessageTimer invalidate];
	self.missedMessageTimer = nil;
}


#pragma mark - Missed Message Timer


- (void)restartMissedMessageTimer {
	// refactor: don't forget to do something about
	
	[self.missedMessageTimer invalidate];
	self.missedMessageTimer = [NSTimer scheduledTimerWithTimeInterval:missedMessageDelay target:self selector:@selector(handleMissedMessage) userInfo:nil repeats:NO];
}


- (void)handleMissedMessage {
	
	[self restartMissedMessageTimer];
	_missedMessagesInARow++;
	
	NSString *description = [NSString stringWithFormat:@"Missed message (%d)", _missedMessagesInARow];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	if (_missedMessagesInARow > maxAcceptableMissedMessagesInARow) {
		LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeMoreMissedMessagesThenAcceptable userInfo:nil];
		[self finishWithError:error];
	}
}


#pragma mark - Protocol Version


- (BOOL)protocolVersionIsRecognized {
	
	return (_protocolVersion != LAConnectProtocolVersionUnknown);
}


#pragma mark - Utilities


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
