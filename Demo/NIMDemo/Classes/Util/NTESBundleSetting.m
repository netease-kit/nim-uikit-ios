//
//  NTESBundleSetting.m
//  NIM
//
//  Created by chris on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESBundleSetting.h"

@implementation NTESBundleSetting

+ (instancetype)sharedConfig
{
    static NTESBundleSetting *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NTESBundleSetting alloc] init];
    });
    return instance;
}


- (BOOL)removeSessionWheDeleteMessages{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled_remove_recent_session"] boolValue];
}

- (BOOL)localSearchOrderByTimeDesc{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"local_search_time_order_desc"] boolValue];
}


- (BOOL)autoRemoveRemoteSession{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"auto_remove_remote_session"] boolValue];
}

- (BOOL)autoRemoveSnapMessage{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"auto_remove_snap_message"] boolValue];
}

- (BOOL)needVerifyForFriend
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"add_friend_need_verify"] boolValue];
}

- (BOOL)showFps{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"show_fps_for_app"] boolValue];
}

- (BOOL)disableProximityMonitor
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"disable_proxmity_monitor"] boolValue];
}


- (BOOL)enableRotate
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"enable_rotate"] boolValue];
}

- (BOOL)usingAmr
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"using_amr"] boolValue];
}

- (NSArray *)ignoreTeamNotificationTypes
{
    static NSArray *types = nil;
    if (types == nil)
    {
        NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:@"ignore_team_types"];
        if ([value isKindOfClass:[NSString class]])
        {
            NSString *typeDescription = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([typeDescription length])
            {
                types = [typeDescription componentsSeparatedByString:@","];
            }
        }
    }
    if (types == nil)
    {
        types = [NSArray array];
    }
    return types;
}


- (BOOL)serverRecordAudio
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"server_record_audio"] boolValue];
}

- (BOOL)serverRecordVideo
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"server_record_video"] boolValue];
}

- (BOOL)serverRecordWhiteboardData
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"server_record_whiteboard_data"] boolValue];
}


- (BOOL)videochatDisableAutoCropping
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_disable_auto_cropping"] boolValue];
}

- (BOOL)videochatAutoRotateRemoteVideo
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_auto_rotate_remote_video"] boolValue];
}

- (NIMNetCallVideoQuality)preferredVideoQuality
{
    NSInteger videoQualitySetting = [[[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_preferred_video_quality"] integerValue];
    if ((videoQualitySetting >= NIMNetCallVideoQualityDefault) &&
        (videoQualitySetting <= NIMNetCallVideoQuality720pLevel)) {
        return (NIMNetCallVideoQuality)videoQualitySetting;
    }
    return NIMNetCallVideoQualityDefault;
}


- (BOOL)startWithBackCamera
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_start_with_back_camera"] boolValue];
}

- (NIMNetCallVideoCodec)perferredVideoEncoder
{
    NSInteger videoEncoderSetting = [[[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_preferred_video_encoder"] integerValue];

    if ((videoEncoderSetting >= NIMNetCallVideoCodecDefault) &&
        (videoEncoderSetting <= NIMNetCallVideoCodecHardware)) {
        return (NIMNetCallVideoCodec)videoEncoderSetting;
    }
    return NIMNetCallVideoCodecDefault;
}

- (NIMNetCallVideoCodec)perferredVideoDecoder
{
    NSInteger videoDecoderSetting = [[[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_preferred_video_decoder"] integerValue];
    
    if ((videoDecoderSetting >= NIMNetCallVideoCodecDefault) &&
        (videoDecoderSetting <= NIMNetCallVideoCodecHardware)) {
        return (NIMNetCallVideoCodec)videoDecoderSetting;
    }
    return NIMNetCallVideoCodecDefault;

}
- (NSUInteger)videoMaxEncodeKbps
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_video_encode_max_kbps"] integerValue];
}

- (NSUInteger)localRecordVideoKbps
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_local_record_video_kbps"] integerValue];
}

- (BOOL)autoDeactivateAudioSession
{
    id setting = [[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_auto_disable_audiosession"];
    
    if (setting) {
        return [setting boolValue];
    }
    else {
        return YES;
    }
}

- (BOOL)audioDenoise
{
    id setting = [[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_audio_denoise"];
    
    if (setting) {
        return [setting boolValue];
    }
    else {
        return YES;
    }
    
}

- (BOOL)voiceDetect
{
    id setting = [[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_voice_detect"];
    
    if (setting) {
        return [setting boolValue];
    }
    else {
        return YES;
    }
    
}

- (BOOL)preferHDAudio
{
    id setting = [[NSUserDefaults standardUserDefaults] objectForKey:@"videochat_prefer_hd_audio"];
    
    if (setting) {
        return [setting boolValue];
    }
    else {
        return NO;
    }
}


- (NSString *)description
{
    return [NSString stringWithFormat:
                @"\n\n\n" \
                "enabled_remove_recent_session %d\n" \
                "local_search_time_order_desc %d\n" \
                "auto_remove_remote_session %d\n" \
                "auto_remove_snap_message %d\n" \
                "add_friend_need_verify %d\n" \
                "show app %d\n" \
                "using amr %d\n" \
                "ignore_team_types %@ \n" \
                "server_record_audio %d\n" \
                "server_record_video %d\n" \
                "server_record_whiteboard_data %d\n" \
                "videochat_disable_auto_cropping %d\n" \
                "videochat_auto_rotate_remote_video %d \n" \
                "videochat_preferred_video_quality %zd\n" \
                "videochat_start_with_back_camera %zd\n" \
                "videochat_preferred_video_encoder %zd\n" \
                "videochat_preferred_video_decoder %zd\n" \
                "videochat_video_encode_max_kbps %zd\n" \
                "videochat_local_record_video_kbps %zd\n" \
                "videochat_auto_disable_audiosession %zd\n" \
                "videochat_audio_denoise %zd\n" \
                "videochat_voice_detect %zd\n" \
                "videochat_prefer_hd_audio %zd\n" \
                "\n\n\n",
                [self removeSessionWheDeleteMessages],
                [self localSearchOrderByTimeDesc],
                [self autoRemoveRemoteSession],
                [self autoRemoveSnapMessage],
                [self needVerifyForFriend],
                [self showFps],
                [self usingAmr],
                [self ignoreTeamNotificationTypes],
                [self serverRecordAudio],
                [self serverRecordVideo],
                [self serverRecordWhiteboardData],
                [self videochatDisableAutoCropping],
                [self videochatAutoRotateRemoteVideo],
                [self preferredVideoQuality],
                [self startWithBackCamera],
                [self perferredVideoEncoder],
                [self perferredVideoDecoder],
                [self videoMaxEncodeKbps],
                [self localRecordVideoKbps],
                [self autoDeactivateAudioSession],
                [self audioDenoise],
                [self voiceDetect],
                [self preferHDAudio]
            ];
}
@end
