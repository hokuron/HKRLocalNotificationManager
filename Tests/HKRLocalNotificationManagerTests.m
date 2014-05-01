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

@property (nonatomic) NSMutableDictionary *props;

@end

@implementation HKRLocalNotificationManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _fireDate = [NSDate date];
    _timeZone = [NSTimeZone localTimeZone];
    _repeatInterval = NSCalendarUnitDay | NSCalendarUnitHour;
    _repeatCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSISO8601Calendar];
    _alertBody = @"body";
    _hasAction = NO;
    _alertAction = @"action";
    _alertLaunchImage = @"path/to/image";
    _soundName = @"custom_sound";
    _applicationIconBadgeNumber = 86;
    _userInfo = @{@"user": @"info"};
    
    [self buildProperties];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [_props removeAllObjects];
    [super tearDown];
}

- (void)buildProperties
{
    _props = [@{} mutableCopy];
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (unsigned int idx=0; idx < count; idx += 1) {
        objc_property_t property = properties[idx];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        if ([name isEqualToString:@"props"]) continue;
        [self.props setObject:[self valueForKey:name] forKey:name];
    }
}

- (void)testSharedInstance
{
    XCTAssertEqualObjects([HKRLocalNotificationManager sharedManager], [HKRLocalNotificationManager sharedManager], @"shared instance should match");
}

- (void)testInit
{
    XCTAssertThrows([[HKRLocalNotificationManager alloc] init], @"init method should not recognize");
    XCTAssertThrows([HKRLocalNotificationManager new], @"new method should not recognize");
}

- (void)testUILocalNotificationCategory_hkr_localNotificationWithOptions_validArg
{
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:self.props];
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (unsigned int idx=0; idx < count; idx += 1) {
        objc_property_t property = properties[idx];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        if ([name isEqualToString:@"props"]) continue;
        XCTAssertEqualObjects([notif valueForKey:name], [self valueForKey:name], @"%@ should match %@", name, [self valueForKey:name]);
    }
}

- (void)testUILocalNotificationCategory_hkr_localNotificationWithOptions_invalidArg
{
    [self.props setObject:@"no_exists_property" forKey:@"invalid"];
    UILocalNotification *notif = [UILocalNotification hkr_localNotificationWithOptions:self.props];
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (unsigned int idx=0; idx < count; idx += 1) {
        objc_property_t property = properties[idx];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        if ([name isEqualToString:@"props"]) continue;
        XCTAssertEqualObjects([notif valueForKey:name], [self valueForKey:name], @"%@ should match %@", name, [self valueForKey:name]);
    }
}

@end
