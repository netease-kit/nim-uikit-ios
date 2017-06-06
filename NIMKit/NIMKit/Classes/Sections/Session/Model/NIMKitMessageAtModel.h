//
//  NIMKitMessageAtModel.h
//  NIMKit
//
//  Created by chris on 2016/12/7.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NIMKitMessageAtData : NSObject

@property (nonatomic,strong) NSString *name;  //@消息用户在群中的群名

@property (nonatomic,strong) NSString *uid;   //@消息的用户ID

@property (nonatomic,assign) NSRange  range;  //@消息的range

@end


@interface NIMKitMessageAtInfo : NSObject

- (void)addSendAtMessageData:(NIMKitMessageAtData *)data;

- (NSRange)deleteTextWithRange:(NSRange)range
                          text:(NSString*)text;

- (void)addTextWithReplaceRange:(NSRange)replaceRange
                           text:(NSString*)text;

@end
