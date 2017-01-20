//
//  NTESSessionHistoryViewController.m
//  NIM
//
//  Created by chris on 15/4/22.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESSessionRemoteHistoryViewController.h"
#import "UIView+Toast.h"
#import "SVProgressHUD.h"
#import "NIMCellLayoutConfig.h"
#import "NTESBundleSetting.h"
#import "NTESCellLayoutConfig.h"

#pragma mark - Remote View Controller
@interface NTESSessionRemoteHistoryViewController ()<NTESRemoteSessionDelegate>

@property (nonatomic,strong) NTESRemoteSessionConfig *config;


@end

@implementation NTESSessionRemoteHistoryViewController

- (instancetype) initWithSession:(NIMSession *)session{
    self = [super initWithSession:session];
    if (self) {
        _config = [[NTESRemoteSessionConfig alloc] initWithSession:session];
        _config.delegate = self;
        self.disableCommandTyping = YES;
    }
    return self;
}

- (void)dealloc{
    [SVProgressHUD dismiss];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    //注册 NIMKit 自定义排版配置
    [[NIMKit sharedKit] registerLayoutConfig:[NTESCellLayoutConfig class]];

    self.navigationItem.leftBarButtonItems = @[];
    self.navigationItem.rightBarButtonItems = @[];
    [SVProgressHUD show];
}

- (NSString *)sessionTitle{
    return @"云消息记录";
}

- (id<NIMSessionConfig>)sessionConfig{
    return self.config;
}

- (NSArray *)menusItems:(NIMMessage *)message{
    return nil;
}

- (void)uiAddMessages:(NSArray *)messages{}

#pragma mark - NTESRemoteSessionDelegate
- (void)fetchRemoteDataError:(NSError *)error{
    if (error) {
        [self.view makeToast:@"获取消息失败" duration:2.0 position:CSToastPositionCenter];
    }
}

#pragma mark - NIMSessionConfiguratorDelegate
- (void)didFetchMessageData{
    [super didFetchMessageData];
    [SVProgressHUD dismiss];
}

@end



#pragma mark - Remote Session Config
@interface NTESRemoteSessionConfig()

@property (nonatomic,strong) NIMRemoteMessageDataProvider *provider;



@end

@implementation NTESRemoteSessionConfig

- (instancetype)initWithSession:(NIMSession *)session{
    self = [super init];
    if (self) {
        NSInteger limit = 20;
        self.provider = [[NIMRemoteMessageDataProvider alloc] initWithSession:session limit:limit];
    }
    return self;
}

- (void)setDelegate:(id<NTESRemoteSessionDelegate>)delegate{
    self.provider.delegate = delegate;
}

- (id<NIMKitMessageProvider>)messageDataProvider{
    return self.provider;
}

- (BOOL)disableAudioPlayedStatusIcon{
    return YES;
}

- (BOOL)disableProximityMonitor{
    return [[NTESBundleSetting sharedConfig] disableProximityMonitor];
}

- (BOOL)disableInputView{
    return YES;
}

//云消息不支持音频轮播
- (BOOL)disableAutoPlayAudio
{
    return YES;
}

//云消息不显示已读
- (BOOL)shouldHandleReceipt{
    return NO;
}

- (BOOL)disableReceiveNewMessages
{
    return YES;
}

@end




#pragma mark - Provider
@interface NIMRemoteMessageDataProvider(){
    NSMutableArray *_msgArray; //消息数组
    NSTimeInterval _lastTime;
}
@end


@implementation NIMRemoteMessageDataProvider

- (instancetype)initWithSession:(NIMSession *)session limit:(NSInteger)limit{
    self = [super init];
    if (self) {
        _limit = limit;
        _session = session;
    }
    return self;
}

- (void)pullDown:(NIMMessage *)firstMessage handler:(NIMKitDataProvideHandler)handler{
    [self remoteFetchMessage:firstMessage handler:handler];
}


- (void)remoteFetchMessage:(NIMMessage *)message
                   handler:(NIMKitDataProvideHandler)handler
{
    NIMHistoryMessageSearchOption *searchOpt = [[NIMHistoryMessageSearchOption alloc] init];
    searchOpt.startTime  = 0;
    searchOpt.endTime    = message.timestamp;
    searchOpt.currentMessage = message;
    searchOpt.limit      = self.limit;
    searchOpt.sync       = NO;
    [[NIMSDK sharedSDK].conversationManager fetchMessageHistory:self.session option:searchOpt result:^(NSError *error, NSArray *messages) {
        if (handler) {
            handler(error,messages.reverseObjectEnumerator.allObjects);
            if ([self.delegate respondsToSelector:@selector(fetchRemoteDataError:)]) {
                [self.delegate fetchRemoteDataError:error];
            }
        };
    }];
}

@end
