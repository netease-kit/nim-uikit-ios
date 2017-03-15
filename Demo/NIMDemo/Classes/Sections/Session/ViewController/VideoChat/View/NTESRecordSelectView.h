//
//  NTESRecordSelectView.h
//  NIM
//
//  Created by Simon Blue on 17/2/21.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol  NTESRecordSelectViewDelegate <NSObject>

-(void)onRecordWithAudioConversation:(BOOL)audioConversationOn myMedia:(BOOL)myMediaOn otherSideMedia:(BOOL)otherSideMediaOn;

@end

@interface NTESRecordSelectView : UIView

-(instancetype)initWithFrame:(CGRect)frame Video:(BOOL)isVideo;

@property(nonatomic,weak)id<NTESRecordSelectViewDelegate> delegate;

@end
