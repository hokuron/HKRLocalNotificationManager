//
//  HKRLocalNotificationPropertyBuilder.m
//  HKRLocalNotificationManager
//
//  Created by hokuron on 5/12/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

NSString *const kHKRPropertyBuilderAlertAction = @"alertAction";
NSString *const kHKRPropertyBuilderAlertBody   = @"alertBody";
NSString *const kHKRPropertyBuilderFireDate    = @"fireDate";
NSString *const kHKRPropertyBuilderHasAction   = @"hasAction";
NSString *const kHKRPropertyBuilderUserInfo    = @"userInfo";

#import "HKRLocalNotificationPropertyBuilder.h"

@implementation HKRLocalNotificationPropertyBuilder

- (NSDictionary *)basicPropertiesWithDate:(NSDate *)fireDate body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo
{
    return @{kHKRPropertyBuilderFireDate:  fireDate ? fireDate : [NSNull null],
             kHKRPropertyBuilderAlertBody: alertBody,
             kHKRPropertyBuilderUserInfo:  userInfo ? userInfo : [NSNull null]
             };
}

- (NSDictionary *)basicPropertiesWithAction:(NSString *)alertAction date:(NSDate *)fireDate body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo
{
    return @{kHKRPropertyBuilderFireDate:    fireDate ? fireDate : [NSNull null],
             kHKRPropertyBuilderAlertBody:   alertBody,
             kHKRPropertyBuilderAlertAction: alertAction,
             kHKRPropertyBuilderHasAction:   @YES,
             kHKRPropertyBuilderUserInfo:    userInfo ? userInfo : [NSNull null]
             };
}

- (NSDictionary *)mergeProperty:(NSDictionary *)properties withOther:(NSDictionary *)otherProperties
{
    NSMutableDictionary *mergedProperties = otherProperties ? [otherProperties mutableCopy] : [@{} mutableCopy];
    [mergedProperties addEntriesFromDictionary:properties];
    return [mergedProperties copy];
}

@end
