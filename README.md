SSNetworkManager
================

继承自AFHTTPSessionManager，封装的一个下载管理类，并带有HUD


用法示例：
[[NetworkManager shareManager] GET:URL_USER_LOGIN parameters:nil identifier:IDENTIFIER_USER_LOGIN observer:self selector:@selector(handleUserLogin:)];
[[NetworkManager shareManager] showHUDWithText:@"登录中..."];


#pragma mark - 处理网络请求回调
- (void)handleUserLogin:(NSNotification *)notification {
//ret 是在ParseCenter中解析过后的结果，可能是 "解析过后的结果"或者"nil"或者"NSError"
id ret = [[[NetworkManager shareManager] resultDict] objectForKey:notification.name];
NSLog(@"ret:%@", ret);
}