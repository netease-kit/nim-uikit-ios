//
//  NTESDemoConfig.h
//  NIM
//
//  Created by amao on 4/21/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>


//此处 apiURL 为网易云信 Demo 应用服务器地址，更换 appkey 后，请更新为应用自己的服务器接口地址，并提供相关接口服

@interface NTESDemoConfig : NSObject
+ (instancetype)sharedConfig;

@property (nonatomic,copy)  NSString    *appKey;
@property (nonatomic,copy)  NSString    *apiURL;
@property (nonatomic,copy)  NSString    *cerName;
@end
