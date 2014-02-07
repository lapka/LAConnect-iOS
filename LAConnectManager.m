//
//  LAConnect/LAConnectManager.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LAConnectManager.h"
#import "LASessionEvent.h"
#import "AirMessage+ParsedData.h"
#import "Airlift.h"

#define respiteTime 5.0

#define default_alcoholToPromille_coefficient 600
#define default_pressureCorrection_coefficient 0.025
#define default_standardPressureForCorrection 5

#define shortMessageLengthInFrames 3



NSString *const ConnectManagerDidUpdateState = @"ConnectManagerDidUpdateState";
NSString *const ConnectManagerDidFinishSessionWithMeasure = @"ConnectManagerDidFinishSessionWithMeasure";
NSString *const ConnectManagerDidFinishSessionWithDeviceID = @"ConnectManagerDidFinishSessionWithDeviceID";
NSString *const ConnectManagerDidFinishSessionWithError = @"ConnectManagerDidFinishSessionWithError";
NSString *const ConnectManagerDidUpdateSessionDuration = @"ConnectManagerDidUpdateSessionDuration";
NSString *const ConnectManagerDidUpdateBatteryLevel = @"ConnectManagerDidUpdateBatteryLevel";
NSString *const ConnectManagerDidUpdatePressure = @"ConnectManagerDidUpdatePressure";


typedef enum {
	LAMarkerID_DeviceID_part = AirWordValue_Marker_1,
	LAMarkerID_Alcohol		 = AirWordValue_Marker_2,
	LAMarkerID_DeviceID_v1   = AirWordValue_Marker_3
} LAMarkerID;


@interface LAConnectManager ()
@property (strong) NSTimer *respiteTimer;
@end




@implementation LAConnectManager


#pragma mark - Singleton


+ (LAConnectManager *)sharedManager {
	static dispatch_once_t once;
	static LAConnectManager *sharedManager;
    dispatch_once(&once, ^{
        sharedManager = [[LAConnectManager alloc] init];
    });
    return sharedManager;
}




#pragma mark - Init


- (id)init {
	if ((self = [super init])) {
		
		_airListener = [AirListener new];
		_airListener.delegate = self;
		
		_alcoholToPromilleCoefficient = default_alcoholToPromille_coefficient;
		_pressureCorrectionCoefficient = default_pressureCorrection_coefficient;
		_standardPressureForCorrection = default_standardPressureForCorrection;
	}
	return self;
}




#pragma mark - State


- (BOOL)updateWithState:(LAConnectManagerState)toState {
	
	if (toState == _state) return YES;
	LAConnectManagerState fromState = _state;
	
	// off -> ready
	if (fromState == LAConnectManagerStateOff && toState == LAConnectManagerStateReady) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener startListen];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// ready -> off
	if (fromState == LAConnectManagerStateReady && toState == LAConnectManagerStateOff) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener stopListen];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// ready -> measure
	if (fromState == LAConnectManagerStateReady && toState == LAConnectManagerStateMeasure) {
		_state = toState;
		printf("\n");
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		self.session = [LASession new];
		_session.alcoholToPromilleCoefficient = _alcoholToPromilleCoefficient;
		_session.pressureCorrectionCoefficient = _pressureCorrectionCoefficient;
		_session.standardPressureForCorrection = _standardPressureForCorrection;
		_session.framesFrequency = _airListener.airSignalProcessor.stepFrequency;
		_session.framesSinceStart = shortMessageLengthInFrames;
		_session.delegate = self;
		[_session start];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// measure -> respite
	if (fromState == LAConnectManagerStateMeasure && toState == LAConnectManagerStateRespite) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener stopListen];
		self.respiteTimer = [NSTimer scheduledTimerWithTimeInterval:respiteTime target:self selector:@selector(respiteFinish) userInfo:nil repeats:NO];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// measure -> off
	if (fromState == LAConnectManagerStateMeasure && toState == LAConnectManagerStateOff) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener stopListen];
		[_session stop];
		self.session = nil;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	NSLog(@"Warning: LAConnectManager can't update state from '%@' to '%@'", [self stateToString:fromState], [self stateToString:toState]);
	return NO;
}


- (void)respiteFinish {
	if (!_state == LAConnectManagerStateRespite) return;
	NSLog(@"respiteFinish");

	[self.respiteTimer invalidate];
	self.respiteTimer = nil;
	
	_state = LAConnectManagerStateOff;
	NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
}




#pragma mark Public methods


- (void)turnOn {
	NSLog(@"LAConnectManager turnOn");
	[self updateWithState:LAConnectManagerStateReady];
}


- (void)turnOff {
	NSLog(@"LAConnectManager turnOff");
	[self updateWithState:LAConnectManagerStateOff];
}


- (void)startMeasure {
	NSLog(@"LAConnectManager startMeasure");
	[self updateWithState:LAConnectManagerStateMeasure];
}




#pragma mark - LASessionDelegate


- (void)sessionDidStart {
	NSLog(@"LAConnectManager sessionDidStart");
	
	LASessionEvent *event = [LASessionEvent eventWithDescription:@"Session started" time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidUpdateDuration {
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateSessionDuration object:nil];
}


- (void)sessionDidUpdatePressure {
	printf("\nLAConnectManager sessionDidUpdatePressure: %d\n", [_session pressure]);
	
	NSString *description = [NSString stringWithFormat:@"Pressure: %d", _session.pressure];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdatePressure object:[NSNumber numberWithInt:_session.pressure]];
}


- (void)sessionDidUpdateAlcohol {
	printf("\nLAConnectManager sessionDidUpdateAlcohol: %d (%.2f%% BAC)\n", _session.rawAlcohol, _session.alcohol);
	
	// trace raw alcohol
	NSString *description = [NSString stringWithFormat:@"Raw alcohol: %d", _session.rawAlcohol];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	description = [NSString stringWithFormat:@"Bac: %.2f%%", _session.alcohol];
	event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidUpdateDeviceID {
	
	NSString *description = [NSString stringWithFormat:@"DeviceID: %d", _session.deviceID];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	if (_session.compositeDeviceID.isComplete && _session.compositeDeviceID.isCoincided) {
		[_session updateWithProtocolVersion:LAConnectProtocolVersion_2];
	}
}


- (void)sessionDidUpdateDeviceIDPart:(BIT_ARRAY *)deviceIDPart {
	
	char *deviceIDPart_str = malloc(sizeof(char) * deviceIDPartLength);
	bit_array_to_str_rev(deviceIDPart, deviceIDPart_str);
	uint8_t deviceIDPart_int = bit_array_get_word8(deviceIDPart, 0);
	
	NSString *description = [NSString stringWithFormat:@"DeviceID part: %s (%d)", deviceIDPart_str, deviceIDPart_int];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	free(deviceIDPart_str);
}


- (void)sessionDidUpdateBatteryLevel {
	printf("\nLAConnectManager sessionDidUpdateBatteryLevel: %d\n", [_session batteryLevel]);
	
	NSString *description = [NSString stringWithFormat:@"Battery Level: %X", _session.batteryLevel];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateBatteryLevel object:@(_session.batteryLevel)];
}


- (void)sessionDidUpdateProtocolVersion {
	printf("\nLAConnectManager sessionDidUpdateProtocolVersion: %d\n", [_session protocolVersion]);
	
	NSString *description = [NSString stringWithFormat:@"Protocol Version: #%d", _session.protocolVersion];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidFinishWithMeasure:(LAMeasure *)measure {
	NSLog(@"LAConnectManager sessionDidFinishWithMeasure");
	
	self.measure = measure;
	
	LASessionEvent *event2 = [LASessionEvent eventWithDescription:@"Session finished\n--------------------------------\n" time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event2];
	
	NSString *description = [NSString stringWithFormat:@"Your alcohol: %.2f%% BAC", _session.alcohol];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidFinishSessionWithMeasure object:measure];
	[self updateWithState:LAConnectManagerStateRespite];
	
	self.session = nil;
}


- (void)sessionDidFinishWithDeviceID {
	NSLog(@"LAConnectManager sessionDidFinishWithDeviceID");
	
	LASessionEvent *event2 = [LASessionEvent eventWithDescription:@"Session finished\n--------------------------------\n" time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event2];
	
	NSString *description = [NSString stringWithFormat:@"Your device ID: %d", _session.deviceID];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidFinishSessionWithDeviceID object:_session];
	[self updateWithState:LAConnectManagerStateRespite];
	
	self.session = nil;
}


- (void)sessionDidFinishWithError:(LAError *)error {
	NSLog(@"LAConnectManager sessionDidFinishWithError");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidFinishSessionWithError object:error];
	[self updateWithState:LAConnectManagerStateRespite];
	self.session = nil;
}




#pragma mark - AirListenerDelegate


- (void)airListenerDidReceiveMessage:(AirMessage *)message {
	
	if (self.state == LAConnectManagerStateReady) {
		if (message.markerID == LAMarkerID_DeviceID_part && message.followedBySameMarker) {
			[self updateWithState:LAConnectManagerStateMeasure];
		}
	}
	
	if (self.state == LAConnectManagerStateMeasure) {
		
		if (message.markerID == LAMarkerID_DeviceID_part) {
			[_session updateWithDeviceIDPart:message.data];
		}
		
		if (message.markerID == LAMarkerID_Alcohol) {
			
			LAConnectProtocolVersion protocolVersion = [message passedAdditionalIntegrityControl] ? LAConnectProtocolVersion_2 : LAConnectProtocolVersion_1;
			
			[_session updateWithProtocolVersion:protocolVersion];
			[_session updateWithPressure:message.pressure];
			[_session updateWithBatteryLevel:message.batteryLevel];
			[_session updateWithRawAlcohol:message.alcohol];
			
			if (protocolVersion == LAConnectProtocolVersion_2 && !message.finalPressureIsAboveAcceptableThreshold)
				[_session finishWithLowBlowError];
			else
				[_session finishWithMeasure];
		}
		
		if (message.markerID == LAMarkerID_DeviceID_v1) {
			
			[_session updateWithProtocolVersion:LAConnectProtocolVersion_1];
			[_session updateWithBatteryLevel:message.batteryLevel];
			[_session updateWithDeviceID:message.deviceID_v1];
			[_session finishWithDeviceID];
		}
	}
}


- (void)airListenerDidProcessWord {

	if (_session) {
		[_session incrementFramesCounter];
		printf("[%.0f]", _session.framesSinceStart);
	}
	
}




#pragma mark - Utilities


- (NSString *)stateToString:(LAConnectManagerState)state {
	
	switch (state) {
		case LAConnectManagerStateOff:
			return @"off";
			break;
			
		case LAConnectManagerStateReady:
			return @"ready";
			break;
			
		case LAConnectManagerStateMeasure:
			return @"measure";
			break;
			
		case LAConnectManagerStateRespite:
			return @"respite";
			break;
			
		default:
			break;
	}
}


@end
