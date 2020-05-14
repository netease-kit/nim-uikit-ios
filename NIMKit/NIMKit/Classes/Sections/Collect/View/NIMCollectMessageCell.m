//
//  NIMCollectMessageCell.m
//  NIMKit
//
//  Created by 丁文超 on 2020/3/19.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMCollectMessageCell.h"
#import "UIView+NIM.h"
#import "NIMAvatarImageView.h"
#import "NIMKit.h"
#import "NIMKitUtil.h"

@implementation NIMCollectMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    return self;
}

@end
