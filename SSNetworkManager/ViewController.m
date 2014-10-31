//
//  ViewController.m
//  SSNetworkManager
//
//  Created by sskh on 14/10/31.
//  Copyright (c) 2014年 sskh. All rights reserved.
//

#import "ViewController.h"
#import "NetworkManager/NetworkManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NetworkManager shareManager] GET:URL_USER_LOGIN parameters:nil identifier:IDENTIFIER_USER_LOGIN observer:self selector:@selector(handleUserLogin:)];
    [[NetworkManager shareManager] showHUDWithText:@"登录中..."];
}

#pragma mark - 处理网络请求回调
- (void)handleUserLogin:(NSNotification *)notification {
    //ret 是在ParseCenter中解析过后的结果，可能是 "解析过后的结果"或者"nil"或者"NSError"
    id ret = [[[NetworkManager shareManager] resultDict] objectForKey:notification.name];
    NSLog(@"ret:%@", ret);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
