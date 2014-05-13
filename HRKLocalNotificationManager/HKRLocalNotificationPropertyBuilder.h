//
//  HKRLocalNotificationPropertyBuilder.h
//  HKRLocalNotificationManager
//
//  Created by hokuron on 5/12/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HKRLocalNotificationPropertyBuilder : NSObject

- (NSDictionary *)basicPropertiesWithDate:(NSDate *)fireDate body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo;
- (NSDictionary *)basicPropertiesWithAction:(NSString *)alertAction date:(NSDate *)fireDate body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo;

- (NSDictionary *)mergeProperty:(NSDictionary *)properties withOther:(NSDictionary *)otherProperties;

@end
