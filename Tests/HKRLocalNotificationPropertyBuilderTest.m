//
//  HKRLocalNotificationPropertyBuilderTest.m
//  HKRLocalNotificationManager
//
//  Created by hokuron on 5/12/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "HKRLocalNotificationPropertyBuilder.h"

@interface HKRLocalNotificationPropertyBuilderTest : XCTestCase

@end

@implementation HKRLocalNotificationPropertyBuilderTest {
    HKRLocalNotificationPropertyBuilder *_builder;
    
    NSString     *_alertAction;
    NSString     *_alertBody;
    NSDate       *_fireDate;
    NSDictionary *_userInfo;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _builder = [HKRLocalNotificationPropertyBuilder new];
    _alertAction = @"Alert Action";
    _alertBody   = @"Alert Body";
    _fireDate    = [NSDate date];
    _userInfo    = @{@"user": @"info"};
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBasicPropertiesWithDateBodyUserInfo
{
    NSDictionary *result = [_builder basicPropertiesWithDate:_fireDate body:_alertBody userInfo:_userInfo];
    XCTAssertEqualObjects(result[@"alertBody"], _alertBody, @"value of alertBody key should match %@", _alertBody);
    XCTAssertEqualObjects(result[@"fireDate"], _fireDate, @"value of fireDate key should match %@", _fireDate);
    XCTAssertTrue([_userInfo isEqualToDictionary:result[@"userInfo"]], @"structure of userInfo key should match %@", _userInfo);
}

- (void)testBasicPropertiesWithDateBodyUserInfo_nil
{
    NSDictionary *result = [_builder basicPropertiesWithDate:nil body:_alertBody userInfo:nil];
    XCTAssertEqualObjects(result[@"fireDate"], [NSNull null], @"when arguments designate nil, it should match NSNull");
    XCTAssertEqualObjects(result[@"userInfo"], [NSNull null], @"when arguments designate nil, it should match NSNull");
}

- (void)testBasicPropertiesWithActionDateBodyUserInfo
{
    NSDictionary *result = [_builder basicPropertiesWithAction:_alertAction date:_fireDate body:_alertBody userInfo:_userInfo];
    XCTAssertEqualObjects(result[@"alertAction"], _alertAction, @"value of alertAction key should match %@", _alertAction);
    XCTAssertEqualObjects(result[@"alertBody"], _alertBody, @"value of alertBody key should match %@", _alertBody);
    XCTAssertEqualObjects(result[@"fireDate"], _fireDate, @"value of fireDate key should match %@", _fireDate);
    XCTAssertEqual([result[@"hasAction"] boolValue], YES, @"value of hasAction key should match YES");
    XCTAssertTrue([_userInfo isEqualToDictionary:result[@"userInfo"]], @"structure of userInfo key should match %@", _userInfo);
}

- (void)testBasicPropertiesWithActionDateBodyUserInfo_nil
{
    NSDictionary *result = [_builder basicPropertiesWithAction:_alertAction date:nil body:_alertBody userInfo:nil];
    XCTAssertEqualObjects(result[@"fireDate"], [NSNull null], @"when arguments designate nil, it should match NSNull");
    XCTAssertEqualObjects(result[@"userInfo"], [NSNull null], @"when arguments designate nil, it should match NSNull");
}

- (void)testMergePropertyWithOther
{
    NSDictionary *prop  = @{@"alertBody": _alertBody, @"userInfo": _userInfo};
    NSDictionary *other = @{@"alertBody": @"DUPLICATE Alert Body", @"alertAction": _alertAction};
    NSDictionary *result = [_builder mergeProperty:prop withOther:other];
    XCTAssertTrue([_userInfo isEqualToDictionary:result[@"userInfo"]], @"structure of userInfo key should match %@", _userInfo);
    XCTAssertEqualObjects(result[@"alertAction"], _alertAction, @"value of alertAction key should match %@", _alertAction);
    XCTAssertEqualObjects(result[@"alertBody"], _alertBody, @"when key of argument dictionaries is duplicate, 1st argument is priority %@", _alertBody);
}

- (void)testMergePropertyWithOther_otherPropertyNil
{
    NSDictionary *prop  = @{@"alertBody": _alertBody, @"userInfo": _userInfo};
    NSDictionary *result = [_builder mergeProperty:prop withOther:nil];
    XCTAssertEqualObjects(result[@"alertBody"], _alertBody, @"when key of argument dictionaries is duplicate, 1st argument is priority %@", _alertBody);
    XCTAssertTrue([_userInfo isEqualToDictionary:result[@"userInfo"]], @"structure of userInfo key should match %@", _userInfo);
}

@end
