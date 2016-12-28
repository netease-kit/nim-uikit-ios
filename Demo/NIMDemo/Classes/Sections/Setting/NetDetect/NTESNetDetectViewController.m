//
//  NTESNetDetectViewController.m
//  NIM
//
//  Created by fenric on 16/12/20.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESNetDetectViewController.h"
#import "NIMAVChat.h"

@interface NTESNetDetectViewController ()
@property (weak, nonatomic) IBOutlet UITextView *netDetectResultTextView;

@property (assign, nonatomic) UInt64 taskId;

@end

@implementation NTESNetDetectViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"音视频网络探测";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStyleDone target:self action:@selector(onDismiss:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"探测" style:UIBarButtonItemStyleDone target:self action:@selector(onDetect:)];


}

- (void)onDismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onDetect:(id)sender {
    
    if (self.taskId == 0) {
        __weak typeof (self) wself = self;
        self.taskId = [[NIMSDK sharedSDK].avchatNetDetectManager startDetectTask:^(NIMAVChatNetDetectResult * _Nonnull result) {
            wself.netDetectResultTextView.text = [NSString stringWithFormat:@"%@net detect result:\n%@\n------------\n", wself.netDetectResultTextView.text, result];
            wself.taskId = 0;
            [wself updateDetectButton];
        }];
        self.netDetectResultTextView.text = [self.netDetectResultTextView.text stringByAppendingString:[NSString stringWithFormat:@"start net detect task id %llu \n------------\n", self.taskId]];
    }
    else {
        self.netDetectResultTextView.text = [self.netDetectResultTextView.text stringByAppendingString:[NSString stringWithFormat:@"stop net detect task id %llu \n------------\n", self.taskId]];
        [[NIMSDK sharedSDK].avchatNetDetectManager stopDetectTask:self.taskId];
        self.taskId = 0;
    }
    
    [self updateDetectButton];
}

- (void)updateDetectButton
{
    self.navigationItem.leftBarButtonItem.title = (self.taskId == 0) ? @"探测" : @"停止";
}


@end
