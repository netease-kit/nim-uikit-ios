//
//  NTESTeamMeetingViewController.h
//  NIM
//
//  Created by chris on 2017/5/2.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NTESTeamMeetingCallerInfo;

@class NTESTeamMeetingCalleeInfo;

@interface NTESTeamMeetingViewController : UIViewController

@property (nonatomic,strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic,strong) IBOutlet UILabel *durationLabel;

@property (nonatomic,strong) IBOutlet UIButton *cameraSwitchButton;

@property (nonatomic,strong) IBOutlet UIButton *cameraDisableButton;

@property (nonatomic,strong) IBOutlet UIButton *micDisableButton;

@property (nonatomic,strong) IBOutlet UIButton *speakerDisableButton;

@property (nonatomic,strong) IBOutlet UIButton *muteButton;

@property (nonatomic,strong) IBOutlet UIButton *hangupButton;

- (instancetype)initWithCallerInfo:(NTESTeamMeetingCallerInfo *)info;

- (instancetype)initWithCalleeInfo:(NTESTeamMeetingCalleeInfo *)info;


@end


