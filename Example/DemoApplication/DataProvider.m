//
//  DataProvider.m
//  DemoApplication
//
//  Created by chris on 15/10/7.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "DataProvider.h"

@implementation DataProvider

- (NIMKitInfo *)infoByUser:(NSString *)userId
               withMessage:(NIMMessage *)message{
    NIMKitInfo *info = [[NIMKitInfo alloc] init];
    info.avatarImage = [UIImage imageNamed:@"DefaultAvatar"];
    //注意只有将用户数据托管给云信才可以调用此方法，否则请自行维护用户昵称等数据
    NIMUser *user = [[NIMSDK sharedSDK].userManager userInfo:userId];
    info.showName = user.userInfo.nickName;
    return info;
}

@end
