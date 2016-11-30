//
//  NIMLoadProgressView.h
//  NIM
//
//  Created by ios on 13-11-9.
//  Copyright (c) 2013年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - LoadProgressView
@interface NIMLoadProgressView : UIView {
    UIImageView             *_maskView;
    UILabel                 *_progressLabel;
    UIActivityIndicatorView *_activity;
}

@property (nonatomic, assign)CGFloat maxProgress;

- (void)setProgress:(CGFloat)progress;

@end

