//
//  NIMInputEmoticonButton.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputEmoticonButton.h"
#import "UIImage+NIMKit.h"
#import "NIMInputEmoticonManager.h"

@implementation NIMInputEmoticonButton

+ (NIMInputEmoticonButton*)iconButtonWithData:(NIMInputEmoticon*)data catalogID:(NSString*)catalogID delegate:( id<NIMEmoticonButtonTouchDelegate>)delegate{
    NIMInputEmoticonButton* icon = [[NIMInputEmoticonButton alloc] init];
    [icon addTarget:icon action:@selector(onIconSelected:) forControlEvents:UIControlEventTouchUpInside];
    
    
    icon.emoticonData    = data;
    icon.catalogID              = catalogID;
    icon.userInteractionEnabled = YES;
    icon.exclusiveTouch         = YES;
    icon.contentMode            = UIViewContentModeScaleToFill;
    icon.delegate               = delegate;
    
    switch (data.type) {
        case NIMEmoticonTypeUnicode:
        {
            [icon setTitle:data.unicode forState:UIControlStateNormal];
            [icon setTitle:data.unicode forState:UIControlStateHighlighted];
            icon.titleLabel.font = [UIFont systemFontOfSize:32];
            break;
        }
        case NIMEmoticonTypeFile:
        default:
        {
            UIImage *image = [UIImage nim_emoticonInKit:data.filename];
            [icon setImage:image forState:UIControlStateNormal];
            [icon setImage:image forState:UIControlStateHighlighted];
            break;
        }
    }
    return icon;
}



- (void)onIconSelected:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(selectedEmoticon:catalogID:)])
    {
        [self.delegate selectedEmoticon:self.emoticonData catalogID:self.catalogID];
    }
}

@end
