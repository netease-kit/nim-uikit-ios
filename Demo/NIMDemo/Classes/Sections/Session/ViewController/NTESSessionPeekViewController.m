//
//  NTESSessionPeekViewController.m
//  NIM
//
//  Created by chris on 2017/1/12.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESSessionPeekViewController.h"
#import "NIMSessionViewController.h"

@interface NTESSessionPeekViewController : NIMSessionViewController

@property (nonatomic,strong) id<NIMSessionConfig> config;

@end


@interface NTESSessionPeekNavigationViewController ()

@property (nonatomic,strong) NIMRecentSession *recent;

@end

@implementation NTESSessionPeekNavigationViewController

+ (instancetype)instance:(NIMSession *)session
{
    NTESSessionPeekViewController *vc = [[NTESSessionPeekViewController alloc] initWithSession:session];
    NTESSessionPeekNavigationViewController *nav = [[NTESSessionPeekNavigationViewController alloc] initWithRootViewController:vc];
    return nav;
}


- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        _recent = [self findRecentSession];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
}


- (NSArray<id<UIPreviewActionItem>> *)previewActionItems
{
    UIPreviewAction *action1 = [UIPreviewAction actionWithTitle:@"标记已读" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [[NIMSDK sharedSDK].conversationManager markAllMessagesReadInSession:self.recent.session];
    }];
    
    UIPreviewAction *action2 = [UIPreviewAction actionWithTitle:@"删除会话" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [[NIMSDK sharedSDK].conversationManager deleteRecentSession:self.recent];        
    }];

    return @[action1,action2];
}


- (NIMRecentSession *)findRecentSession
{
    NIMSessionViewController *vc = (NIMSessionViewController *)self.topViewController;
    NIMSession *session = vc.session;
    NSArray *recents = [NIMSDK sharedSDK].conversationManager.allRecentSessions;
    for (NIMRecentSession *recent in recents) {
        if ([recent.session.sessionId isEqualToString:session.sessionId] && recent.session.sessionType == session.sessionType) {
            return recent;
        }
    }
    return nil;
}


@end



@interface NTESSessionPeekSessionConfig : NSObject<NIMSessionConfig>

@end

@implementation  NTESSessionPeekViewController

- (instancetype)initWithSession:(NIMSession *)session
{
    self = [super initWithSession:session];
    if (self) {
        _config = [[NTESSessionPeekSessionConfig alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //预览的时候不显示未读红点
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.leftItemsSupplementBackButton = NO;
}

- (id<NIMSessionConfig>)sessionConfig
{
    return self.config;
}

@end


@implementation NTESSessionPeekSessionConfig

- (BOOL)disableAutoMarkMessageRead
{
    return YES;
}

@end

