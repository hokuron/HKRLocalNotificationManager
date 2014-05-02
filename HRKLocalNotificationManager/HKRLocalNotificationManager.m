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
    _fixedSoundName = UILocalNotificationDefaultSoundName;
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
    NSDictionary *options = [self.class mergeNotificationProperty:otherProperties fireDate:fireDate alertBody:alertBody userInfo:userInfo];
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:options];
    [self.app scheduleLocalNotification:notif];
    return notif;
}

#pragma mark - Privates

+ (NSDictionary *)mergeNotificationProperty:(NSDictionary *)properties fireDate:(NSDate *)fireDate alertBody:(NSString *)alertBody userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *options = properties ? [properties mutableCopy] : [@{} mutableCopy];
    if (! [[options allKeys] containsObject:@"soundName"]) {
        [options setObject:[HKRLocalNotificationManager sharedManager].fixedSoundName forKey:@"soundName"];
    }
    [options setObject:fireDate forKey:@"fireDate"];
    [options setObject:alertBody forKey:@"alertBody"];
    [options setObject:userInfo forKey:@"userInfo"];
    return [options copy];
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
            [notif setValue:obj forKey:key];
        }
    }];
    return notif;
}

@end
