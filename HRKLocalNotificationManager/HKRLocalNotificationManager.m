//
//  HKRLocalNotificationManager.m
//
//  Created by Takuma Shimizu on 5/1/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

#import "HKRLocalNotificationManager.h"

#import <objc/runtime.h>
#import "HKRLocalNotificationPropertyBuilder.h"

@interface HKRLocalNotificationManager ()

@property (nonatomic) NSMutableArray *stackedLocalNotifications;
@property (nonatomic) NSDate *startRescheduleDate;

@property (nonatomic) HKRLocalNotificationPropertyBuilder *builder;

@property (nonatomic) UIApplication *app;

@end

@implementation HKRLocalNotificationManager

#pragma mark - Instantiation

+ (instancetype)sharedManager
{
    static HKRLocalNotificationManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HKRLocalNotificationManager alloc] initSharedInstance];
    });
    return manager;
}

- (instancetype)initSharedInstance
{
    if (! (self = [super init])) return nil;
    _defaultSoundName = UILocalNotificationDefaultSoundName;
    _builder = [HKRLocalNotificationPropertyBuilder new];
    _app = [UIApplication sharedApplication];
    return self;
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - Publics

- (UILocalNotification *)scheduleNotificationOn:(NSDate *)fireDate body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties
{
    NSDictionary *properties = [self.builder basicPropertiesWithDate:fireDate body:alertBody userInfo:userInfo];
    UILocalNotification *notif = [self mergeAndScheduleLocalNotificationWithProperties:properties options:otherProperties];
    return notif;
}

- (UILocalNotification *)scheduleNotificationWithAction:(NSString *)alertAction onDate:(NSDate *)fireDate body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties
{
    NSDictionary *properties = [self.builder basicPropertiesWithAction:alertAction date:fireDate body:alertBody userInfo:userInfo];
    UILocalNotification *notif = [self mergeAndScheduleLocalNotificationWithProperties:properties options:otherProperties];
    return notif;
}

- (UILocalNotification *)presentNotificationNowWithBody:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties
{
    NSDictionary *properties = [self.builder basicPropertiesWithDate:nil body:alertBody userInfo:userInfo];
    UILocalNotification *notif = [self mergeAndScheduleLocalNotificationWithProperties:properties options:otherProperties];
    return notif;
}

- (UILocalNotification *)presentNotificationNowWithAction:(NSString *)alertAction body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties
{
    NSDictionary *properties = [self.builder basicPropertiesWithAction:alertAction date:nil body:alertBody userInfo:userInfo];
    UILocalNotification *notif = [self mergeAndScheduleLocalNotificationWithProperties:properties options:otherProperties];
    return notif;
}

#pragma mark - Privates

- (void)scheduleLocalNotifications:(id)notifications
{
    if (! [notifications isKindOfClass:[NSArray class]]) {
        notifications = @[notifications];
    }
    
    for (UILocalNotification *notif in notifications) {
        if (! notif.fireDate) {
            [self.app presentLocalNotificationNow:notif];
        }
        else if ([self allowsToScheduleNotificationOn:notif.fireDate]) {
            [self.app scheduleLocalNotification:notif];
        }
    }
}

- (UILocalNotification *)mergeAndScheduleLocalNotificationWithProperties:(NSDictionary *)properties options:(NSDictionary *)otherProperties
{
    NSDictionary *options = [self.builder mergeProperty:properties withOther:otherProperties];
    options = [self determineSoundNameForProperties:[options mutableCopy]];
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:options];
    [self scheduleLocalNotifications:notif];
    return notif;
}

- (NSDictionary *)determineSoundNameForProperties:(NSDictionary *)options
{
    NSMutableDictionary *prop = [options mutableCopy];
    if (! [[options allKeys] containsObject:@"soundName"]) {
        prop[@"soundName"] = self.defaultSoundName;
    }
    return [prop copy];
}

- (BOOL)allowsToScheduleNotificationOn:(NSDate *)fireDate
{
    NSDate *date = self.startRescheduleDate ? self.startRescheduleDate : [NSDate date];
    return [fireDate timeIntervalSinceDate:date] > 0;
}

@end

#pragma mark
#pragma mark - UILocalNotification category

@implementation UILocalNotification (HKRLocalNotificationManager)

+ (instancetype)hkr_localNotificationWithOptions:(NSDictionary *)properties
{
    UILocalNotification *notif = [UILocalNotification new];
    [properties enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (class_getProperty([notif class], [key UTF8String]) != NULL) {
            if (obj == [NSNull null]) {
                [notif setValue:nil forKey:key];
            }
            else {
                [notif setValue:obj forKey:key];
            }
        }
    }];
    return notif;
}

@end
