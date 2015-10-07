//
//  NIMCustomObject.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMMessageObjectProtocol.h"


/*
 除了 SDK 预定义的几种消息类型，上层APP开发者如果想要实现更多的消息类型，不可避免需要使用自定义消息这种类型
 由于 SDK 并不能预测上层 APP 的应用场景，所以 NIMCustomObject 采取消息透传的方式以提供给上层开发者最大的自由度
 即 SDK 只负责发送和收取由 NIMCustomObject 中 id<NIMCustomAttachment> attachment 序列化和反序列化后的字节流
 在发送端,SDK 获取 encodeAttachment 后得到的字节流发送至对面端
 在接收端,SDK 读取字节流，并通过上层 APP 设置的反序列化对象进行解析 (registerCustomDecoder:)

文件上传:
 为了方便 APP 在自定义消息类型中进行文件的上传，SDK 也提供了三个接口文件上传
 即只要 APP 实现上传相关的接口，资源的上传就可以由 SDK 自动完成
 如需要上传资源需要实现的接口有：
 1. - (BOOL)attachmentNeedsUpload  是否有文件需要上传,在有文件且文件没有上传成功时返回YES
 2. - (NSString *)attachmentPathForUploading  返回需要上传的文件路径
 3. - (void)updateAttachmentURL:(NSString *)urlString 上传成功后SDK会调用这个接口,APP 需要实现这个接口来保存上传后的URL
 具体可以参考 DEMO 中阅后即焚的实现
 
服务器配置:
 为了满足更丰富的用户场景，自定义消息的服务器存储也做了不同的配置：
 
 1.- (BOOL)messageHistoryEnabled  是否支持在消息历史中拉取当前这条消息,默认为YES。正常而言所有消息都会出现在通过 NIMConversationManager 调用(fetchMessageHistory:option:result:)返回的结果中，但是可以通过设置这个值来使得消息不出现在这其中。
 
 2.- (BOOL)meessageRoamingEnabled 是否支持消息漫游，默认为YES。消息漫游的概念是指一定时间内发送的消息可以在另一端被同步到，以保证最大限度的消息同步。
 
 3.- (BOOL)messageSyncEnabled 是否支持多端消息同步，默认为YES。在默认情况下，如果用户在 iOS端和其他端（如PC）同时登录一个帐号，那么iOS 端发送的消息会被同步到其他端，同样其他端发送的消息也会被同步到 iOS 端。但是需要注意的是因为 iOS 经常会退到后台，所以其他端发送的消息在 iOS 断线后是通过漫游消息来同步到的。
 
 以阅后即焚为例，一般而言为了保证阅后即焚的消息的安全，可以设置为不支持消息历史拉取和不支持漫游，这样用户就无法通过一些极端手段重新查看到当前消息，如重装 APP 后会漫游到已经阅后即焚的消息。

 */



/**
 *  自定义消息对象附件协议
 */
@protocol NIMCustomAttachment <NSObject>
@required

/**
 *  序列化attachment
 *
 *  @return 序列化后的结果，将用于透传
 */
- (NSString *)encodeAttachment;

@optional
#pragma mark - 上传相关接口
/**
 *  是否需要上传附件
 *
 *  @return 是否需要上传附件
 */
- (BOOL)attachmentNeedsUpload;

/**
 *  需要上传的附件路径
 *
 *  @return 路径
 */
- (NSString *)attachmentPathForUploading;

/**
 *  更新附件URL
 *
 *  @param urlString 附件url
 */
- (void)updateAttachmentURL:(NSString *)urlString;

#pragma mark - 下载相关接口
/**
 *  是否需要下载附件
 *
 *  @return 是否需要上传附件
 */
- (BOOL)attachmentNeedsDownload;

/**
 *  需要下载的附件url
 *
 *  @return 附件url
 */
- (NSString *)attachmentURLStringForDownload;


/**
 *  更新附件本地存储路径
 *
 *  @param path 下载的附件存储路径
 */
- (void)downloadAttachmentPath:(NSString *)path;

#pragma mark - 服务器存储相关接口
/**
 *  是否允许在消息历史中拉取
 *
 *  @return 是否允许在消息历史中拉取
 */
- (BOOL)messageHistoryEnabled;

/**
 *  是否支持漫游
 *
 *  @return 是否支持漫游
 */
- (BOOL)messageRoamingEnabled;

/**
 *  是否支持多端同步
 *
 *  @return 是否支持多端同步
 */
- (BOOL)messageSyncEnabled;
@end



/**
 *  自定义消息对象附件序列化协议
 */
@protocol NIMCustomAttachmentCoding<NSObject>
@required

/**
 *  反序列化
 *
 *  @param content 透传的自定义消息
 *
 *  @return 自定义消息附件
 */
- (id<NIMCustomAttachment>)decodeAttachment:(NSString *)content;
@end


/**
 *  用户自定义消息对象
 */
@interface NIMCustomObject : NSObject<NIMMessageObject>

/**
 *  用户自定义附件
 *  @discussion SDK负责将attachment通过encodeAttachment接口序列化后的结果进行透传
 */
@property(nonatomic, strong) id<NIMCustomAttachment>  attachment;


/**
 *  注册自定义消息解析器
 *
 *  @param decoder 自定义消息解析器
 *  @disucssion 如果用户使用自定义消息类型,就需要注册自定义消息解析器，负责将透传过来的自定义消息反序列化成上层应用可识别的对象
 */
+ (void)registerCustomDecoder:(id<NIMCustomAttachmentCoding>)decoder;

@end




