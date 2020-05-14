//
//  NIMReplyContentView.h
//  NIMKit
//
//  Created by He on 2020/4/3.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <M80AttributedLabel/M80AttributedLabel.h>


NS_ASSUME_NONNULL_BEGIN

@protocol NIMReplyContentViewDelegate <NSObject>

@optional
- (void)onClearReplyContent:(id)sender;

@end

@interface NIMReplyContentView : UIView

@property (nonatomic,strong) UIButton *closeButton;

@property (nonatomic,strong) UIView *divider;

@property (nonatomic,strong) M80AttributedLabel *label;

@property (nonatomic,weak) id<NIMReplyContentViewDelegate> delegate;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
