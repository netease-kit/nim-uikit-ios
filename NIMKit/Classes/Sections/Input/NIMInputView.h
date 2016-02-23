//
//  NIMInputView.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMInputTextView.h"
#import "NIMInputProtocol.h"
#import "NIMSessionConfig.h"

@class NIMInputMoreContainerView;
@class NIMInputEmoticonContainerView;
@class NIMInputToolBar;

typedef NS_ENUM(NSInteger, NIMInputType){
    InputTypeText = 1,
    InputTypeEmot = 2,
    InputTypeAudio = 3,
    InputTypeMedia = 4,
};

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

@property (nonatomic, assign) NSInteger              maxTextLength;
@property (nonatomic, assign) CGFloat                inputBottomViewHeight;

@property (assign, nonatomic, getter=isRecording) BOOL recording;

@property (strong, nonatomic)  NIMInputToolBar *toolBar;
@property (strong, nonatomic)  NIMInputMoreContainerView *moreContainer;
@property (strong, nonatomic)  NIMInputEmoticonContainerView *emoticonContainer;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)setInputDelegate:(id<NIMInputDelegate>)delegate;

//外部设置
- (void)setInputActionDelegate:(id<NIMInputActionDelegate>)actionDelegate;
- (void)setInputConfig:(id<NIMSessionConfig>)config;

- (void)setInputTextPlaceHolder:(NSString*)placeHolder;
- (void)updateAudioRecordTime:(NSTimeInterval)time;
- (void)updateVoicePower:(float)power;

@end
