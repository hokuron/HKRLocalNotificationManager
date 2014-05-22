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
@property (nonatomic) NSMutableOrderedSet *proxyStackedNotificationsSet;
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

- (HKRLocalNotificationPropertyBuilder *)builder
{
    if (_builder) return _builder;
    _builder = [HKRLocalNotificationPropertyBuilder new];
    return _builder;
}

- (UIApplication *)app
{
    if (_app) return _app;
    _app = [UIApplication sharedApplication];
    return _app;
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
    _needsRescheduling = NO;
    [self addObserver:self forKeyPath:@"stackedNotificationsSet" options:NSKeyValueObservingOptionNew context:NULL];
    _proxyStackedNotificationsSet = [self mutableOrderedSetValueForKey:@"stackedNotificationsSet"];
    return self;
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"stackedNotificationsSet"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.needsRescheduling = [self.stackedNotificationsSet count];
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

- (void)cancelNotification:(UILocalNotification *)notification
{
    if ([self.app.scheduledLocalNotifications containsObject:notification]) {
        [self.app cancelLocalNotification:notification];
    }
    if ([self.proxyStackedNotificationsSet containsObject:notification]) {
        [self.proxyStackedNotificationsSet removeObject:notification];
    }
}

- (void)cancelAllNotifications
{
    [self.app cancelAllLocalNotifications];
    [self.proxyStackedNotificationsSet removeAllObjects];
}

+ (void)rescheduleInBackground
{
    HKRLocalNotificationManager *manager = [self sharedManager];
    __block UIBackgroundTaskIdentifier bgTask = [manager.app beginBackgroundTaskWithExpirationHandler:^{
        [manager.app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    [manager rescheduleAllLocalNotificationsIfNeeded];
    [manager.app endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}

- (void)setNeedsRescheduling
{
    self.needsRescheduling = YES;
}

- (void)rescheduleAllLocalNotificationsIfNeeded
{
    if (! self.needsRescheduling) return;
    
    [self.proxyStackedNotificationsSet addObjectsFromArray:self.app.scheduledLocalNotifications];
    [self.app cancelAllLocalNotifications];
    [self rescheduleAllLocalNotifications];
    [self.proxyStackedNotificationsSet removeAllObjects];
}

#pragma mark - Privates

- (void)scheduleLocalNotification:(UILocalNotification *)notification
{
    if (! notification.fireDate) {
        [self.app presentLocalNotificationNow:notification];
    }
    else if ([self allowsToScheduleNotificationOn:notification.fireDate]) {
        if ([self shouldStackNotification]) {
            [self.proxyStackedNotificationsSet addObject:notification];
        }
        else {
            [self.app scheduleLocalNotification:notification];
        }
    }
}

- (void)rescheduleAllLocalNotifications
{
    self.startRescheduleDate = [NSDate date];

    for (UILocalNotification *notification in self.stackedNotificationsSet) {
        if (! notification.fireDate) {
            [self.app presentLocalNotificationNow:notification];
        }
        else if ([self allowsToScheduleNotificationOn:notification.fireDate]) {
            [self.app scheduleLocalNotification:notification];
        }
    }
    
    self.startRescheduleDate = nil;
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
