//
//  NTESDemoRegisterTask.m
//  NIM
//
//  Created by amao on 1/20/16.
//  Copyright © 2016 Netease. All rights reserved.
//

#import "NTESDemoRegisterTask.h"
#import "NTESDemoConfig.h"
#import "NSDictionary+NTESJson.h"

@implementation NTESRegisterData
@end

@implementation NTESDemoRegisterTask
- (NSURLRequest *)taskRequest
{
    NSString *urlString = [[[NTESDemoConfig sharedConfig] apiURL] stringByAppendingString:@"/createDemoUser"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
                                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                            timeoutInterval:30];
    [request setHTTPMethod:@"Post"];
    
    [request addValue:@"application/x-www-form-urlencoded;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"nim_demo_ios" forHTTPHeaderField:@"User-Agent"];
    [request addValue:[[NIMSDK sharedSDK] appKey] forHTTPHeaderField:@"appkey"];
    
    NSString *postData = [NSString stringWithFormat:@"username=%@&password=%@&nickname=%@",[_data account],[_data token],[_data nickname]];
    [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

- (void)onGetResponse:(id)jsonObject error:(NSError *)error
{
    NSError *resultError = error;
    NSString *errMsg = @"unknown error";
    if (error == nil && [jsonObject isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = (NSDictionary *)jsonObject;
        NSInteger code = [dict jsonInteger:@"res"];
        resultError = code == 200 ? nil :  [NSError errorWithDomain:@"ntes domain"
                                                               code:code
                                                           userInfo:nil];
        errMsg = dict[@"errmsg"];
    }
    if (_handler)
    {
        _handler(resultError,errMsg);
    }
    
}

@end
