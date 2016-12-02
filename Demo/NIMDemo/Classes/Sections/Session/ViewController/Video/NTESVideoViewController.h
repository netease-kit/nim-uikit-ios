//
//  NTESVideoViewController.h
//  NIM
//
//  Created by chris on 15/4/12.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
@interface NTESVideoViewController : UIViewController

- (instancetype)initWithVideoObject:(NIMVideoObject *)videoObject;

@property (nonatomic, readonly) MPMoviePlayerController *moviePlayer;

@end
