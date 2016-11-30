//
//  NIMSessionConfigurateProtocol.h
//  NIMKit
//
//  Created by chris on 2016/11/7.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#ifndef NIMSessionConfigurateProtocol_h
#define NIMSessionConfigurateProtocol_h

#import "NIMSDK.h"
#import "NIMMessageModel.h"

@protocol NIMSessionInteractorDelegate <NSObject>

- (void)didFetchMessageData;

- (void)didRefreshMessageData;


@end

@protocol NIMSessionInteractor <NSObject>

//网络接口
- (void)sendMessage:(NIMMessage *)message;

- (void)sendMessageReceipt:(NSArray *)messages;


//界面操作接口
- (void)addMessages:(NSArray *)messages;

- (NIMMessageModel *)updateMessage:(NIMMessage *)message;

- (NIMMessageModel *)deleteMessage:(NIMMessage *)message;


//数据接口
- (NSArray *)items;

- (NIMMessageModel *)findMessageModel:(NIMMessage *)message;

- (NIMMessageModel *)makeMessageModel:(NIMMessage *)message;

- (void)checkReceipt;

- (void)resetMessages;

- (void)loadMessages:(void (^)(NSArray *messages, NSError *error))handler;


//排版接口
- (void)resetLayout;

- (void)changeLayout:(CGFloat)inputHeight;

- (void)cleanCache;

- (void)checkLayoutConfig:(NIMMessageModel *)messageModel;


//按钮响应接口
- (void)mediaPicturePressed;

- (void)mediaShootPressed;

- (void)mediaLocationPressed;

@end

#endif /* NIMSessionConfigurateProtocol_h */
