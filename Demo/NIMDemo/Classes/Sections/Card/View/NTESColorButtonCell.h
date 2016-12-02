//
//  NTESColorButtonCell.h
//  NIM
//
//  Created by chris on 15/3/11.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMCommonTableViewCell.h"

typedef NS_ENUM(NSInteger, ColorButtonCellStyle){
    ColorButtonCellStyleRed,
    ColorButtonCellStyleBlue,
};

@class NTESColorButton;

@interface NTESColorButtonCell : UITableViewCell<NIMCommonTableViewCell>

@property (nonatomic,strong) NTESColorButton *button;

@end



@interface NTESColorButton : UIButton

@property (nonatomic,assign) ColorButtonCellStyle style;

@end