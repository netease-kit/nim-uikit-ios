//
//  JrmfPacket.h
//  JrmfPacketKit
//
//  Created by 一路财富 on 16/8/24.
//  Copyright © 2016年 JYang. All rights reserved.
//

//  注：IM红包类方法

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum jrmfSendStatus {
    kjrmfStatCancel = 0,     // 取消发送，用户行为
    kjrmfStatSucess = 1,     // 红包发送成功
    kjrmfStatUnknow,         // 其他
}jrmfSendStatus;

@protocol jrmfManagerDelegate <NSObject>

/**
 *  红包发送回调
 *
 *  @param envId    红包ID
 *  @param envName  红包名称
 *  @param envMsg   描述信息
 *  @param jrmfStat 发送状态
 */
- (void)dojrmfActionDidSendEnvelopedWithID:(NSString *)envId Name:(NSString *)envName Message:(NSString *)envMsg Stat:(jrmfSendStatus)jrmfStat;


@optional

/**
 *  成功领取了一个红包回调
 *
 *  @param isDone 是否为最后一个红包；YES：领取的为最后一个红包；NO：红包未被领取完成
 *
 *  @discussion     此函数调用时，一定是成功领取了一个红包；只有红包个数>=2的时候，isDone才有效，群红包个数为1个时，默认为NO
 */
- (void)dojrmfActionOpenPacketSuccessWithGetDone:(BOOL)isDone;

@end

@interface JrmfPacket : NSObject

@property (nonatomic, assign) id <jrmfManagerDelegate> delegate;

/**
 *  发红包/钱包 页面标题字号 Default:18.f
 */
@property (nonatomic, assign) float titleFont;

/**
 *  发红包/钱包 页面'标题栏'颜色 支持@“#123456”、 @“0X123456”、 @“123456”三种格式
 */
@property (nonatomic, strong) NSString * packetRGB;

/**
 *  发红包/钱包 页面'标题'颜色 支持@“#123456”、 @“0X123456”、 @“123456”三种格式
 */
@property (nonatomic, strong) NSString * titleColorRGB;

/**
 JrmfSDK 注册方法

 @param partnerId            渠道名称（我们公司分配给你们的渠道字符串）
 @param envName              红包名称
 @param aliPaySchemeUrl      支付宝回调Scheme【保证格式的正确性】
 @param weChatSchemeUrl      微信回调Scheme
 @param isOnLine             是否正式环境 YES：正式环境    NO：测试环境
 */
+ (void)instanceJrmfPacketWithPartnerId:(NSString *)partnerId EnvelopeName:(NSString *)envName aliPaySchemeUrl:(NSString *)aliPayscheme weChatSchemeUrl:(NSString *)weChatScheme appMothod:(BOOL)isOnLine;

/**
 *  用户信息更新
 *
 *  aram userId             用户ID（app用户的唯一标识）
 *  @param userName         用户昵称
 *  @param userHeadLink     用户头像
 *  @param thirdToken       三方签名令牌
 *  @param completionAction 回调函数
 *
 *  @discussion      A.用户昵称、头像可单独更新，非更新是传nil即可，但不可两者同时为nil；三方签名令牌（服务端计算后给到app，服务端算法为md5（custUid+appsecret））
 *                   B.头像的URL连接字符不要过长，不超过256个字符为宜。（所有头像链接都需要限制）【注:外网可访问】【下同】
 */
+ (void)updateUserMsgWithUserId:(NSString *)userId userName:(NSString *)userName userHead:(NSString *)userHeadLink thirdToken:(NSString *)thirdToken completion:(void (^)(NSError *error, NSDictionary *resultDic))completionAction;

/**
 *  发红包
 *
 *  @param viewController 当前视图
 *  @param thirdToken     三方签名令牌
 *  @param isGroup        是否为群组红包
 *  @param receiveID      接受者ID（单人红包：接受者用户唯一标识；群红包：群组ID，唯一标识）
 *  @param userName       发送者昵称
 *  @param userHeadLink   发送者头像链接
 *  @param userId         发送者ID
 *  @param groupNum       群人数(个人红包可不传)
 *
 *  @discussion      三方签名令牌（服务端计算后给到app，服务端算法为md5（custUid+appsecret））
 */
- (void)doActionPresentSendRedEnvelopeViewController:(UIViewController *)viewController thirdToken:(NSString *)thirdToken withGroup:(BOOL)isGroup receiveID:(NSString *)receiveID sendUserName:(NSString *)userName sendUserHead:(NSString *)userHeadLink sendUserID:(NSString *)userId groupNumber:(NSString *)groupNum;

/**
 *  拆红包
 *
 *  @param viewController   当前视图
 *  @param thirdToken       三方签名令牌
 *  @param userName         当前操作用户姓名
 *  @param userHeadLink     头像链接
 *  @param userId           当前操作用户ID
 *  @param envelopeId       红包ID
 *  @param isGroup          是否为群组红包 
 *
 *  @discussion      三方签名令牌（服务端计算后给到app，服务端算法为md5（custUid+appsecret））
 */
- (void)doActionPresentOpenViewController:(UIViewController *)viewController thirdToken:(NSString *)thirdToken withUserName:(NSString *)userName userHead:(NSString *)userHeadLink userID:(NSString *)userId envelopeID:(NSString *)envelopeId isGroup:(BOOL)isGroup;

/**
 查看红包领取详情

 @param userId          用户ID
 @param packetId        红包ID
 @param thirdToken      三方签名令牌
 */
- (void)doActionPresentPacketDetailInViewWithUserID:(NSString *)userId packetID:(NSString *)packetId thirdToken:(NSString *)thirdToken;

/**
 查看收支明细

 @param userId          用户ID
 @param thirdToken      三方签名令牌
 */
- (void)doActionPresentPacketListInViewWithUserID:(NSString *)userId thirdToken:(NSString *)thirdToken;


/**
 *  支付宝支付完成时，回调函数
 */
+ (void)doActionAlipayDone;


/**
 销毁扩展模块
 */
+ (void)destroyPacketModule;

/**
 *  版本号
 *
 *  @return 获取当前版本
 */
+ (NSString *)getCurrentVersion;


@end
