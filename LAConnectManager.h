//
//  LAConnect/LAConnectManager.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "LASession.h"
#import "LAMeasure.h"


extern NSString *const ConnectManagerDidUpdateState;
extern NSString *const ConnectManagerDidFinishMeasureWithMeasure;
extern NSString *const ConnectManagerDidFinishMeasureWithError;


typedef enum {
	LAConnectManagerStateOff,
	LAConnectManagerStateReady,
	LAConnectManagerStateMeasure,
	LAConnectManagerStateRespite
} LAConnectManagerState;


@interface LAConnectManager : NSObject

@property LAConnectManagerState state;
@property (strong) LASession *session;
@property (strong) LAMeasure *measure;

- (void)turnOn;
- (void)turnOff;
- (void)startMeasure;

@end
