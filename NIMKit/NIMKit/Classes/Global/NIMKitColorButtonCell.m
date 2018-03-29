//
//  NIMKitColorButtonCell.m
//  NIM
//
//  Created by chris on 15/3/11.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMKitColorButtonCell.h"
#import "UIView+NIM.h"
#import "NIMCommonTableData.h"
#import "UIImage+NIMKit.h"

@interface NIMKitColorButtonCell()

@property (nonatomic,strong) NIMCommonTableRow *rowData;

@end

@implementation NIMKitColorButtonCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _button = [[NIMKitColorButton alloc] initWithFrame:CGRectZero];
        _button.nim_size = [_button sizeThatFits:CGSizeMake(self.nim_width, CGFLOAT_MAX)];
        _button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:_button];
    }
    return self;
}

- (void)refreshData:(NIMCommonTableRow *)rowData tableView:(UITableView *)tableView{
    self.rowData = rowData;
    [self.button setTitle:rowData.title forState:UIControlStateNormal];
    NIMKitColorButtonCellStyle style = [rowData.extraInfo integerValue];
    self.button.style = style;
    [self.button removeTarget:tableView.nim_viewController action:NULL forControlEvents:UIControlEventTouchUpInside];
    if (rowData.cellActionName.length) {
        SEL action = NSSelectorFromString(rowData.cellActionName);
        [_button addTarget:tableView.nim_viewController action:action forControlEvents:UIControlEventTouchUpInside];
    }
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    CGRect buttonRect = self.button.frame;
    if(CGRectContainsPoint(buttonRect, point)){
        return self;
    }
    return [super hitTest:point withEvent:event];
}


- (void)layoutSubviews{
    [super layoutSubviews];
    _button.nim_centerX = self.nim_width * .5f;
    _button.nim_centerY = self.nim_height * .5f;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [_button setSelected:selected];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    [_button setHighlighted:highlighted];
}

@end


@implementation NIMKitColorButton : UIButton

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self reset];
    }
    return self;
}

- (void)setStyle:(NIMKitColorButtonCellStyle)style{
    _style = style;
    [self reset];
}

- (void)reset{
    NSString *imageNormalName = @"";
    NSString *imageHighLightName  = @"";
    switch (self.style) {
        case NIMKitColorButtonCellStyleRed:
            imageNormalName = @"icon_cell_red_normal";
            imageHighLightName  = @"icon_cell_red_pressed";
            break;
        case NIMKitColorButtonCellStyleBlue:
            imageNormalName = @"icon_cell_blue_normal";
            imageHighLightName  = @"icon_cell_blue_pressed";
            break;
        default:
            break;
    }
    UIImage *imageNormal = [[UIImage nim_imageInKit:imageNormalName] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
    UIImage *imageHighLight = [[UIImage nim_imageInKit:imageHighLightName] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
    [self setBackgroundImage:imageNormal forState:UIControlStateNormal];
    [self setBackgroundImage:imageHighLight forState:UIControlStateHighlighted];
}

- (CGSize)sizeThatFits:(CGSize)size{
    return CGSizeMake(size.width - 20, 45);
}

@end
