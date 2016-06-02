//
//  NIMGlobalDefs.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#ifndef NIMLib_NIMGlobalDefs_h
#define NIMLib_NIMGlobalDefs_h



/**
 *  消息内容类型枚举
 */
typedef NS_ENUM(NSInteger, NIMMessageType){
    /**
     *  文本类型消息
     */
    NIMMessageTypeText          = 0,
    /**
     *  图片类型消息
     */
    NIMMessageTypeImage         = 1,
    /**
     *  声音类型消息
     */
    NIMMessageTypeAudio         = 2,
    /**
     *  视频类型消息
     */
    NIMMessageTypeVideo         = 3,
    /**
     *  位置类型消息
     */
    NIMMessageTypeLocation      = 4,
    /**
     *  通知类型消息
     */
    NIMMessageTypeNotification  = 5,
    /**
     *  文件类型消息
     */
    NIMMessageTypeFile          = 6,
    /**
     *  提醒类型消息
     */
    NIMMessageTypeTip           = 10,
    /**
     *  自定义类型消息
     */
    NIMMessageTypeCustom        = 100
};


/**
 *  网络通话类型
 */
typedef NS_ENUM(NSInteger, NIMNetCallType){
    /**
     *  音频通话
     */
    NIMNetCallTypeAudio = 1,
    /**
     *  视频通话
     */
    NIMNetCallTypeVideo = 2,
};

/**
 *  网络通话视频质量
 */
typedef NS_ENUM(NSInteger, NIMNetCallVideoQuality) {
    /**
     *  默认视频质量
     */
    NIMNetCallVideoQualityDefault = 0,
    /**
     *  低视频质量
     */
    NIMNetCallVideoQualityLow     = 1,
    /**
     *  中等视频质量
     */
    NIMNetCallVideoQualityMedium  = 2,
    /**
     *  高视频质量
     */
    NIMNetCallVideoQualityHigh    = 3,
};



/**
 *  NIM本地Error Domain
 */
extern NSString *const NIMLocalErrorDomain;

/**
 *  NIM服务器Error Domain
 */
extern NSString *const NIMRemoteErrorDomain;



/**
 *  本地错误码
 */
typedef NS_ENUM(NSInteger, NIMLocalErrorCode) {
    /**
     *  错误的参数
     */
    NIMLocalErrorCodeInvalidParam                 = 1,
    /**
     *  多媒体文件异常
     */
    NIMLocalErrorCodeInvalidMedia                 = 2,
    /**
     *  图片异常
     */
    NIMLocalErrorCodeInvalidPicture               = 3,
    /**
     *  url异常
     */
    NIMLocalErrorCodeInvalidUrl                   = 4,
    /**
     *  读取/写入文件失败
     */
    NIMLocalErrorCodeIOError                      = 5,
    /**
     *  无效的token
     */
    NIMLocalErrorCodeInvalidToken                 = 6,
    /**
     *  Http请求失败
     */
    NIMLocalErrorCodeHttpReqeustFailed            = 7,
    /**
     *  无录音权限
     */
    NIMLocalErrorCodeAudioRecordErrorNoPermission = 8,
    /**
     *  录音初始化失败
     */
    NIMLocalErrorCodeAudioRecordErrorInitFailed   = 9,
    /**
     *  录音失败
     */
    NIMLocalErrorCodeAudioRecordErrorRecordFailed   = 10,
    /**
     *  播放初始化失败
     */
    NIMLocalErrorCodeAudioPlayErrorInitFailed     = 11,
    /**
     *  有正在进行的网络通话
     */
    NIMLocalErrorCodeNetCallBusy                  = 12,
    /**
     *  这一通网络通话已经被其他端处理过了
     */
    NIMLocalErrorCodeNetCallOtherHandled          = 13,
    /**
     *  SQL语句执行失败
     */
    NIMLocalErrorCodeSQLFailed                    = 14,
    /**
     *  音频设备初始化失败
     */
    NIMLocalErrorCodeAudioDeviceInitFailed        = 15,
    
    /**
     *  用户信息缺失 (未登录 或 未提供用户资料)
     */
    NIMLocalErrorCodeUserInfoNeeded               = 16,
    
    /**
     *  无法开始录制, 因为文件路径不合法
     */
    NIMLocalErrorCodeRecordInvalidFilePath       = 17,
    /**
     *  开始本地录制失败
     */
    NIMLocalErrorCodeRecordStartFailed           = 18,

    /**
     *  创建录制文件失败
     */
    NIMLocalErrorCodeRecordCreateFileFailed      = 19,
    
    /**
     *  初始化录制音频失败
     */
    NIMLocalErrorCodeRecordInitAudioFailed       = 20,
    
    /**
     *  初始化录制视频失败
     */
    NIMLocalErrorCodeRecordInitVideoFailed       = 21,
    
    /**
     *  开始写录制文件失败
     */
    NIMLocalErrorCodeRecordStartWritingFailed    = 22,
    
    /**
     *  结束本地录制失败
     */
    NIMLocalErrorCodeRecordStopFailed            = 23,
    
    /**
     *  写录制文件失败
     */
    NIMLocalErrorCodeRecordWritingFileFailed     = 24,
    
    /**
     *  空间不足，录制即将结束
     */
    NIMLocalErrorCodeRecordWillStopForLackSpace  = 25,
    
    /**
     *  聊天室不存在
     */
    NIMLocalErrorChatroomNotExists               = 26,
    
    /**
     *  操作尚未完成
     */
    NIMLocalErrorCodeOperationIncomplete         = 27,
    /**
     *  AppKey 缺失，未注册 AppKey 就进行登录行为之类的接口
     */
    NIMLocalErrorCodeAppKeyNeed                  = 28,
};




/**
 *  服务器错误码
 *  @discussion 更多错误详见 http://dev.netease.im/docs?doc=nim_status_code#服务器端状态码
 */
typedef NS_ENUM(NSInteger, NIMRemoteErrorCode) {
    /**
     *  客户端版本错误
     */
    NIMRemoteErrorCodeInvalidVersion      = 201,
    /**
     *  密码错误
     */
    NIMRemoteErrorCodeInvalidPass         = 302,
    /**
     *  CheckSum校验失败
     */
    NIMRemoteErrorCodeInvalidCRC          = 402,
    /**
     *  非法操作或没有权限
     */
    NIMRemoteErrorCodeForbidden           = 403,
    /**
     *  请求的目标（用户或对象）不存在
     */
    NIMRemoteErrorCodeNotExist            = 404,
    /**
     *  对象只读
     */
    NIMRemoteErrorCodeReadOnly            = 406,
    /**
     *  请求过程超时
     */
    NIMRemoteErrorCodeTimeoutError        = 408,
    /**
     *  参数错误
     */
    NIMRemoteErrorCodeParameterError      = 414,
    /**
     *  网络连接出现错误
     */
    NIMRemoteErrorCodeConnectionError     = 415,
    /**
     *  操作太过频繁
     */
    NIMRemoteErrorCodeFrequently          = 416,
    /**
     *  对象已经存在
     */
    NIMRemoteErrorCodeExist               = 417,
    /**
     *  账号被禁用
     */
    NIMRemoteErrorAccountBlock            = 422,
    /**
     *  未知错误
     */
    NIMRemoteErrorCodeUnknownError        = 500,
    /**
     *  服务器数据错误
     */
    NIMRemoteErrorCodeServerDataError     = 501,
    /**
     *  不足
     */
    NIMRemoteErrorCodeNotEnough           = 507,
    /**
     *  超过期限
     */
    NIMRemoteErrorCodeDomainExpireOld     = 508,
    /**
     *  无效协议
     */
    NIMRemoteErrorCodeInvalidProtocol     = 509,
    /**
     *  用户不存在
     */
    NIMRemoteErrorCodeUserNotExist        = 510,
    /**
     *  服务不可用
     */
    NIMRemoteErrorCodeServiceUnavailable  = 514,
    /**
     *  没有操作群的权限
     */
    NIMRemoteErrorCodeTeamAccessError     = 802,
    /**
     *  群组不存在
     */
    NIMRemoteErrorCodeTeamNotExists       = 803,
    /**
     *  用户不在兴趣组内
     */
    NIMRemoteErrorCodeNotInTeam           = 804,
    /**
     *  群类型错误
     */
    NIMRemoteErrorCodeTeamInvaildType     = 805,
    /**
     *  超出群成员个数限制
     */
    NIMRemoteErrorCodeTeamMemberLimit     = 806,
    /**
     *  已经在群里
     */
    NIMRemoteErrorCodeTeamAlreadyIn       = 809,
    /**
     *   不是群成员
     */
    NIMRemoteErrorCodeTeamNotMember       = 810,
    /**
     *  在群黑名单中
     */
    NIMRemoteErrorCodeTeamBlackList       = 812,
    /**
     *  解包错误
     */
    NIMRemoteErrorCodeEUnpacket           = 998,
    /**
     *  打包错误
     */
    NIMRemoteErrorCodeEPacket             = 999,
    
    /**
     *  被叫离线(无可送达的被叫方)
     */
    NIMRemoteErrorCodeCalleeOffline       = 11001,
    /**
     *  聊天室状态异常
     */
    NIMRemoteErrorCodeInvalidChatroom     = 13002,
    /**
     *  账号在黑名单中,不允许进入聊天室
     */
    NIMRemoteErrorCodeInChatroomBlackList = 13003,
    /**
     *  在禁言列表中,不允许发言
     */
    NIMRemoteErrorCodeInChatroomMuteList  = 13004,
};




#endif
