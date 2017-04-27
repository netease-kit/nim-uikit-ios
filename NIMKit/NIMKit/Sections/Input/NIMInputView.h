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

@class NIMInputMoreContainerView;
@class NIMInputEmoticonContainerView;



typedef NS_ENUM(NSInteger, NIMAudioRecordPhase) {
    AudioRecordPhaseStart,
    AudioRecordPhaseRecording,
    AudioRecordPhaseCancelling,
    AudioRecordPhaseEnd
};





@protocol NIMInputDelegate <NSObject>

@optional

- (void)showInputView;
- (void)hideInputView;

- (void)inputViewSizeToHeight:(CGFloat)toHeight
                showInputView:(BOOL)show;
@end

@interface NIMInputView : UIView

@property (nonatomic, strong) NIMSession             *session;

@property (nonatomic, assign) NSInteger              maxTextLength;

@property (assign, nonatomic, getter=isRecording)    BOOL recording;

@property (strong, nonatomic)  NIMInputToolBar *toolBar;
@property (strong, nonatomic)  NIMInputMoreContainerView *moreContainer;
@property (strong, nonatomic)  NIMInputEmoticonContainerView *emoticonContainer;

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

@end
