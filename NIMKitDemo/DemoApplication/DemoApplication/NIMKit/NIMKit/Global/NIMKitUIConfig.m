//
//  NIMKitCustomConfigReader.m
//  NIMKit
//
//  Created by chris on 2016/11/1.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMKitUIConfig.h"
#import "NIMKit.h"
#import "NSString+NIM.h"
#import "UIImage+NIM.h"

@interface NIMKitConfigHelper : NSObject

+ (id)configHelper:(NSDictionary *)configs isRight:(BOOL)isRight;

+ (NIMKitBubbleStyle *)bubbleConfigHelper:(NSDictionary *)configs isRight:(BOOL)isRight;

@end

@interface NIMKitBubbleStyle : NSObject 

@property (nonatomic,copy) NSString *bubbleImageNormal;

@property (nonatomic,copy) NSString *bubbleImageHightlighted;

@property (nonatomic,assign) UIEdgeInsets bubbleImageInsertsNormal;

@property (nonatomic,assign) UIEdgeInsets bubbleImageInsertsHighlighted;

- (NSString *)bubbleImage:(UIControlState)state;

- (UIEdgeInsets)bubbleInsets:(UIControlState)state;

@end

@interface NIMKitBubbleConfig()

@property (nonatomic,strong) NIMMessage *message;

@property (nonatomic,strong)  NIMKitBubbleStyle *bubbleConfig;

@end

@interface NIMKitGlobalConfig()

@property (nonatomic,strong) NIMKitBubbleStyle *leftBubbleConfig;

@property (nonatomic,strong) NIMKitBubbleStyle *rightBubbleConfig;

@end

@interface NIMKitUIConfig(){
    NSMutableDictionary<NSString *, NIMKitBubbleConfig *> *_cachedBubbleSettings;
    NIMKitGlobalConfig *_cachedGlobalSettings;
}

@property(nonatomic,strong) NSDictionary *bubbleSetting;

@end

@implementation NIMKitUIConfig

+ (instancetype)sharedConfig
{
    static NIMKitUIConfig *config;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[NIMKitUIConfig alloc] init];
    });
    return config;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cachedBubbleSettings = [[NSMutableDictionary alloc] init];
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


- (NIMKitGlobalConfig *)globalConfig
{
    if (!_cachedGlobalSettings) {
        _cachedGlobalSettings = [[NIMKitGlobalConfig alloc] init];
    }
    return _cachedGlobalSettings;
}

- (NIMKitBubbleConfig *)bubbleConfig:(NIMMessage *)message
{
    NSString *key = [self key:message];
    NIMKitBubbleConfig *config = [self configForKey:key isRight:message.isOutgoingMsg];
    config = config? : [self unsupportConfig:message];
    config.message = message;
    return config;
}

- (NIMKitBubbleConfig *)unsupportConfig:(NIMMessage *)message
{
    return [self configForKey:@"Unsupport" isRight:message.isOutgoingMsg];
}


- (NSString *)key:(NIMMessage *)message{
    NSDictionary *messageDict = @{
                                  @(NIMMessageTypeText) : @"Text",
                                  @(NIMMessageTypeImage): @"Image",
                                  @(NIMMessageTypeVideo): @"Video",
                                  @(NIMMessageTypeAudio): @"Audio",
                                  @(NIMMessageTypeFile) : @"File",
                                  @(NIMMessageTypeLocation) : @"Location",
                                  @(NIMMessageTypeTip)  : @"Tip",
                                  };
    
    NSDictionary *notificationDict = @{
                                       @(NIMNotificationTypeTeam)     : @"Team_Notification",
                                       @(NIMNotificationTypeChatroom) : @"Chatroom_Notification",
                                       @(NIMNotificationTypeNetCall)  : @"Netcall_Notification",
                                       };
    
    
    if (message.messageType == NIMMessageTypeNotification) {
        NIMNotificationObject *object = (NIMNotificationObject *)message.messageObject;
        return notificationDict[@(object.notificationType)];
    }else{
        return messageDict[@(message.messageType)];
    }
}


- (NIMKitBubbleConfig *)configForKey:(NSString *)key isRight:(BOOL)isRight
{
    NSString *configKey = [self cachedCustomBubbleSettingKey:key isRight:isRight];
    NIMKitBubbleConfig *config = _cachedBubbleSettings[configKey];
    if (config) {
        return config;
    }else{
        NSString *name = [[[NIMKit sharedKit] settingBundleName] stringByAppendingPathComponent:@"NIMKitBubbleSetting.plist"];
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];
        NSDictionary *bubbleSetting = [NSDictionary dictionaryWithContentsOfFile:path];

        NSDictionary *info = [bubbleSetting objectForKey:key];
        if (info) {

            NIMKitBubbleConfig *config = [[NIMKitBubbleConfig alloc] init];
            
            NSString *insetsString = [NIMKitConfigHelper configHelper:[info objectForKey:@"Content_Insets"] isRight:isRight];
            config.contentInset  = UIEdgeInsetsFromString(insetsString);
                        
            config.textColor     = [NIMKitConfigHelper configHelper:[info objectForKey:@"Content_Color"] isRight:isRight];
            
            config.textFontSize  = [[info objectForKey:@"Content_Font_Size"] floatValue];
            
            config.bubbleConfig = [NIMKitConfigHelper bubbleConfigHelper:info isRight:isRight];
            
            config.showAvatar   = [[info objectForKey:@"Show_Avatar"] boolValue];
            
            _cachedBubbleSettings[configKey] = config;
            
            return config;
        }
    }
    return nil;
}


- (NSString *)cachedCustomBubbleSettingKey:(NSString *)key isRight:(BOOL)isRight
{
    return [key stringByAppendingFormat:@"-%zd",isRight];
}

@end


@implementation NIMKitGlobalConfig

- (instancetype)init{
    self = [super init];
    if (self) {
        NSString *name = [[[NIMKit sharedKit] settingBundleName] stringByAppendingPathComponent:@"NIMKitGlobalSetting.plist"];
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];
        NSDictionary *globalSetting = [NSDictionary dictionaryWithContentsOfFile:path];
        
        _leftBubbleConfig  = [NIMKitConfigHelper bubbleConfigHelper:globalSetting isRight:NO];
        _rightBubbleConfig = [NIMKitConfigHelper bubbleConfigHelper:globalSetting isRight:YES];

        _messageInterval   = [globalSetting[@"Message_Interval"] doubleValue];
        _messageLimit      = [globalSetting[@"Message_Limit"] integerValue];
        _recordMaxDuration = [globalSetting[@"Record_Max_Duration"] integerValue];
        
        _placeholder     = globalSetting[@"Placeholder"];
        _maxLength       = [globalSetting[@"Max_Length"] integerValue];
        
        _topInputViewHeight = [globalSetting[@"Top_Input_Height"] doubleValue];
        _bottomInputViewHeight = [globalSetting[@"Bottom_Input_Height"] doubleValue];

    }
    return self;
}

- (NIMKitBubbleStyle *)bubbleStyle:(BOOL)isRight
{
    return isRight? self.rightBubbleConfig : self.leftBubbleConfig;
}

@end


@implementation NIMKitBubbleConfig

- (UIColor *)contentTextColor
{
    return [self.textColor nim_hexToColor];
}

- (UIFont *)contentTextFont
{
    CGFloat fontSize = self.textFontSize;
    return [UIFont systemFontOfSize:fontSize];
}

- (UIImage *)bubbleImage:(UIControlState)state;
{
    NIMKitBubbleStyle *bubbleConfig = [self customBubbleConfig];
    NSString *name = [bubbleConfig bubbleImage:state];
    UIEdgeInsets insets = [self bubbleInsets:state];
    return [[UIImage nim_imageInKit:name] resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
}

- (UIEdgeInsets)bubbleInsets:(UIControlState)state
{
    NIMKitBubbleStyle *bubbleConfig = [self customBubbleConfig];
    return [bubbleConfig bubbleInsets:state];
}


- (NIMKitBubbleStyle *)customBubbleConfig
{
    NIMKitBubbleStyle *bubbleConfig = self.bubbleConfig;
    if(!bubbleConfig)
    {
        //如果没有特殊定义，则取全局的设置
        NIMKitGlobalConfig *global = [[NIMKitUIConfig sharedConfig] globalConfig];
        bubbleConfig = [global bubbleStyle:self.message.isOutgoingMsg];
    }
    return bubbleConfig;
}


@end

@implementation NIMKitBubbleStyle

- (NSString *)bubbleImage:(UIControlState)state
{
    switch (state) {
        case UIControlStateHighlighted:
            return self.bubbleImageHightlighted;
        default:
            return self.bubbleImageNormal;
    }
}

- (UIEdgeInsets )bubbleInsets:(UIControlState)state
{
    switch (state) {
        case UIControlStateHighlighted:
            return self.bubbleImageInsertsHighlighted;
        default:
            return self.bubbleImageInsertsNormal;
    }
}


@end



@implementation NIMKitConfigHelper : NSObject

+ (id)configHelper:(NSDictionary *)configs isRight:(BOOL)isRight
{
    return isRight? configs[@"Right"] : configs[@"Left"];
}

+ (NIMKitBubbleStyle *)bubbleConfigHelper:(NSDictionary *)configs isRight:(BOOL)isRight
{
    NSDictionary *bubbleConfig = [self configHelper:[configs objectForKey:@"Bubble"] isRight:isRight];
    if (bubbleConfig) {
        NIMKitBubbleStyle *bubble = [[NIMKitBubbleStyle alloc] init];
        NSDictionary *normal = bubbleConfig[@"Normal"];
        NSDictionary *highlighted = bubbleConfig[@"Highlighted"];
        
        NSString *name   = @"Name";
        NSString *insets = @"Insets";
        
        bubble.bubbleImageNormal = normal[name];
        bubble.bubbleImageInsertsNormal = UIEdgeInsetsFromString(normal[insets]);
        
        bubble.bubbleImageHightlighted = highlighted[name];
        bubble.bubbleImageInsertsHighlighted = UIEdgeInsetsFromString(highlighted[insets]);
        
        return bubble;
    }
    return nil;
}

@end
