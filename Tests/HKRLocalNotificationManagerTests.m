//
//  HKRLocalNotificationManagerTests.m
//  HKRLocalNotificationManagerTests
//
//  Created by hokuron on 5/1/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

#import <XCTest/XCTest.h>
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

- (void)testScheduleNotificationOnBodyUserInfoOptions_fireDateNil
{
    UILocalNotification *result = [_manager scheduleNotificationOn:nil body:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertNil(result, @"if fireDate is nil, notification should NOT be scheduled");
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"if fireDate is nil, notification should NOT be scheduled");
}

- (void)testScheduleNotificationOnBodyUserInfoOptions_fireDatePast
{
    UILocalNotification *result = [_manager scheduleNotificationOn:[NSDate date] body:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertNil(result, @"if fireDate is past, notification should NOT be scheduled");
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"if fireDate is past, notification should NOT be scheduled");
}

#pragma mark - testScheduleNotificationWithActionOnDateBodyUserInfoOptions

- (void)testScheduleNotificationWithActionOnDateBodyUserInfoOptions_noOptions
{
    UILocalNotification *result = [_manager scheduleNotificationWithAction:self.alertAction onDate:self.fireDate body:self.alertBody userInfo:self.userInfo options:nil];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.alertAction = self.alertAction;
    notif.fireDate  = self.fireDate;
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:[[UIApplication sharedApplication].scheduledLocalNotifications firstObject]];
}

- (void)testScheduleNotificationWithActionOnDateBodyUserInfoOptions_addOptions
{
    NSString *alertLaunchImage = @"additional_option";
    UILocalNotification *result = [_manager scheduleNotificationWithAction:self.alertAction onDate:self.fireDate body:self.alertBody userInfo:self.userInfo options:@{@"alertLaunchImage": alertLaunchImage}];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.alertAction = self.alertAction;
    notif.fireDate  = self.fireDate;
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
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
    notif.fireDate  = self.fireDate;
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
    
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
    XCTAssertNil(result, @"if fireDate is past, notification should NOT be scheduled");
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"if fireDate is past, notification should NOT be scheduled");
}

#pragma mark - presentNotificationNowWithBodyUserInfoOptions

- (void)testPresentNotificationNowWithBodyUserInfoOptions
{
    UILocalNotification *result = [HKRLocalNotificationManager presentNotificationNowWithBody:self.alertBody userInfo:self.userInfo options:nil];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"there is no scheduledLocalNotifications for the notification was fired right now");
}

- (void)testPresentNotificationNowWithBodyUserInfoOptions_defaultSoundName
{
    _manager.defaultSoundName = @"defaultSoundName";
    UILocalNotification *result = [HKRLocalNotificationManager presentNotificationNowWithBody:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertEqualObjects(result.soundName, _manager.defaultSoundName, @"if soundName is NOT specified, it should match %@", _manager.defaultSoundName);
}

- (void)testPresentNotificationNowWithBodyUserInfoOptions_overwriteDefaultSoundName
{
    NSString *soundName = @"orverwritten_sound_name";
    UILocalNotification *result = [HKRLocalNotificationManager presentNotificationNowWithBody:self.alertBody userInfo:self.userInfo options:@{@"soundName": soundName}];
    XCTAssertEqualObjects(result.soundName, soundName, @"if soundName is specified, defaultSoundName is ignored (specific soundName: %@)", soundName);
}

#pragma mark - presentNotificationNowWithActionBodyUserInfoOptions

- (void)testPresentNotificationNowWithActionBodyUserInfoOptions
{
    UILocalNotification *result = [HKRLocalNotificationManager presentNotificationNowWithAction:self.alertAction body:self.alertBody userInfo:self.userInfo options:nil];
    UILocalNotification *notif  = [UILocalNotification new];
    notif.alertBody = self.alertBody;
    notif.userInfo  = self.userInfo;
    
    [self localNotificationPropertiesMatchingTestWithTarget:result testData:notif];
    XCTAssertEqual([[UIApplication sharedApplication].scheduledLocalNotifications count], (NSUInteger)0, @"there is no scheduledLocalNotifications for the notification was fired right now");
}

- (void)testPresentNotificationNowWithActionBodyUserInfoOptions_defaultSoundName
{
    _manager.defaultSoundName = @"defaultSoundName";
    UILocalNotification *result = [HKRLocalNotificationManager presentNotificationNowWithAction:self.alertAction body:self.alertBody userInfo:self.userInfo options:nil];
    XCTAssertEqualObjects(result.soundName, _manager.defaultSoundName, @"if soundName is NOT specified, it should match %@", _manager.defaultSoundName);
}

- (void)testPresentNotificationNowWithActionBodyUserInfoOptions_overwriteDefaultSoundName
{
    NSString *soundName = @"orverwritten_sound_name";
    UILocalNotification *result = [HKRLocalNotificationManager presentNotificationNowWithAction:self.alertAction body:self.alertBody userInfo:self.userInfo options:@{@"soundName": soundName}];
    XCTAssertEqualObjects(result.soundName, soundName, @"if soundName is specified, defaultSoundName is ignored (specific soundName: %@)", soundName);
}

- (void)testPresentNotificationNowWithActionBodyUserInfoOptions_hasAction
{
    UILocalNotification *result = [HKRLocalNotificationManager presentNotificationNowWithAction:self.alertAction body:self.alertBody userInfo:self.userInfo options:@{@"hasAction": @NO}];
    XCTAssertEqual(result.hasAction, YES, @"hasAction is YES at any time");
}

#pragma mark - UILocalNotification (HKRLocalNotificationManager)

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
