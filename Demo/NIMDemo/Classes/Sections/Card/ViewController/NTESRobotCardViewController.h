//
//  NTESRobotCardViewController.h
//  NIM
//
//  Created by chrisRay on 2017/7/1.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMAvatarImageView.h"
#import "NTESColorButtonCell.h"

@interface NTESRobotCardViewController : UIViewController

@property (nonatomic,strong) IBOutlet NIMAvatarImageView *avatarImageView;

@property (nonatomic,strong) IBOutlet UILabel *userIdLabel;

@property (nonatomic,strong) IBOutlet UILabel *nickLabel;

@property (nonatomic,strong) IBOutlet UILabel *introLabel;

- (instancetype)initWithUserId:(NSString *)userId;

@end
