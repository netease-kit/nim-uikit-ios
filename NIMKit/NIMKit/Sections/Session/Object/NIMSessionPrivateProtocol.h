//
//  NIMSessionPrivateProtocol.h
//  NIMKit
//
//  Created by chris on 2016/11/7.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#ifndef NIMSessionPrivateProtocol_h
#define NIMSessionPrivateProtocol_h

#import "NIMSessionViewController.h"

@class NIMMessage;
@class NIMMessageModel;

@interface NIMSessionMessageOperateResult : NSObject

@property (nonatomic,copy) NSArray *indexpaths;

@property (nonatomic,copy) NSArray *messageModels;

@end

@protocol NIMSessionDataSource <NSObject>

- (NSArray *)items;

- (NIMSessionMessageOperateResult *)addMessageModels:(NSArray *)models;

- (NIMSessionMessageOperateResult *)deleteMessageModel:(NIMMessageModel *)model;

- (NIMSessionMessageOperateResult *)updateMessageModel:(NIMMessageModel *)model;

- (NIMMessageModel *)findModel:(NIMMessage *)message;

- (NSInteger)indexAtModelArray:(NIMMessageModel *)model;

- (NSArray *)deleteModels:(NSRange)range;

- (void)resetMessages:(void(^)(NSError *error))handler;

- (void)loadHistoryMessagesWithComplete:(void(^)(NSInteger index, NSArray *messages , NSError *error))handler;

- (void)checkAttachmentState:(NSArray *)messages;

- (NSDictionary *)checkReceipt;

- (void)sendMessageReceipt:(NSArray *)messages;

- (void)cleanCache;

@end

@protocol NIMSessionLayout <NSObject>

- (void)update:(NSIndexPath *)indexPath;

- (void)insert:(NSArray *)indexPaths animated:(BOOL)animated;

- (void)remove:(NSArray *)indexPaths;

- (BOOL)canInsertChatroomMessages;

- (void)layoutConfig:(NIMMessageModel *)model;

- (void)resetLayout;

- (void)changeLayout:(CGFloat)inputViewHeight;

- (void)layoutAfterRefresh;

@end


@interface NIMSessionViewController(Interactor)

- (void)setInteractor:(id<NIMSessionInteractor>) interactor;

- (void)setTableDelegate:(id<UITableViewDelegate, UITableViewDataSource>) tableDelegate;

@end


#endif /* NIMSessionPrivateProtocol_h */
