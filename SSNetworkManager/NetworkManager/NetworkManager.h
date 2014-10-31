//
//  NetworkManager.h
//  AFNetworkLianXi
//
//  Created by sskh on 14-8-7.
//  Copyright (c) 2014年 sskh. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "MBProgressHUD.h"

#define HUD_network_minShowTime 1.f //带网络请求的最小显示时间

@interface NetworkManager : AFHTTPSessionManager

@property (nonatomic, strong, readonly) NSMutableDictionary *resultDict;
@property (nonatomic, strong, readonly) MBProgressHUD *HUD;


+ (NSString *)URLCachePath;

+ (instancetype)shareManager;

- (NSURLSessionTask *)GET:(NSString *)URLString
               parameters:(id)parameters
               identifier:(int)identifier
                 observer:(id)observer
                 selector:(SEL)selector;

- (NSURLSessionTask *)GET:(NSString *)URLString parametersShouldConvertToJSON:(id)parameters
               identifier:(int)identifier
                 observer:(id)observer
                 selector:(SEL)selector;

- (NSURLSessionTask *)POST:(NSString *)URLString
                parameters:(id)parameters
                identifier:(int)identifier
                  observer:(id)observer
                  selector:(SEL)selector;


- (NSURLSessionTask *)POST:(NSString *)URLString parametersShouldConvertToJSON:(id)parameters
                identifier:(int)identifier
                  observer:(id)observer
                  selector:(SEL)selector;

/**
 *  <AFMultipartFormData>中可能用到的参数示例：
 *  fileURL:   @"file://path/to/image.png"
 *  name:      @"image"
 *  fileName:  @"image.jpg"
 *  mimeType:  @"image/jpeg"
 *  这个方法会加一个boundary，服务器那套解析的可能有点问题
 */
- (NSURLSessionTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                    identifier:(int)identifier
                      observer:(id)observer
                      selector:(SEL)selector;

//自己的改写，可以用来上传图片
- (NSURLSessionTask *)ss_POST:(NSString *)URLString
                parameters:(id)parameters
                fromData:(NSData *)bodyData
                identifier:(int)identifier
                  observer:(id)observer
                  selector:(SEL)selector;

#pragma mark -
#pragma mark - HUD
- (void)showHUD;
- (void)showHUDWithText:(NSString *)text;

- (void)hideHUD;

#pragma mark -
#pragma mark - HUD类方法
//这里的text不能为nil，因为只是显示文字HUD
+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view withText:(NSString *)text;
+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view withText:(NSString *)text duration:(NSTimeInterval)duration;

+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view withText:(NSString *)text completionBlock:(MBProgressHUDCompletionBlock)completionBlock;

+ (MBProgressHUD *)showHUDAddedTo:(UIView *)view withText:(NSString *)text duration:(NSTimeInterval)duration completionBlock:(MBProgressHUDCompletionBlock)completionBlock;

//显示一个对号HUD,这里的text可以为nil， 因为这显示“对号”HUD
+ (MBProgressHUD *)showCheckmarkHUDAddedTo:(UIView *)view withText:(NSString *)text;
+ (MBProgressHUD *)showCheckmarkHUDAddedTo:(UIView *)view withText:(NSString *)text duration:(NSTimeInterval)duration;
+ (MBProgressHUD *)showCheckmarkHUDAddedTo:(UIView *)view withText:(NSString *)text completionBlock:(MBProgressHUDCompletionBlock)completionBlock;
+ (MBProgressHUD *)showCheckmarkHUDAddedTo:(UIView *)view withText:(NSString *)text duration:(NSTimeInterval)duration completionBlock:(MBProgressHUDCompletionBlock)completionBlock;





@end
