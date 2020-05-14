//
//  NIMChatUIManager.m
//  NIMKit
//
//  Created by 丁文超 on 2020/3/19.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMChatUIManager.h"
#import "NIMContactSelectConfig.h"
#import "NIMContactSelectViewController.h"
#import "NIMKitInfoFetchOption.h"
#import "UIView+NIMToast.h"

@implementation NIMChatUIManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static NIMChatUIManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [self.alloc init];
    });
    return instance;
}

- (void)forwardMessage:(NIMMessage *)message fromViewController:(UIViewController *)fromVC
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"选择会话类型", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"个人", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NIMContactFriendSelectConfig *config = [[NIMContactFriendSelectConfig alloc] init];
        config.needMutiSelected = NO;
        NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
        vc.finshBlock = ^(NSArray *array){
            NSString *userId = array.firstObject;
            NIMSession *session = [NIMSession session:userId type:NIMSessionTypeP2P];
            [self forwardMessage:message toSession:session fromViewController:fromVC];
        };
        [vc show];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"群组", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NIMContactTeamSelectConfig *config = [[NIMContactTeamSelectConfig alloc] init];
        config.teamType = NIMKitTeamTypeNomal;
        NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
        vc.finshBlock = ^(NSArray *array){
            NSString *teamId = array.firstObject;
            NIMSession *session = [NIMSession session:teamId type:NIMSessionTypeTeam];
            [self forwardMessage:message toSession:session fromViewController:fromVC];
        };
        [vc show];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"超大群组", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NIMContactTeamSelectConfig *config = [[NIMContactTeamSelectConfig alloc] init];
        config.teamType = NIMKitTeamTypeSuper;
        NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
        vc.finshBlock = ^(NSArray *array){
            NSString *teamId = array.firstObject;
            NIMSession *session = [NIMSession session:teamId type:NIMSessionTypeSuperTeam];
            [self forwardMessage:message toSession:session fromViewController:fromVC];
        };
        [vc show];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:nil]];
    [fromVC presentViewController:alertController animated:YES completion:nil];
}

- (void)forwardMessage:(NIMMessage *)message toSession:(NIMSession *)session fromViewController:(UIViewController *)fromVC
{
    NSString *name;
    if (session.sessionType == NIMSessionTypeP2P) {
        NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
        option.session = session;
        name = [[NIMKit sharedKit] infoByUser:session.sessionId option:option].showName;
    }
    else if (session.sessionType == NIMSessionTypeTeam) {
        name = [[NIMKit sharedKit] infoByTeam:session.sessionId option:nil].showName;
    }
    else if (session.sessionType == NIMSessionTypeSuperTeam) {
        name = [[NIMKit sharedKit] infoBySuperTeam:session.sessionId option:nil].showName;
    }
    NSString *tip = [NSString stringWithFormat:@"%@ %@ ?", NSLocalizedString(@"确认转发给", nil), name];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"确认转发", nil) message:tip preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"确认", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSError *error = nil;
        if (message.session) {
            [[NIMSDK sharedSDK].chatManager forwardMessage:message toSession:session error:&error];
        } else {
            [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:&error];
        }
        if (error) {
            NSString *errorMessage = [NSString stringWithFormat:@"%@.code:%zd", NSLocalizedString(@"转发失败", nil), error.code];
            [fromVC.view nim_showToast:errorMessage duration:2.0];
        } else {
            [fromVC.view nim_showToast:NSLocalizedString(@"已发送", nil) duration:2.0];
        }
    }]];
    [fromVC presentViewController:alertController animated:YES completion:nil];
}

@end
