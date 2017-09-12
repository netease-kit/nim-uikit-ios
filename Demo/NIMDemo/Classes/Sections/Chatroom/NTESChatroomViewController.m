//
//  NTESChatroomViewController.m
//  NIM
//
//  Created by chris on 15/12/11.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomViewController.h"
#import "NTESChatroomConfig.h"
#import "NTESJanKenPonAttachment.h"
#import "NTESSessionMsgConverter.h"
#import "NTESChatroomManager.h"

@interface NTESChatroomViewController ()
{
    BOOL _isRefreshing;
}

@property (nonatomic,strong) NTESChatroomConfig *config;

@property (nonatomic,strong) NIMChatroom *chatroom;

@end

@implementation NTESChatroomViewController

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom
{
    self = [super initWithSession:[NIMSession session:chatroom.roomId type:NIMSessionTypeChatroom]];
    if (self) {
        _chatroom = chatroom;
    }
    return self;
}

- (void)dealloc
{
    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (id<NIMSessionConfig>)sessionConfig{
    return self.config;
}


- (BOOL)onTapCell:(NIMKitEvent *)event
{
    BOOL handled = [super onTapCell:event];
    NSString *eventName = event.eventName;
    if([eventName isEqualToString:NIMKitEventNameTapLabelLink] || [eventName isEqualToString:NIMKitEventNameTapRobotLink])
    {
       NSString *link = event.data;
       [self openSafari:link];
       handled = YES;
    }
    
    if (!handled)
    {
        NSAssert(0, @"invalid event");
    }
    return handled;
}


- (BOOL)onTapMediaItem:(NIMMediaItem *)item
{
    SEL  sel = item.selctor;
    BOOL response = [self respondsToSelector:sel];
    if (response) {
        SuppressPerformSelectorLeakWarning([self performSelector:sel withObject:item]);
    }
    return response;
}

- (void)onTapMediaItemJanKenPon:(NIMMediaItem *)item{
    NTESJanKenPonAttachment *attachment = [[NTESJanKenPonAttachment alloc] init];
    attachment.value = arc4random() % 3 + 1;
    [self sendMessage:[NTESSessionMsgConverter msgWithJenKenPon:attachment]];
}

- (void)sendMessage:(NIMMessage *)message
{
    NIMChatroomMember *member = [[NTESChatroomManager sharedInstance] myInfo:self.chatroom.roomId];
    message.remoteExt = @{@"type":@(member.type)};
    [super sendMessage:message];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        CGFloat offset = 44.f;
        if (self.tableView.contentOffset.y <= -offset && !_isRefreshing && self.tableView.isDragging) {
            _isRefreshing = YES;
            UIRefreshControl *refreshControl = [self findRefreshControl];
            [refreshControl beginRefreshing];
            [refreshControl sendActionsForControlEvents:UIControlEventValueChanged];
            [self.tableView endEditing:YES];
        }
        else if(self.tableView.contentOffset.y >= 0)
        {
            _isRefreshing = NO;
        }
    }
}

- (UIRefreshControl *)findRefreshControl
{
    for (UIRefreshControl *subView in self.tableView.subviews) {
        if ([subView isKindOfClass:[UIRefreshControl class]]) {
            return subView;
        }
    }
    return nil;
}


- (void)openSafari:(NSString *)link
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:link];
    if (components)
    {
        if (!components.scheme)
        {
            //默认添加 http
            components.scheme = @"http";
        }
        [[UIApplication sharedApplication] openURL:[components URL]];
    }
}


#pragma mark - Get
- (NTESChatroomConfig *)config{
    if (!_config) {
        _config = [[NTESChatroomConfig alloc] initWithChatroom:self.chatroom.roomId];
    }
    return _config;
}


@end
