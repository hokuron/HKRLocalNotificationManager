//
//  HKRLocalNotificationManagerTests.m
//  HKRLocalNotificationManagerTests
//
//  Created by hokuron on 5/1/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "HKRLocalNotificationManager.h"

@interface HKRLocalNotificationManagerTests : XCTestCase

@property (nonatomic, copy) NSDate         *fireDate;
@property (nonatomic, copy) NSTimeZone     *timeZone;
@property (nonatomic)       NSCalendarUnit repeatInterval;
@property (nonatomic, copy) NSCalendar     *repeatCalendar;
@property (nonatomic, copy) NSString       *alertBody;
@property (nonatomic)       BOOL           hasAction;
@property (nonatomic, copy) NSString       *alertAction;
@property (nonatomic, copy) NSString       *alertLaunchImage;
@property (nonatomic, copy) NSString       *soundName;
@property (nonatomic)       NSInteger      applicationIconBadgeNumber;
@property (nonatomic, copy) NSDictionary   *userInfo;

@end

@implementation HKRLocalNotificationManagerTests {
    NSMutableDictionary *_props;
    HKRLocalNotificationManager *_manager;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _fireDate                   = [[NSDate date] dateByAddingTimeInterval:24.0 * 60.0 * 60.0];
    _timeZone                   = [NSTimeZone localTimeZone];
    _repeatInterval             = NSCalendarUnitDay | NSCalendarUnitHour;
    _repeatCalendar             = [[NSCalendar alloc] initWithCalendarIdentifier:NSISO8601Calendar];
    _alertBody                  = @"body";
    _hasAction                  = NO;
    _alertAction                = @"action";
    _alertLaunchImage           = @"path/to/image";
    _soundName                  = @"custom_sound";
    _applicationIconBadgeNumber = 86;
    _userInfo                   = @{@"user": @"info"};

    [self buildProperties];
    
    _manager = [HKRLocalNotificationManager sharedManager];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [_props removeAllObjects];
    _manager = nil;
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [super tearDown];
}

- (NSArray *)propertyNames
{
    NSMutableArray *names = [@[] mutableCopy];
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (unsigned int idx=0; idx < count; idx += 1) {
        objc_property_t property = properties[idx];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        [names addObject:name];
    }
    return [names copy];
}

- (void)buildProperties
{
    _props = [@{} mutableCopy];
    NSArray *propNames = [self propertyNames];
    for (NSString *key in propNames) {
        [_props setObject:[self valueForKey:key] forKey:key];
    }
}

- (void)localNotificationPropertiesMatchingTestWithTarget:(UILocalNotification *)target testData:(UILocalNotification *)notif
{
    NSArray *propNames = [self propertyNames];
    for (NSString *name in propNames) {
        if ([name isEqualToString:@"soundName"]) continue;
        XCTAssertEqualObjects([target valueForKey:name], [notif valueForKey:name], @"%@ should match '%@'", name, [self valueForKey:name]);
    }
}

#pragma mark
#pragma mark - Instantiation

- (void)testSharedInstance
{
    XCTAssertEqualObjects([HKRLocalNotificationManager sharedManager], [HKRLocalNotificationManager sharedManager], @"shared instance should match");
}

- (void)testInit
{
    XCTAssertThrows([[HKRLocalNotificationManager alloc] init], @"init method should not recognize");
    XCTAssertThrows([HKRLocalNotificationManager new], @"new method should not recognize");
}

#pragma mark - testScheduleNotificationOnBodyUserInfoOptions

- (void)testScheduleNotificationOnBodyUserInfoOptions_noOptions
{
    UILocalNotification *result = [_manager scheduleNotificationOn:self.fireDate body:self.alertBody userInfo:self.userInfo options:nil];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.fireDate  = self.fireDate;
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:[[UIApplication sharedApplication].scheduledLocalNotifications firstObject]];
}

- (void)testScheduleNotificationOnBodyUserInfoOptions_addOptions
{
    NSString *alertLaunchImage = @"additional_option";
    UILocalNotification *result = [_manager scheduleNotificationOn:self.fireDate body:self.alertBody userInfo:self.userInfo options:@{@"alertLaunchImage": alertLaunchImage}];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.fireDate  = self.fireDate;
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
    notif.alertLaunchImage = alertLaunchImage;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:[[UIApplication sharedApplication].scheduledLocalNotifications firstObject]];
}

- (void)testScheduleNotificationOnBodyUserInfoOptions_overwriteArgProps
{
    NSString *alertBody = @"orverwritten_alert_body";
    UILocalNotification *result = [_manager scheduleNotificationOn:self.fireDate body:self.alertBody userInfo:self.userInfo options:@{@"alertBody": alertBody}];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.fireDate  = self.fireDate;
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:[[UIApplication sharedApplication].scheduledLocalNotifications firstObject]];
    XCTAssertNotEqualObjects(self.alertBody, alertBody, @"cannot overwrite argument properties by options");
}

- (void)testScheduleNotificationOnBodyUserInfoOptions_defaultSoundName
{
    _manager.defaultSoundName = @"defaultSoundName";
    UILocalNotification *result = [_manager scheduleNotificationOn:self.fireDate body:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertEqualObjects(result.soundName, _manager.defaultSoundName, @"if soundName is NOT specified, it should match %@", _manager.defaultSoundName);
}

- (void)testScheduleNotificationOnBodyUserInfoOptions_overwriteDefaultSoundName
{
    NSString *soundName = @"orverwritten_sound_name";
    UILocalNotification *result = [_manager scheduleNotificationOn:self.fireDate body:self.alertBody userInfo:self.userInfo options:@{@"soundName": soundName}];
    XCTAssertEqualObjects(result.soundName, soundName, @"if soundName is specified, defaultSoundName is ignored (specific soundName: %@)", soundName);
}

- (void)testScheduleNotificationOnBodyUserInfoOptions_fireDatePast
{
    UILocalNotification *result = [_manager scheduleNotificationOn:[NSDate date] body:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertNotNil(result, @"");
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"if fireDate is past, notification should NOT be scheduled");
}

#pragma mark - testScheduleNotificationWithActionOnDateBodyUserInfoOptions

- (void)testScheduleNotificationWithActionOnDateBodyUserInfoOptions_noOptions
{
    UILocalNotification *result = [_manager scheduleNotificationWithAction:self.alertAction onDate:self.fireDate body:self.alertBody userInfo:self.userInfo options:nil];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.alertAction = self.alertAction;
    notif.fireDate    = self.fireDate;
    notif.alertBody   = self.alertBody;
    notif.userInfo    = self.userInfo;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:[[UIApplication sharedApplication].scheduledLocalNotifications firstObject]];
}

- (void)testScheduleNotificationWithActionOnDateBodyUserInfoOptions_addOptions
{
    NSString *alertLaunchImage = @"additional_option";
    UILocalNotification *result = [_manager scheduleNotificationWithAction:self.alertAction onDate:self.fireDate body:self.alertBody userInfo:self.userInfo options:@{@"alertLaunchImage": alertLaunchImage}];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.alertAction = self.alertAction;
    notif.fireDate    = self.fireDate;
    notif.alertBody   = self.alertBody;
    notif.userInfo    = self.userInfo;
    notif.alertLaunchImage = alertLaunchImage;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:[[UIApplication sharedApplication].scheduledLocalNotifications firstObject]];
}

- (void)testScheduleNotificationWithActionOnDateBodyUserInfoOptions_overwriteArgProps
{
    NSString *alertBody = @"orverwritten_alert_body";
    UILocalNotification *result = [_manager scheduleNotificationWithAction:self.alertAction onDate:self.fireDate body:self.alertBody userInfo:self.userInfo options:@{@"alertBody": alertBody}];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.alertAction = self.alertAction;
    notif.fireDate    = self.fireDate;
    notif.alertBody   = self.alertBody;
    notif.userInfo    = self.userInfo;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:[[UIApplication sharedApplication].scheduledLocalNotifications firstObject]];
    XCTAssertNotEqualObjects(self.alertBody, alertBody, @"cannot overwrite argument properties by options");
}

- (void)testScheduleNotificationWithActionOnDateBodyUserInfoOptions_defaultSoundName
{
    _manager.defaultSoundName = @"defaultSoundName";
    UILocalNotification *result = [_manager scheduleNotificationWithAction:self.alertAction onDate:self.fireDate body:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertEqualObjects(result.soundName, _manager.defaultSoundName, @"if soundName is NOT specified, it should match %@", _manager.defaultSoundName);
}

- (void)testScheduleNotificationWithActionOnDateBodyUserInfoOptions_overwriteDefaultSoundName
{
    NSString *soundName = @"orverwritten_sound_name";
    UILocalNotification *result = [_manager scheduleNotificationWithAction:self.alertAction onDate:self.fireDate body:self.alertBody userInfo:self.userInfo options:@{@"soundName": soundName}];
    XCTAssertEqualObjects(result.soundName, soundName, @"if soundName is specified, defaultSoundName is ignored (specific soundName: %@)", soundName);
}

- (void)testScheduleNotificationWithActionOnDateBodyUserInfoOptions_fireDatePast
{
    UILocalNotification *result = [_manager scheduleNotificationWithAction:self.alertAction onDate:[NSDate date] body:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertNotNil(result, @"");
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"if fireDate is past, notification should NOT be scheduled");
}

#pragma mark - presentNotificationNowWithBodyUserInfoOptions

- (void)testPresentNotificationNowWithBodyUserInfoOptions
{
    UILocalNotification *result = [_manager presentNotificationNowWithBody:self.alertBody userInfo:self.userInfo options:nil];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"there is no scheduledLocalNotifications for the notification was fired right now");
}

- (void)testPresentNotificationNowWithBodyUserInfoOptions_defaultSoundName
{
    _manager.defaultSoundName = @"defaultSoundName";
    UILocalNotification *result = [_manager presentNotificationNowWithBody:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertEqualObjects(result.soundName, _manager.defaultSoundName, @"if soundName is NOT specified, it should match %@", _manager.defaultSoundName);
}

- (void)testPresentNotificationNowWithBodyUserInfoOptions_overwriteDefaultSoundName
{
    NSString *soundName = @"orverwritten_sound_name";
    UILocalNotification *result = [_manager presentNotificationNowWithBody:self.alertBody userInfo:self.userInfo options:@{@"soundName": soundName}];
    XCTAssertEqualObjects(result.soundName, soundName, @"if soundName is specified, defaultSoundName is ignored (specific soundName: %@)", soundName);
}

#pragma mark - presentNotificationNowWithActionBodyUserInfoOptions

- (void)testPresentNotificationNowWithActionBodyUserInfoOptions
{
    UILocalNotification *result = [_manager presentNotificationNowWithAction:self.alertAction body:self.alertBody userInfo:self.userInfo options:nil];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.alertAction = self.alertAction;
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"there is no scheduledLocalNotifications for the notification was fired right now");
}

- (void)testPresentNotificationNowWithActionBodyUserInfoOptions_defaultSoundName
{
    _manager.defaultSoundName = @"defaultSoundName";
    UILocalNotification *result = [_manager presentNotificationNowWithAction:self.alertAction body:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertEqualObjects(result.soundName, _manager.defaultSoundName, @"if soundName is NOT specified, it should match %@", _manager.defaultSoundName);
}

- (void)testPresentNotificationNowWithActionBodyUserInfoOptions_overwriteDefaultSoundName
{
    NSString *soundName = @"orverwritten_sound_name";
    UILocalNotification *result = [_manager presentNotificationNowWithAction:self.alertAction body:self.alertBody userInfo:self.userInfo options:@{@"soundName": soundName}];
    XCTAssertEqualObjects(result.soundName, soundName, @"if soundName is specified, defaultSoundName is ignored (specific soundName: %@)", soundName);
}

- (void)testPresentNotificationNowWithActionBodyUserInfoOptions_hasAction
{
    UILocalNotification *result = [_manager presentNotificationNowWithAction:self.alertAction body:self.alertBody userInfo:self.userInfo options:@{@"hasAction": @NO}];
    XCTAssertEqual(result.hasAction, YES, @"hasAction is YES at any time");
}

#pragma mark - rescheduleAllLocalNotificationsIfNeeded

- (void)testRescheduleAllLocalNotificationsIfNeeded_scheduledLocalNotifications
{
    for (int i=0; i < 2; i += 1) {
        [_props setObject:[@"notif" stringByAppendingFormat:@" %d", i] forKey:@"alertBody"];
        UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:_props];
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    }
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)2, @"");
    
    [_manager setNeedsRescheduling];
    [_manager rescheduleAllLocalNotificationsIfNeeded];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)2, @"after rescheduling and number before that should match");
}

- (void)testRescheduleAllLocalNotificationsIfNeeded_stackedLocalNotificaions
{
    UILocalNotification *firstNotif;
    SEL selector = @selector(scheduleLocalNotification:);
    for (int i=0; i < 3; i += 1) {
        [_props setObject:[@"notif" stringByAppendingFormat:@" %d", i] forKey:@"alertBody"];
        UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:_props];
        objc_msgSend(_manager, selector, notif);
        if (i == 0) {
            firstNotif = notif;
        }
    }
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)1, @"");
    XCTAssertEqualObjects([[UIApplication sharedApplication].scheduledLocalNotifications firstObject], firstNotif, @"");
    XCTAssertEqual([_manager.stackedLocalNotifications count], (NSUInteger)2, @"subsequent notifications of second should be stacked");
    
    [_manager setNeedsRescheduling];
    [_manager rescheduleAllLocalNotificationsIfNeeded];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)3, @"total of notification schedules on OS and stacks should be rescheduled into OS");
}

- (void)testRescheduleAllLocalNotificationsIfNeeded_notNeed
{
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:_props];
    NSMutableOrderedSet *stackedNotificationsSetSpy = [_manager valueForKey:@"stackedNotificationsSet"];
    [stackedNotificationsSetSpy addObject:notif];
    
    [_manager setValue:@NO forKey:@"needsRescheduling"];
    [_manager rescheduleAllLocalNotificationsIfNeeded];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"not be rescheduled if it is not needed");
    XCTAssertEqual([_manager.stackedLocalNotifications count], (NSUInteger)1, @"");
    [stackedNotificationsSetSpy removeAllObjects];
}

- (void)testRescheduleAllLocalNotificationsIfNeeded_variationOfNeedsRescheduling
{
    SEL selector = @selector(scheduleLocalNotification:);
    for (int i=0; i < 2; i += 1) {
        [_props setObject:[@"notif" stringByAppendingFormat:@" %d", i] forKey:@"alertBody"];
        UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:_props];
        objc_msgSend(_manager, selector, notif);
    }
    XCTAssertTrue([[_manager valueForKey:@"needsRescheduling"] boolValue], @"before rescheduling, needsRescheduling is YES");
    
    [_manager rescheduleAllLocalNotificationsIfNeeded];
    XCTAssertFalse([[_manager valueForKey:@"needsRescheduling"] boolValue], @"after rescheduling, needsRescheduling should NO");
}

#pragma mark - cancelNotification

- (void)testCancelNotification_inScheduled
{
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:_props];
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)1, @"");
    
    [_manager cancelNotification:notif];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"notification should be canceled from OS");
    XCTAssertFalse([[_manager valueForKey:@"needsRescheduling"] boolValue], @"need to reschedule is eliminated");
}

- (void)testCancelNotification_inStacked
{
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:_props];
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    UILocalNotification *stackedNotif = [_manager scheduleNotificationOn:self.fireDate body:@"stack" userInfo:nil options:nil];
    XCTAssertEqual([_manager.stackedLocalNotifications count], (NSUInteger)1, @"");
    XCTAssertTrue([[_manager valueForKey:@"needsRescheduling"] boolValue], @"");

    [_manager cancelNotification:stackedNotif];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)1, @"scheduled notification is no affects");
    XCTAssertEqual([_manager.stackedLocalNotifications count], (NSUInteger)0, @"notification should be canceled from stacked by manager");
    XCTAssertFalse([[_manager valueForKey:@"needsRescheduling"] boolValue], @"need to reschedule is eliminated");
}

#pragma mark - cancelAllNotifications

- (void)testCancelAllNotifications
{
    [_manager scheduleNotificationOn:self.fireDate body:@"under OS" userInfo:nil options:nil];
    [_manager scheduleNotificationOn:self.fireDate body:@"stack" userInfo:nil options:nil];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)1, @"");
    XCTAssertEqual([_manager.stackedLocalNotifications count], (NSUInteger)1, @"");
    
    [_manager cancelAllNotifications];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"all notification should be canceled from OS");
    XCTAssertEqual([_manager.stackedLocalNotifications count], (NSUInteger)0, @"all notification should be canceled from stacked by manager");
    XCTAssertFalse([[_manager valueForKey:@"needsRescheduling"] boolValue], @"need to reschedule is eliminated");
}

#pragma mark - UILocalNotification (HKRLocalNotificationManager)

- (void)testScheduleLocalNotification_sameLocalNotificationObject
{
    UILocalNotification *notif = [UILocalNotification new];
    notif.fireDate = [[NSDate date] dateByAddingTimeInterval:24 * 60 * 60];
    notif.alertBody = @"notification";
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    for (int i=0; i < 10; i += 1) {
        [[UIApplication sharedApplication] scheduleLocalNotification:[[UIApplication sharedApplication].scheduledLocalNotifications firstObject]];
    }

    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)1, @"");
}

- (void)testUILocalNotificationCategory_hkr_localNotificationWithOptions_validArg
{
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:_props];
    NSArray *propNames = [self propertyNames];
    for (NSString *name in propNames) {
        XCTAssertEqualObjects([notif valueForKey:name], [self valueForKey:name], @"%@ should match %@", name, [self valueForKey:name]);
    }
}

- (void)testUILocalNotificationCategory_hkr_localNotificationWithOptions_invalidArg
{
    [_props setObject:@"no_exists_property" forKey:@"invalid"];
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:_props];
    NSArray *propNames = [self propertyNames];
    for (NSString *name in propNames) {
        XCTAssertEqualObjects([notif valueForKey:name], [self valueForKey:name], @"%@ should match %@", name, [self valueForKey:name]);
    }
}

- (void)testUILocalNotificationCategory_hkr_localNotificationWithOptions_NSNull
{
    [_props setObject:[NSNull null] forKey:@"soundName"];
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:_props];
    self.soundName = nil;
    NSArray *propNames = [self propertyNames];
    for (NSString *name in propNames) {
        if ([name isEqualToString:@"soundName"]) {
            XCTAssertNil([notif valueForKey:name], @"NSNull should be converted nil");
        }
        else {
            XCTAssertEqualObjects([notif valueForKey:name], [self valueForKey:name], @"%@ should match %@", name, [self valueForKey:name]);
        }
    }
}

@end
