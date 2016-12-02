//
//  RTSDemoViewController.h
//  NIM
//
//  Created by 高峰 on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESWhiteboardViewController : UIViewController

- (id)initWithSessionID:(NSString *)sessionID
                 peerID:(NSString *)peerID
                  types:(NSUInteger)types
                   info:(NSString *)info;


@end
