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

@property (nonatomic) BOOL needsRescheduling;
@property (nonatomic) NSMutableOrderedSet *stackedNotificationsSet;
@property (nonatomic) NSDate *startRescheduleDate;

@property (nonatomic) HKRLocalNotificationPropertyBuilder *builder;
@property (nonatomic) UIApplication *app;

@end

@implementation HKRLocalNotificationManager

#pragma mark - Getter

- (NSArray *)stackedLocalNotifications
{
    return [self.stackedNotificationsSet array];
}

- (NSMutableOrderedSet *)stackedNotificationsSet
{
    if (_stackedNotificationsSet) return _stackedNotificationsSet;
    _stackedNotificationsSet = [NSMutableOrderedSet orderedSet];
    return _stackedNotificationsSet;
}

#pragma mark - Instantiation

+ (instancetype)sharedManager
{
    static HKRLocalNotificationManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] initSharedInstance];
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

- (void)setNeedsRescheduling
{
    self.needsRescheduling = YES;
}

- (void)rescheduleAllLocalNotificationsIfNeeded
{
    if (! self.needsRescheduling) return;
    
    self.startRescheduleDate = [NSDate date];
    
    [self.stackedNotificationsSet addObjectsFromArray:self.app.scheduledLocalNotifications];
    [self.app cancelAllLocalNotifications];
    [self rescheduleAllLocalNotifications];
    [self.stackedNotificationsSet removeAllObjects];

    self.needsRescheduling = NO;
    
    self.startRescheduleDate = nil;
}

#pragma mark - Privates

- (void)scheduleLocalNotification:(UILocalNotification *)notification
{
    if (! notification.fireDate) {
        [self.app presentLocalNotificationNow:notification];
    }
    else if ([self shouldStackNotification]) {
        self.needsRescheduling = YES;
        [self.stackedNotificationsSet addObject:notification];
    }
    else if ([self allowsToScheduleNotificationOn:notification.fireDate]) {
        [self.app scheduleLocalNotification:notification];
    }
}

- (void)rescheduleAllLocalNotifications
{
    for (UILocalNotification *notification in self.stackedNotificationsSet) {
        if (! notification.fireDate) {
            [self.app presentLocalNotificationNow:notification];
        }
        else if ([self allowsToScheduleNotificationOn:notification.fireDate]) {
            [self.app scheduleLocalNotification:notification];
        }
    }
}

- (UILocalNotification *)mergeAndScheduleLocalNotificationWithProperties:(NSDictionary *)properties options:(NSDictionary *)otherProperties
{
    NSDictionary *options = [self.builder mergeProperty:properties withOther:otherProperties];
    options = [self determineSoundNameForProperties:[options mutableCopy]];
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:options];
    [self scheduleLocalNotification:notif];
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

- (BOOL)shouldStackNotification
{
    return [self.app.scheduledLocalNotifications count];
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
    UILocalNotification *notif = [self new];
    [properties enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (class_getProperty([notif class], [key UTF8String]) != NULL) {
            obj = obj == [NSNull null] ? nil : obj;
            [notif setValue:obj forKey:key];
        }
    }];
    return notif;
}

@end
