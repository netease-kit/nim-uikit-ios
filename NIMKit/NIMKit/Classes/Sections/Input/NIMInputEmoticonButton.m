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
    if(data.unicode && data.unicode.length>0) {
        [icon setTitle:data.unicode forState:UIControlStateNormal];
        [icon setTitle:data.unicode forState:UIControlStateHighlighted];
        icon.titleLabel.font = [UIFont systemFontOfSize:32];
    }else if(data.filename && data.filename.length>0){
        UIImage *image = [UIImage nim_fetchEmoticon:data.filename];
        [icon setImage:image forState:UIControlStateNormal];
        [icon setImage:image forState:UIControlStateHighlighted];
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
