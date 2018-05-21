//
//  NIMKitConfig.m
//  NIMKit
//
//  Created by chris on 2017/10/25.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMKitConfig.h"
#import "NIMGlobalMacro.h"
#import "NIMMediaItem.h"
#import "UIImage+NIMKit.h"
#import <NIMSDK/NIMSDK.h>

@interface NIMKitSettings()
{
    BOOL _isRight;
}

- (instancetype)init:(BOOL)isRight;

@end


@implementation NIMKitConfig

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self applyDefaultSettings];
    }
    return self;
}


- (NSArray *)defaultMediaItems
{
    return @[[NIMMediaItem item:@"onTapMediaItemPicture:"
                    normalImage:[UIImage nim_imageInKit:@"bk_media_picture_normal"]
                  selectedImage:[UIImage nim_imageInKit:@"bk_media_picture_nomal_pressed"]
                          title:@"相册"],
             
             [NIMMediaItem item:@"onTapMediaItemShoot:"
                    normalImage:[UIImage nim_imageInKit:@"bk_media_shoot_normal"]
                  selectedImage:[UIImage nim_imageInKit:@"bk_media_shoot_pressed"]
                          title:@"拍摄"],
             
             [NIMMediaItem item:@"onTapMediaItemLocation:"
                    normalImage:[UIImage nim_imageInKit:@"bk_media_position_normal"]
                  selectedImage:[UIImage nim_imageInKit:@"bk_media_position_pressed"]
                          title:@"位置"],
             ];
}


- (CGFloat)maxNotificationTipPadding{
    return 20.f;
}


- (void)applyDefaultSettings
{
    _messageInterval = 300;
    _messageLimit    = 20;
    _recordMaxDuration = 60.f;
    _placeholder = @"请输入消息";
    _inputMaxLength = 1000;
    _nickFont  = [UIFont systemFontOfSize:13.0];
    _nickColor = [UIColor darkGrayColor];
    _receiptFont  = [UIFont systemFontOfSize:13.0]; 
    _receiptColor = [UIColor darkGrayColor];
    _avatarType = NIMKitAvatarTypeRounded;
    _cellBackgroundColor = NIMKit_UIColorFromRGB(0xE4E7EC);
    _leftBubbleSettings  = [[NIMKitSettings alloc] init:NO];
    _rightBubbleSettings = [[NIMKitSettings alloc] init:YES];
}

- (NIMKitSetting *)setting:(NIMMessage *)message
{
    NIMKitSettings *settings = message.isOutgoingMsg? self.rightBubbleSettings : self.leftBubbleSettings;
    switch (message.messageType) {
        case NIMMessageTypeText:
            return settings.textSetting;
        case NIMMessageTypeImage:
            return settings.imageSetting;
        case NIMMessageTypeLocation:
            return settings.locationSetting;
        case NIMMessageTypeAudio:
            return settings.audioSetting;
        case NIMMessageTypeVideo:
            return settings.videoSetting;
        case NIMMessageTypeFile:
            return settings.fileSetting;
        case NIMMessageTypeTip:
            return settings.tipSetting;
        case NIMMessageTypeRobot:
            return settings.robotSetting;
        case NIMMessageTypeNotification:
        {
            NIMNotificationObject *object = (NIMNotificationObject *)message.messageObject;
            switch (object.notificationType)
            {
                case NIMNotificationTypeTeam:
                    return settings.teamNotificationSetting;
                case NIMNotificationTypeChatroom:
                    return settings.chatroomNotificationSetting;
                case NIMNotificationTypeNetCall:
                    return settings.netcallNotificationSetting;
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
    return settings.unsupportSetting;
}

@end


@implementation NIMKitSettings

- (instancetype)init:(BOOL)isRight
{
    self = [super init];
    if (self)
    {
        _isRight = isRight;
        [self applyDefaultSettings];
    }
    return self;
}

- (void)applyDefaultSettings
{
    [self applyDefaultTextSettings];
    [self applyDefaultAudioSettings];
    [self applyDefaultVideoSettings];
    [self applyDefaultFileSettings];
    [self applyDefaultImageSettings];
    [self applyDefaultLocationSettings];
    [self applyDefaultTipSettings];
    [self applyDefaultRobotSettings];
    [self applyDefaultUnsupportSettings];
    [self applyDefaultTeamNotificationSettings];
    [self applyDefaultChatroomNotificationSettings];
    [self applyDefaultNetcallNotificationSettings];
}

- (void)applyDefaultTextSettings
{
    _textSetting = [[NIMKitSetting alloc] init:_isRight];
    _textSetting.contentInsets = _isRight? UIEdgeInsetsFromString(@"{11,11,9,15}") : UIEdgeInsetsFromString(@"{11,15,9,9}");
    _textSetting.textColor = _isRight? NIMKit_UIColorFromRGB(0xFFFFFF) : NIMKit_UIColorFromRGB(0x000000);
    _textSetting.font      = [UIFont systemFontOfSize:14];
    _textSetting.showAvatar = YES;
}

- (void)applyDefaultAudioSettings
{
    _audioSetting = [[NIMKitSetting alloc] init:_isRight];
    _audioSetting.contentInsets = _isRight? UIEdgeInsetsFromString(@"{8,12,9,14}") : UIEdgeInsetsFromString(@"{8,13,9,12}");
    _audioSetting.textColor = _isRight? NIMKit_UIColorFromRGB(0xFFFFFF) : NIMKit_UIColorFromRGB(0x000000);
    _audioSetting.font      = [UIFont systemFontOfSize:14];
    _audioSetting.showAvatar = YES;
}

- (void)applyDefaultVideoSettings
{
    _videoSetting = [[NIMKitSetting alloc] init:_isRight];
    _videoSetting.contentInsets = _isRight? UIEdgeInsetsFromString(@"{3,3,3,8}") : UIEdgeInsetsFromString(@"{3,8,3,3}");
    _videoSetting.font      = [UIFont systemFontOfSize:14];
    _videoSetting.showAvatar = YES;
}

- (void)applyDefaultFileSettings
{
    _fileSetting = [[NIMKitSetting alloc] init:_isRight];
    _fileSetting.contentInsets = _isRight? UIEdgeInsetsFromString(@"{3,3,3,8}") : UIEdgeInsetsFromString(@"{3,8,3,3}");
    _fileSetting.font      = [UIFont systemFontOfSize:14];
    _fileSetting.showAvatar = YES;
}

- (void)applyDefaultImageSettings
{
    _imageSetting = [[NIMKitSetting alloc] init:_isRight];
    _imageSetting.contentInsets = _isRight? UIEdgeInsetsFromString(@"{3,3,3,8}") : UIEdgeInsetsFromString(@"{3,8,3,3}");
    _imageSetting.showAvatar = YES;
}

- (void)applyDefaultLocationSettings
{
    _locationSetting = [[NIMKitSetting alloc] init:_isRight];
    _locationSetting.contentInsets = _isRight? UIEdgeInsetsFromString(@"{3,3,3,8}") : UIEdgeInsetsFromString(@"{3,8,3,3}");
    _locationSetting.textColor = NIMKit_UIColorFromRGB(0xFFFFFF);
    _locationSetting.font      = [UIFont systemFontOfSize:12];
    _locationSetting.showAvatar = YES;
}

- (void)applyDefaultTipSettings
{
    _tipSetting = [[NIMKitSetting alloc] init:_isRight];
    _tipSetting.contentInsets = UIEdgeInsetsZero;
    _tipSetting.textColor = NIMKit_UIColorFromRGB(0xFFFFFF);
    _tipSetting.font  = [UIFont systemFontOfSize:10.f];
    _tipSetting.showAvatar = NO;
    UIImage *backgroundImage = [[UIImage nim_imageInKit:@"icon_session_time_bg"] resizableImageWithCapInsets:UIEdgeInsetsFromString(@"{8,20,8,20}") resizingMode:UIImageResizingModeStretch];;
    _tipSetting.normalBackgroundImage    = backgroundImage;
    _tipSetting.highLightBackgroundImage = backgroundImage;
}


- (void)applyDefaultRobotSettings
{
    _robotSetting = [[NIMKitSetting alloc] init:_isRight];
    _robotSetting.contentInsets = _isRight? UIEdgeInsetsFromString(@"{11,11,9,15}") : UIEdgeInsetsFromString(@"{11,15,9,9}");
    _robotSetting.textColor = _isRight? NIMKit_UIColorFromRGB(0xFFFFFF) : NIMKit_UIColorFromRGB(0x000000);
    _robotSetting.font      = [UIFont systemFontOfSize:14];
    _robotSetting.showAvatar = YES;
}

- (void)applyDefaultUnsupportSettings
{
    _unsupportSetting = [[NIMKitSetting alloc] init:_isRight];
    _unsupportSetting.contentInsets = _isRight? UIEdgeInsetsFromString(@"{11,11,9,15}") : UIEdgeInsetsFromString(@"{11,15,9,9}");
    _unsupportSetting.textColor = _isRight? NIMKit_UIColorFromRGB(0xFFFFFF) : NIMKit_UIColorFromRGB(0x000000);
    _unsupportSetting.font      = [UIFont systemFontOfSize:14];
    _unsupportSetting.showAvatar = YES;
}


- (void)applyDefaultTeamNotificationSettings
{
    _teamNotificationSetting = [[NIMKitSetting alloc] init:_isRight];
    _teamNotificationSetting.contentInsets = UIEdgeInsetsZero;
    _teamNotificationSetting.textColor = NIMKit_UIColorFromRGB(0xFFFFFF);
    _teamNotificationSetting.font      = [UIFont systemFontOfSize:10];
    _teamNotificationSetting.showAvatar = NO;
    UIImage *backgroundImage = [[UIImage nim_imageInKit:@"icon_session_time_bg"] resizableImageWithCapInsets:UIEdgeInsetsFromString(@"{8,20,8,20}") resizingMode:UIImageResizingModeStretch];
    _teamNotificationSetting.normalBackgroundImage    = backgroundImage;
    _teamNotificationSetting.highLightBackgroundImage = backgroundImage;
}

- (void)applyDefaultChatroomNotificationSettings
{
    _chatroomNotificationSetting = [[NIMKitSetting alloc] init:_isRight];
    _chatroomNotificationSetting.contentInsets = UIEdgeInsetsZero;
    _chatroomNotificationSetting.textColor = NIMKit_UIColorFromRGB(0xFFFFFF);
    _chatroomNotificationSetting.font      = [UIFont systemFontOfSize:10];
    _chatroomNotificationSetting.showAvatar = NO;
    UIImage *backgroundImage = [[UIImage nim_imageInKit:@"icon_session_time_bg"] resizableImageWithCapInsets:UIEdgeInsetsFromString(@"{8,20,8,20}") resizingMode:UIImageResizingModeStretch];
    _chatroomNotificationSetting.normalBackgroundImage    = backgroundImage;
    _chatroomNotificationSetting.highLightBackgroundImage = backgroundImage;
}

- (void)applyDefaultNetcallNotificationSettings
{
    _netcallNotificationSetting = [[NIMKitSetting alloc] init:_isRight];
    _netcallNotificationSetting.contentInsets = _isRight? UIEdgeInsetsFromString(@"{11,11,9,15}") : UIEdgeInsetsFromString(@"{11,15,9,9}");
    _netcallNotificationSetting.textColor = _isRight? NIMKit_UIColorFromRGB(0xFFFFFF) : NIMKit_UIColorFromRGB(0x000000);
    _netcallNotificationSetting.font      = [UIFont systemFontOfSize:14];
    _netcallNotificationSetting.showAvatar = YES;
}


@end





