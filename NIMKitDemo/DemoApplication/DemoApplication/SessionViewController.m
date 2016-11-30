//
//  SessionViewController.m
//  DemoApplication
//
//  Created by chris on 15/10/7.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "SessionViewController.h"
#import "SessionConfig.h"
#import "Attachment.h"

@interface SessionViewController ()

@property (nonatomic,strong) SessionConfig *config;

@end

@implementation SessionViewController

- (instancetype)initWithSession:(NIMSession *)session
{
    self = [super initWithSession:session];
    if (self) {
        _config = [[SessionConfig alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (NSString *)sessionTitle{
    return @"聊天";
}

- (id<NIMSessionConfig>)sessionConfig{
    return self.config;
}


#pragma mark - Private
- (void)sendCustomMessage{
    //构造自定义内容
    Attachment *attachment = [[Attachment alloc] init];
    attachment.title = @"这是一条自定义消息";
    attachment.subTitle = @"这是自定义消息的副标题";
    
    //构造自定义MessageObject
    NIMCustomObject *object = [[NIMCustomObject alloc] init];
    object.attachment = attachment;
    
    //构造自定义消息
    NIMMessage *message = [[NIMMessage alloc] init];
    message.messageObject = object;
    
    //发送消息
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:self.session error:nil];
}

@end
