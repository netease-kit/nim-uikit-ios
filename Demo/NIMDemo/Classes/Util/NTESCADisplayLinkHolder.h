//
//  NTESCADisplayLinkHolder.h
//  NIM
//
//  Created by Netease on 15/8/27.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NTESCADisplayLinkHolder;

@protocol NTESCADisplayLinkHolderDelegate <NSObject>

- (void)onDisplayLinkFire:(NTESCADisplayLinkHolder *)holder
                 duration:(NSTimeInterval)duration
              displayLink:(CADisplayLink *)displayLink;

@end


@interface NTESCADisplayLinkHolder : NSObject

@property (nonatomic,weak  ) id<NTESCADisplayLinkHolderDelegate> delegate;
@property (nonatomic,assign) NSInteger frameInterval;

- (void)startCADisplayLinkWithDelegate: (id<NTESCADisplayLinkHolderDelegate>)delegate;

- (void)stop;

@end
