//
//  AppDelegate.m
//  TelegramLiveCamera
//
//  Created by fanzhang on 2020年4月15日  16周Wednesday.
//  Copyright © 2020 twotrees. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIViewController *root = [[ViewController alloc] init];
    UINavigationController* navi = [[UINavigationController alloc] initWithRootViewController:root];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];
    
    return YES;
}



@end
