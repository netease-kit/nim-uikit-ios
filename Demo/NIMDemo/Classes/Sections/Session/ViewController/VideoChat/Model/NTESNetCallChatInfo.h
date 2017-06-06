//
//  NTESNetCallChatInfo.h
//  NIM
//
//  Created by chris on 15/5/12.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTESNetCallChatInfo : NSObject

@property(nonatomic,strong) NSString *caller;

@property(nonatomic,strong) NSString *callee;

@property(nonatomic,assign) UInt64 callID;

@property(nonatomic,assign) NIMNetCallMediaType callType;

@property(nonatomic,assign) NSTimeInterval startTime;

@property(nonatomic,assign) BOOL isStart;

@property(nonatomic,assign) BOOL isMute;

@property(nonatomic,assign) BOOL useSpeaker;

@property(nonatomic,assign) BOOL disableCammera;

@property(nonatomic,assign) BOOL localRecording;

@property(nonatomic,assign) BOOL otherSideRecording;

@property(nonatomic,assign) BOOL audioConversation;

@end
