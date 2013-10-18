//
//  LAConnect/LAConnectManager.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LAConnectManager.h"
#import "LASessionEvent.h"
#import "Airlift.h"

#define respiteTime 5.0


NSString *const ConnectManagerDidUpdateState = @"ConnectManagerDidUpdateState";
NSString *const ConnectManagerDidFinishSessionWithMeasure = @"ConnectManagerDidFinishSessionWithMeasure";
NSString *const ConnectManagerDidFinishSessionWithDeviceID = @"ConnectManagerDidFinishSessionWithDeviceID";
NSString *const ConnectManagerDidFinishSessionWithError = @"ConnectManagerDidFinishSessionWithError";


typedef enum {
	LAMarkerID_Pressure = AirWordValue_Marker_1,
	LAMarkerID_Alcohol  = AirWordValue_Marker_2,
	LAMarkerID_DeviceID = AirWordValue_Marker_3
} LAMarkerID;


@interface LAConnectManager ()
@property (strong) NSTimer *respiteTimer;
@property (strong) NSDate *firstPressureMessageTime;
@property (strong) NSDate *lastAlcoholMessageTime;
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
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		self.session = [LASession new];
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
	printf("\nLAConnectManager sessionDidUpdateDuration: %0.1f\n", _session.duration);
}


- (void)sessionDidUpdatePressure {
	printf("\nLAConnectManager sessionDidUpdatePressure: %.0f\n", [_session pressure]);
	
	NSString *description = [NSString stringWithFormat:@"Pressure: %.0f", _session.pressure];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidUpdateAlcohol {
	printf("\nLAConnectManager sessionDidUpdateAlcohol: %.0f\n", [_session alcohol]);
	
	NSString *description = [NSString stringWithFormat:@"Alcohol: %.0f", _session.alcohol];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidUpdateDeviceID {
	
	// convert to binary string, just for log
	BIT_ARRAY *device_id_bits = bit_array_create(18);
	bit_array_set_word32(device_id_bits, 0, _session.deviceID);
	char *str = malloc(18 * sizeof(char));
	bit_array_to_str_rev(device_id_bits, str);
	bit_array_free(device_id_bits);
	
	printf("\nLAConnectManager sessionDidUpdateDeviceID: %s\n", str);
	
	NSString *description = [NSString stringWithFormat:@"DeviceID: %s (%0X)", str, _session.deviceID];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	free(str);
}


- (void)sessionDidUpdateShortDeviceID {
	
	// convert to binary string, just for log
	BIT_ARRAY *short_device_id_bits = bit_array_create(6);
	bit_array_set_word8(short_device_id_bits, 0, _session.shortDeviceID);
	char *str = malloc(6 * sizeof(char));
	bit_array_to_str_rev(short_device_id_bits, str);
	bit_array_free(short_device_id_bits);
	
	printf("\nLAConnectManager sessionDidUpdateShortDeviceID: %s\n", str);
	
	NSString *description = [NSString stringWithFormat:@"Short DeviceID: %s", str];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	free(str);
}


- (void)sessionDidUpdateBatteryLevel {
	printf("\nLAConnectManager sessionDidUpdateBatteryLevel: %d\n", [_session batteryLevel]);
	
	NSString *description = [NSString stringWithFormat:@"Battery Level: %X", _session.batteryLevel];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidFinishWithMeasure:(LAMeasure *)measure {
	NSLog(@"LAConnectManager sessionDidFinishWithMeasure");
	
	LASessionEvent *event2 = [LASessionEvent eventWithDescription:@"Session finished\n--------------------------------\n" time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event2];
	
	NSString *description = [NSString stringWithFormat:@"Your alcohol: %.0f", _session.alcohol];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	self.measure = measure;
	
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidFinishSessionWithDeviceID object:[NSNumber numberWithInt:_session.deviceID]];
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
		if (message.markerID == LAMarkerID_Pressure) {
			
			if (_firstPressureMessageTime) {
				NSTimeInterval delta = [[NSDate date] timeIntervalSinceDate:_firstPressureMessageTime];
				BOOL deltaIsInExpectedWindow = (delta > 0.15) && (delta < 0.3);
				if (deltaIsInExpectedWindow) {
					[self updateWithState:LAConnectManagerStateMeasure];
				}
			}
			self.firstPressureMessageTime = [message.time copy];
		}
	}
	
	if (self.state == LAConnectManagerStateMeasure) {
		
		if (message.markerID == LAMarkerID_Pressure) {
			
			float pressure = bit_array_get_word8(message.data, 0);
			[_session updateWithPressure:pressure];
		}
		
		if (message.markerID == LAMarkerID_Alcohol) {
			
			if (_lastAlcoholMessageTime) {
				NSTimeInterval delta = [[NSDate date] timeIntervalSinceDate:_lastAlcoholMessageTime];
				BOOL deltaIsInExpectedWindow = (delta > 0.1) && (delta < 3.3);
				if (deltaIsInExpectedWindow) {
					// refactor: incapsulate this sheat
					BIT_ARRAY *alcohol_bits = bit_array_create(12);
					BIT_ARRAY *short_device_id_bits = bit_array_create(6);
					BIT_ARRAY *battery_bits = bit_array_create(2);
					bit_array_copy(alcohol_bits, 0, message.data, 8, 12);
					bit_array_copy(short_device_id_bits, 0, message.data, 2, 6);
					bit_array_copy(battery_bits, 0, message.data, 0, 2);
					float alcohol = bit_array_get_word16(alcohol_bits, 0);
					int short_device_id = bit_array_get_word8(short_device_id_bits, 0);
					int battery_level = bit_array_get_word8(battery_bits, 0);
					bit_array_free(alcohol_bits);
					bit_array_free(short_device_id_bits);
					bit_array_free(battery_bits);
					
					[_session updateWithShortDeviceID:short_device_id];
					[_session updateWithBatteryLevel:battery_level];
					[_session updateWithAlcohol:alcohol];
				}
			}
			self.lastAlcoholMessageTime = [message.time copy];
		}
		
		if (message.markerID == LAMarkerID_DeviceID) {
			
			// refactor: incapsulate this sheat
			BIT_ARRAY *device_id_bits = bit_array_create(18);
			BIT_ARRAY *battery_bits = bit_array_create(2);
			bit_array_copy(device_id_bits, 0, message.data, 2, 18);
			bit_array_copy(battery_bits, 0, message.data, 0, 2);
			int device_id = bit_array_get_word32(device_id_bits, 0);
			int battery_level = bit_array_get_word8(battery_bits, 0);
			bit_array_free(device_id_bits);
			bit_array_free(battery_bits);
			
			[_session updateWithBatteryLevel:battery_level];
			[_session updateWithDeviceID:device_id];
		}
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
