//
//  HKRLocalNotificationManager.m
//
//  Created by Takuma Shimizu on 5/1/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

#import "HKRLocalNotificationManager.h"

#import <objc/runtime.h>

@interface HKRLocalNotificationManager ()

@property (nonatomic, strong) UIApplication *app;

@end

@implementation HKRLocalNotificationManager

#pragma mark - Instantiation

+ (instancetype)sharedManager
{
    static HKRLocalNotificationManager *manager = nil;
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
    NSDictionary *properties = @{
                                 @"fireDate" : fireDate,
                                 @"alertBody": alertBody,
                                 @"userInfo" : userInfo
                                 };
    UILocalNotification *notif = [self.class mergeAndCreateLocalNotificationWithProperties:properties options:otherProperties];
    [self.app scheduleLocalNotification:notif];
    return notif;
}

- (UILocalNotification *)scheduleNotificationWithAction:(NSString *)alertAction onDate:(NSDate *)fireDate body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties
{
    NSDictionary *properties = @{
                                 @"alertAction": alertAction,
                                 @"fireDate"   : fireDate,
                                 @"alertBody"  : alertBody,
                                 @"userInfo"   : userInfo,
                                 @"hasAction"  : @YES
                                 };
    UILocalNotification *notif = [self.class mergeAndCreateLocalNotificationWithProperties:properties options:otherProperties];
    [self.app scheduleLocalNotification:notif];
    return notif;
}

+ (UILocalNotification *)presentNotificationNowWithBody:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties
{
    NSDictionary *properties = @{
                                 @"alertBody": alertBody,
                                 @"userInfo" : userInfo
                                 };
    UILocalNotification *notif = [self mergeAndCreateLocalNotificationWithProperties:properties options:otherProperties];
    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
    return notif;
}

+ (UILocalNotification *)presentNotificationNowWithAction:(NSString *)alertAction body:(NSString *)alertBody userInfo:(NSDictionary *)userInfo options:(NSDictionary *)otherProperties
{
    NSDictionary *properties = @{
                                 @"alertBody": alertBody,
                                 @"userInfo" : userInfo,
                                 @"hasAction": @YES
                                 };
    UILocalNotification *notif = [self mergeAndCreateLocalNotificationWithProperties:properties options:otherProperties];
    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
    return notif;
}

#pragma mark - Privates

+ (UILocalNotification *)mergeAndCreateLocalNotificationWithProperties:(NSDictionary *)properties options:(NSDictionary *)otherProperties
{
    NSDictionary *options = [[HKRLocalNotificationManager sharedManager] mergeNotificationProperty:properties options:otherProperties];
    return [UILocalNotification hkr_localNotificationWithOptions:options];
}

- (NSDictionary *)mergeNotificationProperty:(NSDictionary *)properties options:(NSDictionary *)otherProperties
{
    NSMutableDictionary *mergedProperties = otherProperties ? [otherProperties mutableCopy] : [@{} mutableCopy];
    [mergedProperties addEntriesFromDictionary:properties];
    [self determineSoundNameOptionsWithOpions:mergedProperties];
    return [mergedProperties copy];
}

- (void)determineSoundNameOptionsWithOpions:(NSMutableDictionary *)options
{
    if (! [[options allKeys] containsObject:@"soundName"]) {
        options[@"soundName"] = self.defaultSoundName;
    }
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
