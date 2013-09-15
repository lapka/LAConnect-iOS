//
//  LAConnect/LAConnectManager.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LAConnectManager.h"
#import "Airlift.h"


NSString *const ConnectManagerDidUpdateState = @"ConnectManagerDidUpdateState";
NSString *const ConnectManagerDidFinishMeasureWithMeasure = @"ConnectManagerDidFinishMeasureWithMeasure";
NSString *const ConnectManagerDidFinishMeasureWithError = @"ConnectManagerDidFinishMeasureWithError";


@interface LAConnectManager ()
@property (strong) AirListener *airListener;
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
		self.state = toState;
		NSLog(@"LAConnectManager state: ready");
		
		[_airListener startListen];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// ready -> measure
	if (fromState == LAConnectManagerStateReady && toState == LAConnectManagerStateMeasure) {
		self.state = toState;
		NSLog(@"LAConnectManager state: measure");
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	
	// measure -> respite
	if (fromState == LAConnectManagerStateMeasure && toState == LAConnectManagerStateRespite) {
		self.state = toState;
		NSLog(@"LAConnectManager state: respite");
		
		[_airListener stopListen];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	return NO;
}




#pragma mark Public methods


- (void)turnOn {
	
	[self updateWithState:LAConnectManagerStateReady];
}


- (void)turnOff {
	
	[self updateWithState:LAConnectManagerStateOff];
}


- (void)startMeasure {
	
	[self updateWithState:LAConnectManagerStateMeasure];
}




#pragma mark - LASessionDelegate


- (void)sessionDidStart {
	
}


- (void)sessionDidUpdate {
	
}


- (void)sessionDidFinishWithMeasure:(LAMeasure *)measure {
	
	self.measure = measure;
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidFinishMeasureWithMeasure object:measure];
	[self updateWithState:LAConnectManagerStateRespite];
	self.session = nil;
}


- (void)sessionDidFinishWithError:(LAError *)error {
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidFinishMeasureWithError object:error];
	[self updateWithState:LAConnectManagerStateRespite];
	self.session = nil;
}




#pragma mark - AirListenerDelegate


- (void)airListener:(AirListener *)airListener didReceiveMessage:(AirMessage *)message {

	if (self.state == LAConnectManagerStateReady) {
		if (!message.markerIsInverse) return;
		
		LAStartMessage *startMessage = [[LAStartMessage alloc] initWithAirMessage:message];
		self.session = [[LASession alloc] initWithStartMessage:startMessage];
		
		[self updateWithState:LAConnectManagerStateMeasure];
	}
	
	if (self.state == LAConnectManagerStateMeasure) {
		if (message.markerIsInverse) return;
		
		LAMeasureMessage *measureMessage = [[LAMeasureMessage alloc] initWithAirMessage:message];
		[_session updateWithMeasureMessage:measureMessage];
	}
}


- (void)airListenerDidLostMessage:(AirListener *)airListener {
	
}


@end
