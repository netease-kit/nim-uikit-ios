//
//  NIMInputAudioRecordIndicatorView.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputView.h"

@interface NIMInputAudioRecordIndicatorView : UIView

@property (nonatomic, assign) NIMAudioRecordPhase phase;

@property (nonatomic, assign) NSTimeInterval recordTime;

@end
