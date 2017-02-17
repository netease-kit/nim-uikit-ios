//
//  NTESTimePickerView.h
//  NIM
//
//  Created by chris on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CompletionHandler)(NSInteger hour,NSInteger minute);

@protocol NIMTimePickerViewDelegate <NSObject>

- (void)didSelectHour:(NSInteger)hour minute:(NSInteger)minute;

@end

@interface NIMTimePickerView : UIView

@property (nonatomic,weak) id<NIMTimePickerViewDelegate> delegate;

- (void)refreshWithHour:(NSInteger)hour minute:(NSInteger)minute;

- (void)showInView:(UIView *)view onCompletion:(CompletionHandler) handler;

@end
