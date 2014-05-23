//
//  ViewController.m
//  HKRLocalNotificationManager
//
//  Created by Takuma Shimizu on 5/1/14.
//  Copyright (c) 2014 Takuma Shimizu. All rights reserved.
//

#import "ViewController.h"

#import "HKRLocalNotificationManager.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;

@end

@implementation ViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (! (self = [super initWithCoder:aDecoder])) return nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)scheduleDemoNotifications
{
    NSDate *tomorrow = [[NSDate date] dateByAddingTimeInterval:24 * 60 * 60];
    for (int i=0; i < 10; i += 1) {
        [[HKRLocalNotificationManager sharedManager] scheduleNotificationOn:tomorrow
                                                                       body:[NSString stringWithFormat:@"demo notification #%02d", i+1]
                                                                   userInfo:nil
                                                                    options:nil];
    }
}

- (void)buttonEnabled:(BOOL)enabled withTag:(NSInteger)tag
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"tag == %d", tag];
    UIButton *button = [[self.buttons filteredArrayUsingPredicate:pred] firstObject];
    button.enabled = enabled;
}

- (void)resetDemo
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[HKRLocalNotificationManager sharedManager] cancelAllNotifications];
    [self buttonEnabled:YES withTag:1];
    [self buttonEnabled:NO withTag:2];
    [self buttonEnabled:NO withTag:3];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self buttonEnabled:NO withTag:2];
    [self buttonEnabled:YES withTag:3];
}

- (IBAction)schedule:(UIButton *)sender
{
    [self scheduleDemoNotifications];
    sender.enabled = NO;
    [self buttonEnabled:YES withTag:2];
}

- (IBAction)checkNotification:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"ShowNotifications" sender:self];
}

- (IBAction)reset:(UIButton *)sender
{
    [self resetDemo];
}

@end
