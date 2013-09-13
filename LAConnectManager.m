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




#pragma mark - State


- (BOOL)updateWithState:(LAConnectManagerState)toState {
	
	if (toState == _state) return YES;
	LAConnectManagerState fromState = _state;
	
	// off -> ready
	if (fromState == LAConnectManagerStateOff && toState == LAConnectManagerStateReady) {
		self.state = toState;
		return YES;
	}
	
	#warning finish state machine
	
	return NO;
}




#pragma mark - State: public methods


- (void)turnOn {
	
	[self updateWithState:LAConnectManagerStateReady];
}


- (void)turnOff {
	
	[self updateWithState:LAConnectManagerStateOff];
}


- (void)startMeasure {
	
	[self updateWithState:LAConnectManagerStateMeasure];
}


@end
