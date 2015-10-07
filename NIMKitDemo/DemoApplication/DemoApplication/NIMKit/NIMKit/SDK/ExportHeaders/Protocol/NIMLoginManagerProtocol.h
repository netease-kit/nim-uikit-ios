//
//  NIMLoginManagerProtocol.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMLoginClient.h"

/**
 *  登录服务相关Block
 *
 *  @param error 执行结果,如果成功error为nil
 */
typedef void(^NIMLoginHandler)(NSError *error);

/**
 *  登录步骤枚举
 */
typedef NS_ENUM(NSInteger, NIMLoginStep)
{
    /**
     *  连接服务器
     */
    NIMLoginStepLinking = 1,
    /**
     *  连接服务器成功
     */
    NIMLoginStepLinkOK,
    /**
     *  连接服务器失败
     */
    NIMLoginStepLinkFailed,
    /**
     *  登录
     */
    NIMLoginStepLogining,
    /**
     *  登录成功
     */
    NIMLoginStepLoginOK,
    /**
     *  登录失败
     */
    NIMLoginStepLoginFailed,
    /**
     *  开始同步
     */
    NIMLoginStepSyncing,
    /**
     *  同步完成
     */
    NIMLoginStepSyncOK,
    /**
     *  网络切换
     *  @discussion 这个并不是登录步骤的一种,但是UI有可能需要通过这个状态进行UI展现
     */
    NIMLoginStepNetChanged,
};

/**
 *  被踢下线的原因
 */
typedef NS_ENUM(NSInteger, NIMKickReason)
{
    /**
     *  被另外一个客户端踢下线 (互斥客户端一端登录挤掉上一个登录中的客户端)
     */
    NIMKickReasonByClient = 1,
    /**
     *  被服务器踢下线
     */
    NIMKickReasonByServer = 2,
    /**
     *  被另外一个客户端手动选择踢下线
     */
    NIMKickReasonByClientManually   = 3,
};

/**
 *  登录相关回调
 */
@protocol NIMLoginManagerDelegate <NSObject>

@optional
/**
 *  被踢(服务器/其他端)回调
 *
 *  @param code        被踢原因
 *  @param clientType  发起踢出的客户端类型
 */
- (void)onKick:(NIMKickReason)code clientType:(NIMLoginClientType)clientType;

/**
 *  登录回调
 *
 *  @param step 登录步骤
 *  @discussion 这个回调主要用于客户端UI的刷新
 */
- (void)onLogin:(NIMLoginStep)step;

/**
 *  自动登录失败回调
 *
 *  @param error 失败原因
 */
- (void)onAutoLoginFailed:(NSError *)error;

/**
 *  多端登录发生变化
 */
- (void)onMultiLoginClientsChanged;
@end

/**
 *  登录协议
 */
@protocol NIMLoginManager <NSObject>

/**
 *  登录
 *
 *  @param account    帐号
 *  @param token      令牌 (在后台绑定的登录token)
 *  @param completion 完成回调
 */
- (void)login:(NSString *)account
        token:(NSString *)token
   completion:(NIMLoginHandler)completion;


/**
 *  自动登录
 *
 *  @param account    帐号
 *  @param token      令牌 (在后台绑定的登录token)
 *  @discussion 启动APP如果已经保存了用户帐号和令牌,建议使用这个登录方式,使用这种方式可以在无网络时直接打开会话窗口
 */
- (void)autoLogin:(NSString *)account
            token:(NSString *)token;
/**
 *  登出
 *
 *  @param completion 完成回调
 */
- (void)logout:(NIMLoginHandler)completion;

/**
 *  踢人
 *
 *  @param client     当前登录的其他帐号
 *  @param completion 完成回调
 */
- (void)kickOtherClient:(NIMLoginClient *)client
             completion:(NIMLoginHandler)completion;

/**
 *  返回当前登录帐号
 *
 *  @return 当前登录帐号,如果没有登录成功,这个地方会返回nil
 */
- (NSString *)currentAccount;

/**
 *  返回当前登录的设备列表
 *
 *  @return 当前登录设备列表 内部是NIMLoginClient,不包括自己
 */
- (NSArray *)currentLoginClients;

/**
 *  添加登录委托
 *
 *  @param delegate 登录委托
 */
- (void)addDelegate:(id<NIMLoginManagerDelegate>)delegate;

/**
 *  移除登录委托
 *
 *  @param delegate 登录委托
 */
- (void)removeDelegate:(id<NIMLoginManagerDelegate>)delegate;
@end
