//
//  JrmfWalletSDK.h
//  JrmfWalletKit
//
//  Created by 一路财富 on 16/10/17.
//  Copyright © 2016年 JYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JrmfWalletSDK : NSObject

/**
 标准字体大小，默认14.f;
 */
@property (nonatomic, assign) CGFloat themeFontSize;

/**
 钱包页顶部主题色，默认#157EFB
 */
@property (nonatomic, strong) UIColor * themePageColor;

/**
 钱包页，充值、提现按钮颜色，默认#0665D6
 */
@property (nonatomic, strong) UIColor * pageBtnColor;

/**
 按钮主题色，默认#157EFB
 */
@property (nonatomic, strong) UIColor * themeBtnColor;

/**
 Navigation主题色，默认#157EFB
 */
@property (nonatomic, strong) UIColor * themeNavColor;

/**
 标题颜色，默认白色
 */
@property (nonatomic, strong) UIColor * NavTitColor;

/**
 标题栏字体大小，默认16.f
 */
@property (nonatomic, assign) CGFloat NavTitfontSize;

/**
 首页金额大小，默认22.f
 */
@property (nonatomic, assign) CGFloat pageChargeFont;

/**
 钱包标题，默认“我的钱包”
 */
@property (nonatomic, strong) NSString * pageTitleStr;


/**
 初始化函数
 
 @param partnerId 渠道ID（我们分配给贵公司的渠道名称）
 @param isOnline  测试环境  默认NO：测试环境
 */
+ (void)instanceJrmfWalletSDKWithPartnerId:(NSString *)partnerId AppMethod:(BOOL)isOnline;

/**
 调用钱包页面

 @param baseViewController  基础视图
 @param userId              当前用户ID（接入方app用户的唯一标识）
 @param userName            用户昵称
 @param avatarLink          用户头像链接
 @param thirdToken          第三方签名令牌
 
 @discussion      A.三方签名令牌（服务端计算后给到app，服务端算法为md5（custUid+appsecret））
 @discussion      B.用户头像字符串限制在260个字符内
 */
- (void)doPresentJrmfWalletPageWithBaseViewController:(UIViewController *)baseViewController userId:(NSString *)userId userName:(NSString *)userName userHeadLink:(NSString *)avatarLink thirdToken:(NSString *)thirdToken;

/**
 销毁扩展模块
 */
+ (void)destroyWalletModule;

/**
 获取当前版本
 
 @return 版本号
 */
+ (NSString *)getCurrentVersion;

@end
