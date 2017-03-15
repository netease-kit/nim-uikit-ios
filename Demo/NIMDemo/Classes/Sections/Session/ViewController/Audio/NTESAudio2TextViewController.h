//
//  NTESAudio2TextViewController.h
//  NIM
//
//  Created by amao on 7/10/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NTESAudio2TextViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIButton *cancelBtn;

@property (nonatomic,strong) IBOutlet UIView *errorTipView;

@property (nonatomic,copy)   void (^completeHandler)(void)  ;

- (instancetype)initWithMessage:(NIMMessage *)message;

@end
