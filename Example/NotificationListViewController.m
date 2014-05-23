//
//  NotificationListViewController.m
//  HKRLocalNotificationManager
//
//  Created by hokuron on 5/23/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

#import "NotificationListViewController.h"

#import "HKRLocalNotificationManager.h"

@interface NotificationListViewController ()

@end

@implementation NotificationListViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? [[UIApplication sharedApplication].scheduledLocalNotifications count] : [[HKRLocalNotificationManager sharedManager].stackedLocalNotifications count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell" forIndexPath:indexPath];
    UILocalNotification *notif = [self localNotificationWithIndexPath:indexPath];
    cell.textLabel.text       = notif.alertBody;
    cell.detailTextLabel.text = [notif.fireDate descriptionWithLocale:[NSLocale currentLocale]];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"Scheduled" : @"Stacked";
}

- (UILocalNotification *)localNotificationWithIndexPath:(NSIndexPath *)indexPath
{
    NSArray *notifications = indexPath.section == 0 ? [UIApplication sharedApplication].scheduledLocalNotifications : [HKRLocalNotificationManager sharedManager].stackedLocalNotifications;
    return notifications[indexPath.row];
}

@end
