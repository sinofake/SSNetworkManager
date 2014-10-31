//
//  ParseCenter.m
//  Fitness1229
//
//  Created by sskh on 14-8-7.
//  Copyright (c) 2014年 sskh. All rights reserved.
//

#import "ParseCenter.h"

@implementation ParseCenter

/**
 *  在这里做数据的集中解析
 *
 *  @param responseObject 服务器返回的数据
 *  @param identifier     每次请求的唯一标识
 *
 *  @return 解析过后的结果
 */
+ (id)parseResponseObject:(id)responseObject withIdentifier:(int)identifier
{
    id result = responseObject;
    switch (identifier) {
        case IDENTIFIER_USER_LOGIN:
            result = [ParseCenter parseUserLogin:responseObject];
            break;
        
        default:
            break;
    }
    return result;
}

+ (BOOL)checkServerReturnDataIsCorrect:(id)responseObject
{
    NSString *status = [responseObject objectForKey:@"status"];
    NSString *message = [responseObject objectForKey:@"message"];
    if ([status intValue] == NETWORK_SUCCESS_STATUS_CODE && [message isEqualToString:NETWORK_SUCCESS_MESSAGE]) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (id)parseUserLogin:(id)responseObject
{
    if ([ParseCenter checkServerReturnDataIsCorrect:responseObject]) {
        
//        UserInfoModel *model = [[UserInfoModel alloc] initWithDictionary:responseObject[@"user"] error:nil];
//        
//        return model;
    }
    
    return nil;
}



@end





















