//
//  LAConnect/LAMeasure.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>


@interface LAMeasure : NSObject

@property float alcohol;
@property (strong) NSDate *date;

- (id)initWithAlcohol:(float)alcohol date:(NSDate *)date;

@end