//
//  NTESNotificationCenter.m
//  NIM
//
//  Created by Xuhui on 15/3/25.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESNotificationCenter.h"
#import "NTESVideoChatViewController.h"
#import "NTESAudioChatViewController.h"
#import "NTESMainTabController.h"
#import "NTESSessionViewController.h"
#import "NSDictionary+NTESJson.h"
#import "NTESCustomNotificationDB.h"
#import "NTESCustomNotificationObject.h"
#import "UIView+Toast.h"
#import "NTESWhiteboardViewController.h"
#import "NTESCustomSysNotificationSender.h"
#import "NTESGlobalMacro.h"
#import <AVFoundation/AVFoundation.h>
#import "NTESLiveViewController.h"
#import "NTESSessionMsgConverter.h"
#import "NTESSessionUtil.h"
#import "NTESTeamMeetingCallingViewController.h"
#import "NTESTeamMeetingCalleeInfo.h"
#import "NTESTeamMeetingViewController.h"
#import "NTESAVNotifier.h"
#import "NTESRedPacketTipAttachment.h"

NSString *NTESCustomNotificationCountChanged = @"NTESCustomNotificationCountChanged";

@interface NTESNotificationCenter () <NIMSystemNotificationManagerDelegate,NIMNetCallManagerDelegate,NIMRTSManagerDelegate,NIMChatManagerDelegate>

@property (nonatomic,strong) AVAudioPlayer *player; //播放提示音
@property (nonatomic,strong) NTESAVNotifier *notifier;

@end

@implementation NTESNotificationCenter

+ (instancetype)sharedCenter
{
    static NTESNotificationCenter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NTESNotificationCenter alloc] init];
    });
    return instance;
}

- (void)start
{
    DDLogInfo(@"Notification Center Setup");
}

- (instancetype)init {
    self = [super init];
    if(self) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"message" withExtension:@"wav"];
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        _notifier = [[NTESAVNotifier alloc] init];
        
        [[NIMSDK sharedSDK].systemNotificationManager addDelegate:self];
        [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
        [[NIMAVChatSDK sharedSDK].rtsManager addDelegate:self];
        [[NIMSDK sharedSDK].chatManager addDelegate:self];
        
    }
    return self;
}


- (void)dealloc{
    [[NIMSDK sharedSDK].systemNotificationManager removeDelegate:self];
    [[NIMAVChatSDK sharedSDK].netCallManager removeDelegate:self];
    [[NIMAVChatSDK sharedSDK].rtsManager removeDelegate:self];
    [[NIMSDK sharedSDK].chatManager removeDelegate:self];
}

#pragma mark - NIMChatManagerDelegate
- (void)onRecvMessages:(NSArray *)recvMessages
{
    NSArray *messages = [self filterMessages:recvMessages];
    if (messages.count)
    {
        static BOOL isPlaying = NO;
        if (isPlaying) {
            return;
        }
        isPlaying = YES;
        [self playMessageAudioTip];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isPlaying = NO;
        });
        [self checkMessageAt:messages];
    }
}

- (void)playMessageAudioTip
{
    UINavigationController *nav = [NTESMainTabController instance].selectedViewController;
    BOOL needPlay = YES;
    for (UIViewController *vc in nav.viewControllers) {
        if ([vc isKindOfClass:[NIMSessionViewController class]] ||  [vc isKindOfClass:[NTESLiveViewController class]] || [vc isKindOfClass:[NTESNetChatViewController class]])
        {
            needPlay = NO;
            break;
        }
    }
    if (needPlay) {
        [self.player stop];
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error:nil];
        [self.player play];
    }
}

- (void)checkMessageAt:(NSArray<NIMMessage *> *)messages
{
    //一定是同个 session 的消息
    NIMSession *session = [messages.firstObject session];
    if ([self.currentSessionViewController.session isEqual:session])
    {
        //只有在@所属会话页外面才需要标记有人@你
        return;
    }

    NSString *me = [[NIMSDK sharedSDK].loginManager currentAccount];
    
    for (NIMMessage *message in messages) {
        if ([message.apnsMemberOption.userIds containsObject:me]) {
            [NTESSessionUtil addRecentSessionAtMark:session];
            return;
        }
    }
}


- (NSArray *)filterMessages:(NSArray *)messages
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NIMMessage *message in messages)
    {
        if ([self checkRedPacketTip:message] && ![self canSaveMessageRedPacketTip:message])
        {
            [[NIMSDK  sharedSDK].conversationManager deleteMessage:message];
            [self.currentSessionViewController uiDeleteMessage:message];
            continue;
        }
        [array addObject:message];
    }
    return [NSArray arrayWithArray:array];
}


- (BOOL)checkRedPacketTip:(NIMMessage *)message
{
    NIMCustomObject *object = message.messageObject;
    if ([object isKindOfClass:[NIMCustomObject class]] && [object.attachment isKindOfClass:[NTESRedPacketTipAttachment class]])
    {
        return YES;
    }
    return NO;
}

- (BOOL)canSaveMessageRedPacketTip:(NIMMessage *)message
{
    NIMCustomObject *object = message.messageObject;
    NTESRedPacketTipAttachment *attach = (NTESRedPacketTipAttachment *)object.attachment;
    NSString *me = [NIMSDK sharedSDK].loginManager.currentAccount;
    return [attach.sendPacketId isEqualToString:me] || [attach.openPacketId isEqualToString:me];
}

- (void)onRecvRevokeMessageNotification:(NIMRevokeMessageNotification *)notification
{
    NIMMessage *tipMessage = [NTESSessionMsgConverter msgWithTip:[NTESSessionUtil tipOnMessageRevoked:notification]];
    NIMMessageSetting *setting = [[NIMMessageSetting alloc] init];
    setting.shouldBeCounted = NO;
    tipMessage.setting = setting;
    tipMessage.timestamp = notification.timestamp;
    
    NTESMainTabController *tabVC = [NTESMainTabController instance];
    UINavigationController *nav = tabVC.selectedViewController;

    for (NTESSessionViewController *vc in nav.viewControllers) {
        if ([vc isKindOfClass:[NTESSessionViewController class]]
            && [vc.session.sessionId isEqualToString:notification.session.sessionId]) {
            NIMMessageModel *model = [vc uiDeleteMessage:notification.message];
            if (model) {
                [vc uiInsertMessages:@[tipMessage]];
            }
            break;
        }
    }
    
    // saveMessage 方法执行成功后会触发 onRecvMessages: 回调，但是这个回调上来的 NIMMessage 时间为服务器时间，和界面上的时间有一定出入，所以要提前先在界面上插入一个和被删消息的界面时间相符的 Tip, 当触发 onRecvMessages: 回调时，组件判断这条消息已经被插入过了，就会忽略掉。
    [[NIMSDK sharedSDK].conversationManager saveMessage:tipMessage
                                             forSession:notification.session
                                             completion:nil];
}


#pragma mark - NIMSystemNotificationManagerDelegate
- (void)onReceiveCustomSystemNotification:(NIMCustomSystemNotification *)notification{
    
    NSString *content = notification.content;
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    if (data)
    {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:nil];
        if ([dict isKindOfClass:[NSDictionary class]])
        {
            switch ([dict jsonInteger:NTESNotifyID]) {
                case NTESCustom:{
                    //SDK并不会存储自定义的系统通知，需要上层结合业务逻辑考虑是否做存储。这里给出一个存储的例子。
                    NTESCustomNotificationObject *object = [[NTESCustomNotificationObject alloc] initWithNotification:notification];
                    //这里只负责存储可离线的自定义通知，推荐上层应用也这么处理，需要持久化的通知都走可离线通知
                    if (!notification.sendToOnlineUsersOnly) {
                        [[NTESCustomNotificationDB sharedInstance] saveNotification:object];
                    }
                    if (notification.setting.shouldBeCounted) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:NTESCustomNotificationCountChanged object:nil];
                    }
                    NSString *content  = [dict jsonString:NTESCustomContent];
                    [[NTESMainTabController instance].selectedViewController.view makeToast:content duration:2.0 position:CSToastPositionCenter];
                }
                    break;
                case NTESTeamMeetingCall:{
                    if (![self shouldResponseBusy]) {
                        //繁忙的话，不回复任何信息，直接丢掉，让呼叫方直接走超时
                        NSTimeInterval sendTime = notification.timestamp;
                        NSTimeInterval nowTime  = [[NSDate date] timeIntervalSince1970];
                        if (nowTime - sendTime < 45)
                        {
                            //60 秒内，认为有效，否则丢弃
                            NTESTeamMeetingCalleeInfo *info = [[NTESTeamMeetingCalleeInfo alloc] init];
                            info.teamId  = [dict jsonString:NTESTeamMeetingTeamId];
                            info.members = [dict jsonArray:NTESTeamMeetingMembers];
                            info.meetingName = [dict jsonString:NTESTeamMeetingName];
                            info.teamName = [dict jsonString:NTESTeamMeetingTeamName];
                            
                            NTESTeamMeetingCallingViewController *vc = [[NTESTeamMeetingCallingViewController alloc] initWithCalleeInfo:info];
                            [self presentModelViewController:vc];
                        }                        
                    }                    
                }
                    break;
                default:
                    break;
            }
        }
    }
}

#pragma mark - NIMNetCallManagerDelegate
- (void)onReceive:(UInt64)callID from:(NSString *)caller type:(NIMNetCallMediaType)type message:(NSString *)extendMessage{
    
    NTESMainTabController *tabVC = [NTESMainTabController instance];
    [tabVC.view endEditing:YES];
    UINavigationController *nav = tabVC.selectedViewController;

    if ([self shouldResponseBusy]){
        [[NIMAVChatSDK sharedSDK].netCallManager control:callID type:NIMNetCallControlTypeBusyLine];
    }
    else {
        
        if ([self shouldFireNotification:caller]) {
            NSString *text = [self textByCaller:caller
                                           type:type];
            [_notifier start:text];
        }
        

        
        UIViewController *vc;
        switch (type) {
            case NIMNetCallTypeVideo:{
                vc = [[NTESVideoChatViewController alloc] initWithCaller:caller callId:callID];
            }
                break;
            case NIMNetCallTypeAudio:{
                vc = [[NTESAudioChatViewController alloc] initWithCaller:caller callId:callID];
            }
                break;
            default:
                break;
        }
        if (!vc) {
            return;
        }
        
        // 由于音视频聊天里头有音频和视频聊天界面的切换，直接用present的话页面过渡会不太自然，这里还是用push，然后做出present的效果
        CATransition *transition = [CATransition animation];
        transition.duration = 0.25;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromTop;
        [nav.view.layer addAnimation:transition forKey:nil];
        nav.navigationBarHidden = YES;
        if (nav.presentedViewController) {
            // fix bug MMC-1431
            [nav.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        }
        [nav pushViewController:vc animated:NO];
    }
}

- (void)onHangup:(UInt64)callID
              by:(NSString *)user
{
    [_notifier stop];
}

- (void)onRTSRequest:(NSString *)sessionID
                from:(NSString *)caller
            services:(NSUInteger)types
             message:(NSString *)info
{
    if ([self shouldResponseBusy]) {
        [[NIMAVChatSDK sharedSDK].rtsManager responseRTS:sessionID accept:NO option:nil completion:nil];
    }
    else {
        
        if ([self shouldFireNotification:caller]) {
            NSString *text = [self textByCaller:caller];
            [_notifier start:text];
        }
        NTESWhiteboardViewController *vc = [[NTESWhiteboardViewController alloc] initWithSessionID:sessionID
                                                                                            peerID:caller
                                                                                             types:types
                                                                                              info:info];
        [self presentModelViewController:vc];
    }
}


- (void)presentModelViewController:(UIViewController *)vc
{
    NTESMainTabController *tab = [NTESMainTabController instance];
    [tab.view endEditing:YES];
    if (tab.presentedViewController) {
        __weak NTESMainTabController *wtabVC = tab;
        [tab.presentedViewController dismissViewControllerAnimated:NO completion:^{
            [wtabVC presentViewController:vc animated:NO completion:nil];
        }];
    }else{
        [tab presentViewController:vc animated:NO completion:nil];
    }
}

- (void)onRTSTerminate:(NSString *)sessionID
                    by:(NSString *)user
{
    [_notifier stop];
}

- (BOOL)shouldResponseBusy
{
    NTESMainTabController *tabVC = [NTESMainTabController instance];
    UINavigationController *nav = tabVC.selectedViewController;
    return [nav.topViewController isKindOfClass:[NTESNetChatViewController class]] ||
    [tabVC.presentedViewController isKindOfClass:[NTESWhiteboardViewController class]] ||
    [tabVC.presentedViewController isKindOfClass:[NTESTeamMeetingCallingViewController class]] ||
    [tabVC.presentedViewController isKindOfClass:[NTESTeamMeetingViewController class]];
}

#pragma mark - format
- (NSString *)textByCaller:(NSString *)caller type:(NIMNetCallMediaType)type
{
    NSString *action = type == NIMNetCallMediaTypeAudio ? @"音频":@"视频";
    NSString *text = [NSString stringWithFormat:@"你收到了一个%@聊天请求",action];
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:caller option:nil];
    if ([info.showName length])
    {
        text = [NSString stringWithFormat:@"%@向你发起了一个%@聊天请求",info.showName,action];
    }
    return text;
}


- (NSString *)textByCaller:(NSString *)caller
{
    NSString *text = @"你收到了一个白板请求";
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:caller option:nil];
    if ([info.showName length])
    {
        text = [NSString stringWithFormat:@"%@向你发起了一个白板请求",info.showName];
    }
    return text;
}

- (BOOL)shouldFireNotification:(NSString *)callerId
{
    //退后台后 APP 存活，然后收到通知
    BOOL should = YES;
 
    //消息不提醒
    id<NIMUserManager> userManager = [[NIMSDK sharedSDK] userManager];
    if (![userManager notifyForNewMsg:callerId])
    {
        should = NO;
    }
    
    //当前在正处于免打扰
    id<NIMApnsManager> apnsManager = [[NIMSDK sharedSDK] apnsManager];
    NIMPushNotificationSetting *setting = [apnsManager currentSetting];
    if (setting.noDisturbing)
    {
        NSDate *date = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
        NSInteger now = components.hour * 60 + components.minute;
        NSInteger start = setting.noDisturbingStartH * 60 + setting.noDisturbingStartM;
        NSInteger end = setting.noDisturbingEndH * 60 + setting.noDisturbingEndM;

        //当天区间
        if (end > start && end >= now && now >= start)
        {
            should = NO;
        }
        //隔天区间
        else if(end < start && (now <= end || now >= start))
        {
            should = NO;
        }
    }

    return should;
}


#pragma mark - Misc
- (NIMSessionViewController *)currentSessionViewController
{
    UINavigationController *nav = [NTESMainTabController instance].selectedViewController;
    for (UIViewController *vc in nav.viewControllers)
    {
        if ([vc isKindOfClass:[NIMSessionViewController class]])
        {
            return (NIMSessionViewController *)vc;
        }
    }
    return nil;
}

@end
