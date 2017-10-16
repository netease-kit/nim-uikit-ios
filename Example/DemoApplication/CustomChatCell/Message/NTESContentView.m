//
//  NTESContentView.m
//  DemoApplication
//
//  Created by chris on 15/11/1.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "NTESContentView.h"
#import "NTESAttachment.h"

@implementation NTESContentView

- (instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:13.f];
        _subTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subTitleLabel.font = [UIFont systemFontOfSize:12.f];
        [self addSubview:_titleLabel];
        [self addSubview:_subTitleLabel];
    }
    return self;
}

- (void)refresh:(NIMMessageModel*)data{
    //务必调用super方法
    [super refresh:data];
    NIMCustomObject *object = data.message.messageObject;
    NTESAttachment *attachment = object.attachment;
    
    self.titleLabel.text = attachment.title;
    self.subTitleLabel.text = attachment.subTitle;
    
    if (!self.model.message.isOutgoingMsg) {
        self.titleLabel.textColor = [UIColor blackColor];
        self.subTitleLabel.textColor = [UIColor blackColor];
    }else{
        self.titleLabel.textColor = [UIColor whiteColor];
        self.subTitleLabel.textColor = [UIColor whiteColor];
    }
    
    [_titleLabel sizeToFit];
    [_subTitleLabel sizeToFit];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat titleOriginX = 10.f;
    CGFloat titleOriginY = 10.f;
    CGFloat subTitleOriginX = (self.frame.size.width  - self.subTitleLabel.frame.size.width) / 2;
    CGFloat subTitleOriginY = self.frame.size.height  - self.subTitleLabel.frame.size.height - 10.f;
    
    CGRect frame = self.titleLabel.frame;
    frame.origin = CGPointMake(titleOriginX, titleOriginY);
    self.titleLabel.frame = frame;
    
    frame = self.subTitleLabel.frame;
    frame.origin = CGPointMake(subTitleOriginX, subTitleOriginY);
    self.subTitleLabel.frame = frame;
}

@end
