//
//  NIMInputView.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMInputProtocol.h"
#import "NIMSessionConfig.h"
#import "NIMInputToolBar.h"
#import "NIMInputAtCache.h"

@class NIMInputMoreContainerView;
@class NIMInputEmoticonContainerView;
@class NIMReplyContentView;



typedef NS_ENUM(NSInteger, NIMAudioRecordPhase) {
    AudioRecordPhaseStart,
    AudioRecordPhaseRecording,
    AudioRecordPhaseCancelling,
    AudioRecordPhaseEnd
};



@protocol NIMInputDelegate <NSObject>

@optional

- (void)didChangeInputHeight:(CGFloat)inputHeight;

@end

@interface NIMInputView : UIView

@property (nonatomic, strong) NIMSession             *session;

@property (nonatomic, assign) NSInteger              maxTextLength;

@property (assign, nonatomic, getter=isRecording)    BOOL recording;

@property (strong, nonatomic)  NIMInputToolBar *toolBar;
@property (strong, nonatomic)  UIView *moreContainer;
@property (strong, nonatomic)  UIView *emoticonContainer;

@property (nonatomic, strong)   NIMReplyContentView *replyedContent;

@property (nonatomic, assign) NIMInputStatus status;
@property (nonatomic, strong) NIMInputAtCache *atCache;

- (instancetype)initWithFrame:(CGRect)frame
                       config:(id<NIMSessionConfig>)config;

- (void)reset;

- (void)refreshStatus:(NIMInputStatus)status;

- (void)setInputDelegate:(id<NIMInputDelegate>)delegate;

//外部设置
- (void)setInputActionDelegate:(id<NIMInputActionDelegate>)actionDelegate;

- (void)setInputTextPlaceHolder:(NSString*)placeHolder;
- (void)updateAudioRecordTime:(NSTimeInterval)time;
- (void)updateVoicePower:(float)power;
- (void)addAtItems:(NSArray *)contacts;

- (void)refreshReplyedContent:(NIMMessage *)message;
- (void)dismissReplyedContent;

@end
