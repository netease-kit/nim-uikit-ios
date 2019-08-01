//
//  NIMContactDefines.h
//  NIM
//
//  Created by chris on 15/2/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//
#import <UIKit/UIKit.h>

@protocol NIMGroupMemberProtocol <NSObject>

- (NSString *)groupTitle;

- (NSString *)memberId;

- (NSString *)showName;

- (NSString *)avatarUrlString;

- (UIImage *)avatarImage;

- (id)sortKey;

@end

@protocol NIMContactItemCollection <NSObject>

//显示的title名
- (NSString*)title;

//返回集合里的成员
- (NSArray*)members;

//重用id
- (NSString*)reuseId;

//需要构造的cell类名
- (NSString*)cellName;

@end


#ifndef NIM_NTESContactCellLayoutConstant_h
#define NIM_NTESContactCellLayoutConstant_h
static const CGFloat   NIMContactUtilRowHeight             = 57;//util类Cell行高
static const CGFloat   NIMContactDataRowHeight             = 50;//data类Cell行高
static const NSInteger NIMContactAccessoryLeft             = 10;//选择框到左边的距离
static const NSInteger NIMContactAvatarLeft                = 10;//没有选择框的时候，头像到左边的距离
static const NSInteger NIMContactAvatarAndAccessorySpacing = 10;//头像和选择框之间的距离
static const NSInteger NIMContactAvatarAndTitleSpacing     = 20;//头像和文字之间的间距

#endif

