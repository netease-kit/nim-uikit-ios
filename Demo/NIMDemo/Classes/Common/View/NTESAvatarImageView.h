//
//  AvatarImageView.h
//  NIMDemo
//
//  Created by chris on 15/2/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESAvatarImageView : UIControl

@property (nonatomic,strong)    UIImage *image;

@property (nonatomic,strong)    UIImage *hilghtedImage;

@property (nonatomic,assign)    BOOL    clipPath;

@end



@interface NTESAvatarImageView(NIMDemo)

+ (instancetype)demoInstanceRecentSessionList;  //Demo最近会话头像

+ (instancetype)demoInstanceContactDataList;    //Demo通讯录头像

+ (instancetype)demoInstanceTeamCardHeader;    //Demo讨论组名片头像

+ (instancetype)demoInstanceTeamMember;        //Demo高级群名片头像

+ (instancetype)demoInstanceUserList;          //Demo用户列表
@end
