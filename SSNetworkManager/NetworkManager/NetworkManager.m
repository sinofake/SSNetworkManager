//
//  NetworkManager.m
//  AFNetworkLianXi
//
//  Created by sskh on 14-8-7.
//  Copyright (c) 2014年 sskh. All rights reserved.
//

#import "NetworkManager.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "ParseCenter.h"


#define HUD_opacity 0.5f
#define HUD_minShowTime 1.5f

//static NSString * const kAppBaseURLString = @"http://192.168.1.109:8180/";

@interface NetworkManager ()<MBProgressHUDDelegate>

@property (nonatomic, strong) NSMutableDictionary *resultDict;
@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation NetworkManager

+ (NSString *)URLCachePath
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSArray *cacheDirectorys = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *URLCachePath = [cacheDirectorys[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/NSURLCache", bundleIdentifier]];
    //NSLog(@"URLCachePath:%@", URLCachePath);
    return URLCachePath;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        _resultDict = [[NSMutableDictionary alloc] init];
        //忽略所有缓存
        self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    }
    return self;
}

+ (instancetype)shareManager
{
    static NetworkManager *_shareManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:[NetworkManager URLCachePath]];
        [NSURLCache setSharedURLCache:URLCache];

        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        
        _shareManager = [[NetworkManager alloc] initWithBaseURL:[NSURL URLWithString:kAppBaseURLString]];
        

    });
    return _shareManager;
}

- (NSString *)URLStringForSessionTask:(NSURLSessionTask *)task
{
    return [[[task originalRequest] URL] absoluteString];
}

- (void)addNotificationObserver:(id)observer selector:(SEL)selector withSessionTask:(NSURLSessionTask *)task
{
    //NSLog(@"call...");
    if (observer && selector) {
        [[NSNotificationCenter defaultCenter] addObserver:observer  selector:selector name:[self URLStringForSessionTask:task] object:task];
    }
}

- (void)removeNotificationObserver:(id)observer withSessionTask:(NSURLSessionTask *)task
{
    //NSLog(@"call...");
    if (observer) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer name:[self URLStringForSessionTask:task] object:task];
    }
}

- (void)delayRemoveNotificationObserver:(id)observer withSessionTask:(NSURLSessionTask *)task
{
    //NSLog(@"call...");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeNotificationObserver:observer withSessionTask:task];
    });
}

- (void)postNotificationWithSessionTask:(NSURLSessionTask *)task
{
    [[NSNotificationCenter defaultCenter] postNotificationName:[self URLStringForSessionTask:task] object:task];
}

- (void)handleSuccessTask:(NSURLSessionTask *)task responseObject:(id)responseObject identifier:(int)identifier observer:(id)observer
{
    [self hideHUD];

    NSLog(@"responseObject:%@", responseObject);
    id parseResult = [ParseCenter parseResponseObject:responseObject withIdentifier:identifier];
    
    if (parseResult) {
        self.resultDict[[self URLStringForSessionTask:task]] = parseResult;
    }
    else {
        NSLog(@"解析数据出错或解析结果为空！");
        [self.resultDict removeObjectForKey:[self URLStringForSessionTask:task]];
    }
    
    //NSLog(@"self.resultDict:%@", self.resultDict);
    

    [self postNotificationWithSessionTask:task];
    
    [self delayRemoveNotificationObserver:observer withSessionTask:task];
}

- (void)handleFailureTask:(NSURLSessionTask *)task error:(NSError *)error observer:(id)observer
{
    [self hideHUD];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HUD_network_minShowTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NetworkManager showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] withText:[error localizedDescription] duration:2.f];
    });

    self.resultDict[[self URLStringForSessionTask:task]] = error;
    
    [self postNotificationWithSessionTask:task];
    
    [self delayRemoveNotificationObserver:observer withSessionTask:task];
}

- (NSURLSessionTask *)GET:(NSString *)URLString parameters:(id)parameters identifier:(int)identifier observer:(id)observer selector:(SEL)selector
{
    __weak __typeof(self)weakSelf = self;
    NSURLSessionTask *sessionTask = [self GET:URLString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [weakSelf handleSuccessTask:task responseObject:responseObject identifier:identifier observer:observer];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf handleFailureTask:task error:error observer:observer];
    }];
    
    [self addNotificationObserver:observer selector:selector withSessionTask:sessionTask];
    return sessionTask;
}

- (NSURLSessionTask *)GET:(NSString *)URLString parametersShouldConvertToJSON:(id)parameters identifier:(int)identifier observer:(id)observer selector:(SEL)selector
{
    self.requestSerializer = [AFJSONRequestSerializer serializer];
    self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    NSURLSessionTask *task =  [self GET:URLString parameters:parameters identifier:identifier observer:observer selector:selector];
    
    self.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    return task;
}

- (NSURLSessionTask *)POST:(NSString *)URLString parameters:(id)parameters identifier:(int)identifier observer:(id)observer selector:(SEL)selector
{
    __weak __typeof(self)weakSelf = self;
    NSURLSessionTask *sessionTask = [self POST:URLString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [weakSelf handleSuccessTask:task responseObject:responseObject identifier:identifier observer:observer];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf handleFailureTask:task error:error observer:observer];
    }];
    
    [self addNotificationObserver:observer selector:selector withSessionTask:sessionTask];
    return sessionTask;
}

- (NSURLSessionTask *)POST:(NSString *)URLString parametersShouldConvertToJSON:(id)parameters identifier:(int)identifier observer:(id)observer selector:(SEL)selector
{
    self.requestSerializer = [AFJSONRequestSerializer serializer];
    self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    NSURLSessionTask *task = [self POST:URLString parameters:parameters identifier:identifier observer:observer selector:selector];
    
    self.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    return task;
}

- (NSURLSessionTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                    identifier:(int)identifier
                      observer:(id)observer
                      selector:(SEL)selector
{
//    //放大招，不知道好不好？
//    for (NSString *HTTPHeaderField in parameters) {
//        //如果value是NSNumber类型则会出现-[__NSCFNumber length]: unrecognized selector sent to instance
//        id value = parameters[HTTPHeaderField];
//        if ([value isKindOfClass:[NSNumber class]]) {
//            value = [value stringValue];
//        }
//        [self.requestSerializer setValue:value forHTTPHeaderField:HTTPHeaderField];
//    }
    
    __weak __typeof(self)weakSelf = self;
    NSURLSessionTask *sessionTask = [self POST:URLString parameters:nil constructingBodyWithBlock:block success:^(NSURLSessionDataTask *task, id responseObject) {
        [weakSelf handleSuccessTask:task responseObject:responseObject identifier:identifier observer:observer];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf handleFailureTask:task error:error observer:observer];
    }];
    
    //NSLog(@"HTTPRequestHeaders:%@", self.requestSerializer.HTTPRequestHeaders);
    /**
     HTTPRequestHeaders:{
     "Accept-Language" = "zh-Hans;q=1, en;q=0.9, fr;q=0.8, de;q=0.7, zh-Hant;q=0.6, ja;q=0.5";
     "User-Agent" = "HuaErSlimmingRing/1.0 (iPod touch; iOS 7.1.2; Scale/2.00)";
     picNum = 0;
     relatedId = 100001;
     suffix = png;
     type = 1;
     uid = 100001;
     }
     */
    
    [self addNotificationObserver:observer selector:selector withSessionTask:sessionTask];
    
    //要不要这么写一下？
    //self.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    return sessionTask;
}


//自己的改写
- (NSURLSessionUploadTask *)ss_POST:(NSString *)URLString
                parameters:(id)parameters
                  fromData:(NSData *)bodyData
                   success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                   failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAppBaseURLString, URLString]]];
    
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    for (NSString *HTTPHeaderField in parameters) {
        //如果value是NSNumber类型则会出现-[__NSCFNumber length]: unrecognized selector sent to instance
        id value = parameters[HTTPHeaderField];
        if ([value isKindOfClass:[NSNumber class]]) {
            value = [value stringValue];
        }
        [request setValue:value forHTTPHeaderField:HTTPHeaderField];
    }
    
    __block NSURLSessionUploadTask *task = [self uploadTaskWithRequest:request fromData:bodyData progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(task, error);
            }
        } else {
            if (success) {
                success(task, responseObject);
            }
        }
    }];
    
    [task resume];
    
    return task;
}

- (NSURLSessionTask *)ss_POST:(NSString *)URLString
                   parameters:(id)parameters
                     fromData:(NSData *)bodyData
                   identifier:(int)identifier
                     observer:(id)observer
                     selector:(SEL)selector
{
    __weak __typeof(self)weakSelf = self;
    NSURLSessionTask *sessionTask = [self ss_POST:URLString parameters:parameters fromData:bodyData success:^(NSURLSessionDataTask *task, id responseObject) {
        [weakSelf handleSuccessTask:task responseObject:responseObject identifier:identifier observer:observer];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf handleFailureTask:task error:error observer:observer];
    }];
    
    [self addNotificationObserver:observer selector:selector withSessionTask:sessionTask];
    
    return sessionTask;
}



#pragma mark -
#pragma mark  - HUD

- (MBProgressHUD *)HUD
{
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithWindow:[[UIApplication sharedApplication] keyWindow]];
        [[[UIApplication sharedApplication] keyWindow] addSubview:_HUD];
        _HUD.delegate = self;
        //_HUD.minSize = CGSizeMake(135.f, 135.f);
        _HUD.opacity = HUD_opacity;
        _HUD.minShowTime = HUD_network_minShowTime;
    }
    return _HUD;
}

- (void)showHUD
{
    [self.HUD show:YES];
}

- (void)showHUDWithText:(NSString *)text
{
    self.HUD.labelText = text;
    [self showHUD];
}

- (void)hideHUD
{
    if (_HUD) {
        [_HUD hide:YES];
    }
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	// Remove HUD from screen when the HUD was hidded
	[_HUD removeFromSuperview];
	_HUD = nil;
}

#pragma mark - 
#pragma mark - hud 类方法
+ (MBProgressHUD *)HUDWithView:(UIView *)view text:(NSString *)text
{
    if (text == nil || text.length == 0) {
        return nil;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	
	// Configure for text only and offset down
	hud.mode = MBProgressHUDModeText;
	//hud.margin = 10.f;
	//hud.yOffset = 150.f;
    hud.opacity = HUD_opacity;
    hud.minShowTime = HUD_minShowTime;
    hud.labelText = text;
	hud.removeFromSuperViewOnHide = YES;
    return hud;
}

+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view withText:(NSString *)text;
{
    return [NetworkManager showHUDAddedTo:view withText:text duration:HUD_minShowTime completionBlock:nil];
}

+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view withText:(NSString *)text duration:(NSTimeInterval)duration
{
    return [NetworkManager showHUDAddedTo:view withText:text duration:duration completionBlock:nil];
}

+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view withText:(NSString *)text completionBlock:(MBProgressHUDCompletionBlock)completionBlock
{
    return [self showHUDAddedTo:view withText:text duration:HUD_minShowTime completionBlock:completionBlock];
}


+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view withText:(NSString *)text duration:(NSTimeInterval)duration completionBlock:(MBProgressHUDCompletionBlock)completionBlock
{
    MBProgressHUD *hud = [self HUDWithView:view text:text];
    if (hud) {
        if (completionBlock) {
            hud.completionBlock = completionBlock;
        }
        [hud hide:YES afterDelay:duration];
        return hud;
    }
    else {
        return nil;
    }
}

//checkmark HUD
+ (MBProgressHUD *)showCheckmarkHUDAddedTo:(UIView *)view withText:(NSString *)text;
{
    return [NetworkManager showCheckmarkHUDAddedTo:view withText:text duration:HUD_minShowTime completionBlock:nil];
}

+ (MBProgressHUD *)showCheckmarkHUDAddedTo:(UIView *)view withText:(NSString *)text duration:(NSTimeInterval)duration
{
    return [NetworkManager showCheckmarkHUDAddedTo:view withText:text duration:HUD_minShowTime completionBlock:nil];

}

+ (MBProgressHUD *)showCheckmarkHUDAddedTo:(UIView *)view withText:(NSString *)text completionBlock:(MBProgressHUDCompletionBlock)completionBlock
{
    return [NetworkManager showCheckmarkHUDAddedTo:view withText:text duration:HUD_minShowTime completionBlock:completionBlock];
}

+ (MBProgressHUD *)showCheckmarkHUDAddedTo:(UIView *)view withText:(NSString *)text duration:(NSTimeInterval)duration completionBlock:(MBProgressHUDCompletionBlock)completionBlock
{
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeCustomView;
    hud.opacity = HUD_opacity;
    hud.minShowTime = HUD_minShowTime;
    if (text && text.length) {
        hud.labelText = text;
    }
	hud.removeFromSuperViewOnHide = YES;
    
    hud.square = YES;
    UIImage *image = [UIImage imageNamed:@"MBProgress_Checkmark.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    hud.customView = imageView;
    
    if (completionBlock) {
        hud.completionBlock = completionBlock;
    }
    
    [hud hide:YES afterDelay:duration];
    
    return hud;
}



@end























