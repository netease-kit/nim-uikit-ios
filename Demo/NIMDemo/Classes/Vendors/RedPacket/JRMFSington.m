//
//  JRMFSington.m
//  NIM
//
//  Created by Criss on 2016/12/22.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "JRMFSington.h"

static JRMFSington * sington = nil;

@implementation JRMFSington
@synthesize JrmfPartnerId;
@synthesize JrmfThirdToken, JrmfPacketUserId;

+ (JRMFSington *)GetPacketSington {
    if (sington == nil) {
        sington = [[JRMFSington alloc] init];
    }
    return sington;
}

- (instancetype)init {
    if ([super init]) {
        //数据初始化
        [self PacketDataFormat];
    }
    return self;
}

- (void)ClearJPacketData {
    if (sington == nil) {
        return;
    }
    
    //数据初始化
    [self PacketDataFormat];
}

- (void)PacketDataFormat {
    JrmfThirdToken = @"";
    JrmfPartnerId = @"";
    JrmfPacketUserId = @"";
}

- (NSString *)JrmfPartnerId {
    return [NIMSDK sharedSDK].appKey;
}

- (NSString *)JrmfPacketUserId {
    return [[NIMSDK sharedSDK].loginManager currentAccount];
}



@end
