//
//  HKRLocalNotificationManager.h
//  Example
//
//  Created by Takuma Shimizu on 5/1/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HKRLocalNotificationManager : NSObject

+ (instancetype)sharedManager;

- (UILocalNotification *)scheduleNotificationOn:(NSDate *)fireDate body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties;

- (UILocalNotification *)scheduleNotificationWithAction:(NSString *)alertAction onDate:(NSDate *)fireDate body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties;

- (UILocalNotification *)presentNotificationNowWithBody:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties;

- (UILocalNotification *)presentNotificationNowWithAction:(NSString *)alertAction body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties;

@property (nonatomic, copy) NSString *fixedSoundName;

@end


@interface UILocalNotification (HKRLocalNotificationManager)

+ (instancetype)hkr_localNotificationWithOptions:(NSDictionary *)properties;

@end
