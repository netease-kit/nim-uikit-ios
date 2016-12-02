//
//  WhiteBoardDrawView.h
//  NIM
//
//  Created by 高峰 on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESWhiteboardDrawView : UIView

- (void)setLineColor:(UIColor *)color;

- (void)addPoints:(NSMutableArray *)points isNewLine:(BOOL)newLine;

- (void)deleteLastLine;

- (void)clear;

@end
