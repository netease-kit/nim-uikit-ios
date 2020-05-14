//
//  NIMListCollectionCell.m
//  NIMKit
//
//  Created by He on 2020/4/13.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMQuickCommentCell.h"
#import "NIMKitQuickCommentUtil.h"
#import "M80AttributedLabel+NIMKit.h"
#import "UIView+NIM.h"
#import "NIMKit.h"
#import "UIColor+NIMKit.h"

@interface NIMQuickCommentCell ()

@property (nonatomic, strong) M80AttributedLabel *textLabel;
@property (nonatomic, strong) UIView *divider;

@end

@implementation NIMQuickCommentCell


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _textLabel = [NIMKitQuickCommentUtil newCommentLabel];
        [self.contentView addSubview:_textLabel];
        self.layer.cornerRadius = 12.0;
        self.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.3];
        
        _divider = [[UIView alloc] initWithFrame:CGRectZero];
        _divider.backgroundColor = UIColor.lightGrayColor;
        [self.contentView addSubview:_divider];
        
    }
    return self;
}

- (void)refreshWithData:(NSArray *)comments model:(NIMMessageModel *)data
{
    self.textLabel.textColor = data.shouldShowLeft ? [UIColor colorWithHex:0x000000 alpha:1] : [UIColor colorWithHex:0xFFFFFF alpha:1];
    [self.textLabel nim_setText:[NIMKitQuickCommentUtil commentsContent:comments]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.nim_width = self.nim_width - NIMKitCommentUtilCellContentPadding * 2;
    self.textLabel.nim_height = self.textLabel.intrinsicContentSize.height;
    self.textLabel.nim_centerY = self.nim_height * .5f;
    self.textLabel.nim_left = NIMKitCommentUtilCellPadding;
    
    self.divider.nim_width = 0.5;
    self.divider.nim_height = self.contentView.nim_height - 8;
    self.divider.nim_centerY = self.contentView.nim_height * 0.5;
    self.divider.nim_left = 22;
}

@end
