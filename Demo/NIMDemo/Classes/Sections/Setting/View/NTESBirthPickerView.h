//
//  NTESBirthPickerView.h
//  NIM
//
//  Created by chris on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CompletionHandler)(NSString *birth);

@protocol NTESBirthPickerViewDelegate <NSObject>

- (void)didSelectBirth:(NSString *)brith;

@end

@interface NTESBirthPickerView : UIView

@property (nonatomic,weak) id<NTESBirthPickerViewDelegate> delegate;

- (void)refreshWithBrith:(NSString *)birth;

- (void)showInView:(UIView *)view onCompletion:(CompletionHandler) handler;

@end
