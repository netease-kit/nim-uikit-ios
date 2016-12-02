//
//  WhiteBoardDrawView.m
//  NIM
//
//  Created by 高峰 on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESWhiteboardDrawView.h"
#import <QuartzCore/QuartzCore.h>
#import "NTESCADisplayLinkHolder.h"

@interface NTESWhiteboardDrawView()<NTESCADisplayLinkHolderDelegate>

@property(nonatomic, strong)NSMutableArray *myLines;
@property(nonatomic, assign)BOOL shouldDraw;

@property(nonatomic, strong)NTESCADisplayLinkHolder *displayLinkHolder;

@end

@implementation NTESWhiteboardDrawView

#pragma mark - public methods
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _myLines = [[NSMutableArray alloc] init];
        
        CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer;
        shapeLayer.strokeColor = [UIColor blackColor].CGColor;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.lineJoin = kCALineJoinRound;
        shapeLayer.lineCap = kCALineCapRound;
        shapeLayer.lineWidth = 2;
        shapeLayer.masksToBounds = YES;
        
        _displayLinkHolder = [[NTESCADisplayLinkHolder alloc] init];
        [_displayLinkHolder setFrameInterval:3];
        [_displayLinkHolder startCADisplayLinkWithDelegate:self];
    }
    return self;
}

-(void)dealloc
{
    [_displayLinkHolder stop];
}

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (void)setLineColor:(UIColor *)color
{
    CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer;
    shapeLayer.strokeColor = color.CGColor;
}

- (void)addPoints:(NSMutableArray *)points isNewLine:(BOOL)newLine
{
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself addPoints:points toLines:[wself myLines] isNewLine:newLine];
    });
}

- (void)deleteLastLine
{
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself deleteLastLine:[wself myLines]];
    });

}

- (void)deleteAllLines
{
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself deleteAllLines:[wself myLines]];
    });
}

- (void)clear
{
    [self deleteAllLines];
}

#pragma mark - private methods
- (void)addPoints:(NSMutableArray *)points
          toLines:(NSMutableArray *)lines
        isNewLine:(BOOL)newLine
{
    if (newLine) {
        [lines addObject:points];
    }
    else if (lines.count == 0) {
        [lines addObject:points];
    }
    else {
        NSMutableArray *lastLine = [lines lastObject];
        [lastLine addObjectsFromArray:points];
    }
    _shouldDraw = YES;
}

-(void)deleteLastLine:(NSMutableArray *)lines
{
    [lines removeLastObject];
    _shouldDraw = YES;
}

-(void)deleteAllLines:(NSMutableArray *)lines
{
    [lines removeAllObjects];
    _shouldDraw = YES;
}

- (void)onDisplayLinkFire:(NTESCADisplayLinkHolder *)holder
                 duration:(NSTimeInterval)duration
              displayLink:(CADisplayLink *)displayLink
{
    if (!_shouldDraw) {
        return;
    }
    UIBezierPath *path = [[UIBezierPath alloc] init];
    NSUInteger linesCount = _myLines.count;
    for (NSUInteger i = 0 ; i < linesCount; i ++) {
        NSArray *line = [_myLines objectAtIndex:i];
        NSUInteger pointsCount = line.count;
        for (NSUInteger j = 0 ; j < pointsCount; j ++) {
            NSArray *point = [line objectAtIndex:j];
            CGPoint p = CGPointMake([point[0] floatValue], [point[1] floatValue]);
            if (j == 0) {
                [path moveToPoint:p];
            }
            else {
                [path addLineToPoint:p];
            }
        }
    }
    
    ((CAShapeLayer *)self.layer).path = path.CGPath;
    _shouldDraw = NO;
}


@end
