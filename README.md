# HKRLocalNotificationManager [![build status](https://api.travis-ci.org/hokuron/HKRLocalNotificationManager.png?branch=master)](https://travis-ci.org/hokuron/HKRLocalNotificationManager)

HKRLocalNotificationManager is a safe schedule manager of local notification.  

## Features

* Prevents the duplication schedule.
* Useful methods to schedule.
* When `UILocalNotification` is stocked once, and application moved to a background, it is done a schedule all at once.

## Usage

### Scheduling a local notification without action

```objectivec
[[HKRLocalNotificationManager sharedManager] scheduleNotificationOn:specificDate
                                                               body:@"alert body"
                                                           userInfo:nil
                                                            options:nil];
```

And immediate…

```objectivec
[[HKRLocalNotificationManager sharedManager] presentNotificationNowWithBody:@"alert body"
                                                                   userInfo:nil
                                                                    options:nil];
```

### Scheduling a local notification without action

```objectivec
[[HKRLocalNotificationManager sharedManager] scheduleNotificationWithAction:@"action title"
                                                                     onDate:specificDate
                                                                       body:@"alert body"
                                                                   userInfo:nil
                                                                    options:nil];
```

And immediate...

```objectivec
[[HKRLocalNotificationManager sharedManager] presentNotificationNowWithAction:@"action title"
                                                                       body:@"alert body"
                                                                   userInfo:nil
                                                                    options:nil];
```

### What is `options` in arguments?

`options` in the argument of the above method can specify a value of property of UILocalNotification using NSDictionary.  
  
Example sets the value of `applicationIconBadgeNumber` using the `options`.

```objectivec
[[HKRLocalNotificationManager sharedManager] presentNotificationNowWithBody:@"alert body"
                                                                   userInfo:nil
                                                                    options:@{@"applicationIconBadgeNumber": @10}];
```

### Canceling a local notification in system or Stacked

If you want to cancel a local notification that you scheduled using the methods above, please do use the following methods always.  

```objectivec
[[HKRLocalNotificationManager sharedManager] cancelNotification:specificLocalNotification];
```

```objectivec
[[HKRLocalNotificationManager sharedManager] cancelAllNotifications];
```

### Set default sound name

You can specify the soundName used in local notification of all. you can also override it using `options`. defaults to `UILocalNotificationDefaultSoundName`.

```objectivec
[[HKRLocalNotificationManager sharedManager].defaultSoundName = @"path/to/soundName/file";
```
```objectivec
[[HKRLocalNotificationManager sharedManager].defaultSoundName = @"path/to/soundName/file";

// soundName of the following local notification is applied nil.
[[HKRLocalNotificationManager sharedManager] presentNotificationNowWithBody:@"alert body"
                                                                   userInfo:nil
                                                                    options:@{@"soundName": nil}];
```

### Automatic re-schedule (processing in background)

When `UILocalNotification` is stocked once, and application moved to a background, it is done a schedule all at once.

```objectivec
// in AppDelegate.m
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [HKRLocalNotificationManager rescheduleInBackground];
}
```

### Manual re-schedule

```objectivec
[[HKRLocalNotificationManager sharedManager] setNeedsRescheduling];
[[HKRLocalNotificationManager sharedManager] rescheduleAllLocalNotificationsIfNeeded];
```

### License

the MIT license.
