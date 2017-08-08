//
//  NTESSessionRedPacketContentView.m
//  NIM
//
//  Created by chris on 2017/7/17.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESSessionRedPacketContentView.h"
#import "NTESRedPacketAttachment.h"
#import "JRMFHeader.h"

NSString *const NIMDemoEventNameOpenRedPacket = @"NIMDemoEventNameOpenRedPacket";

@interface NTESSessionRedPacketContentView()

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UILabel *subTitleLabel;

@property (nonatomic, strong) UILabel *descLabel;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation NTESSessionRedPacketContentView

- (instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        // 内容布局
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:12.f];
        _subTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subTitleLabel.font = [UIFont systemFontOfSize:12.f];
        _descLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _descLabel.font = [UIFont systemFontOfSize:13.f];
        
        [self addSubview:_titleLabel];
        [self addSubview:_subTitleLabel];
        [self addSubview:_descLabel];
        
    }
    return self;
}


- (void)onTouchUpInside:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(onCatchEvent:)]) {
        NIMKitEvent *event = [[NIMKitEvent alloc] init];
        event.eventName = NIMDemoEventNameOpenRedPacket;
        event.messageModel = self.model;
        event.data = self;
        [self.delegate onCatchEvent:event];
    }
}

#pragma mark - 系统父类方法
- (void)refresh:(NIMMessageModel*)data{
    [super refresh:data];
    
    NIMCustomObject *object = data.message.messageObject;
    NTESRedPacketAttachment *attachment = (NTESRedPacketAttachment *)object.attachment;
    
    self.titleLabel.text = attachment.title;
    self.descLabel.text  = attachment.content;
    
    self.titleLabel.textColor    =  [UIColor lightGrayColor];
    self.subTitleLabel.textColor =  [UIColor whiteColor];
    self.descLabel.textColor     =  [UIColor whiteColor];
    
    [self.titleLabel sizeToFit];
    CGRect rect = self.titleLabel.frame;
    if (CGRectGetMaxX(rect) > self.bounds.size.width)
    {
        rect.size.width = self.bounds.size.width - rect.origin.x - 20;
        self.titleLabel.frame = rect;
    }
    self.subTitleLabel.text = self.model.message.isOutgoingMsg? @"查看红包" : @"领取红包";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    BOOL outgoing = self.model.message.isOutgoingMsg;
    if (outgoing)
    {
        self.descLabel.frame = CGRectMake(12.0f+31.f+12.f, 17.f, 160.f, 24.f);
        self.subTitleLabel.frame = CGRectMake(12.0f+31.f+12.f, 39.f, 150.f, 20.f);
        self.titleLabel.frame = CGRectMake(7.0f, 93.f-18.f, 180.f, 21.f);
    }
    else
    {
        self.descLabel.frame = CGRectMake(12.f+31.f+12.f, 17.f, 160.f, 24.f);
        self.subTitleLabel.frame = CGRectMake(12.f+31.f+12.f, 39.f, 150.f, 20.f);
        self.titleLabel.frame = CGRectMake(14.f, 93.f-18.f, 180.f, 21.f);
    }
}

- (UIImage *)chatBubbleImageForState:(UIControlState)state outgoing:(BOOL)outgoing
{
    NSString *stateString = state == UIControlStateNormal? @"normal" : @"pressed";
    NSString *imageName = @"icon_redpacket_";
    if (outgoing)
    {
        imageName = [imageName stringByAppendingString:@"from_"];
    }
    else
    {
        imageName = [imageName stringByAppendingString:@"to_"];
    }
    imageName = [imageName stringByAppendingString:stateString];
    return [UIImage imageNamed:imageName];
}

@end
