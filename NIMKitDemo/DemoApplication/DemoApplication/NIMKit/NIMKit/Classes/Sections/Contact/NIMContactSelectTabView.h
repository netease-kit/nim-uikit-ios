//
//  NIMContactSelectTabView.h
//  NIMKit
//
//  Created by chris on 15/9/15.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NIMContactPickedView;

@interface NIMContactSelectTabView : UIView

@property (nonatomic,strong) NIMContactPickedView *pickedView;

@property (nonatomic,strong) UIButton *doneButton;

@end
