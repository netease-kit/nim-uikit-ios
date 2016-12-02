//
//  UIActionSheet+NTESBlock.m
//  eim_iphone
//
//  Created by amao on 12-11-23.
//  Copyright (c) 2012年 Netease. All rights reserved.
//

#import "UIActionSheet+NTESBlock.h"
#import <objc/runtime.h>

static char kUIActionSheetBlockAddress;


@implementation UIActionSheet (NTESBlock)


- (void)showInView: (UIView *)view completionHandler: (ActionSheetBlock)block
{
    self.delegate = self;
    objc_setAssociatedObject(self,&kUIActionSheetBlockAddress,block,OBJC_ASSOCIATION_COPY);
    
    if (view.window)
    {
        [self showInView:view];
    }
    else
    {
        UITabBar *tabbar = [self tabbarForPresent];
        if (tabbar)
        {
            [self showFromTabBar:tabbar];
        }
        else
        {
            //如果出现嵌套调用,会出现当前view的window因为被UIActionSheet的attachedWindow出现而置为nil的情况
            //所以这种情况下先hack一下
            [self performSelector:@selector(showInView:)
                       withObject:view
                       afterDelay:1];

        }
    }
}

- (UITabBar *)tabbarForPresent
{
    UITabBar *bar = nil;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        UIViewController *rootViewController= [[[UIApplication sharedApplication] keyWindow] rootViewController];
        if ([rootViewController isKindOfClass:[UITabBarController class]])
        {
            bar = [(UITabBarController *)rootViewController tabBar];
        }
    }
    return bar;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    ActionSheetBlock block = [objc_getAssociatedObject(self, &kUIActionSheetBlockAddress) copy];
    objc_setAssociatedObject(self,&kUIActionSheetBlockAddress,nil,OBJC_ASSOCIATION_COPY);
    dispatch_block_t dispatchBlock = ^(){
        if (block)
        {
            block(buttonIndex);
        }
    };
    //需要延迟的原因是actionsheet dismiss本身是个动画,如果在这种动画没完成的情况下直接调用present会导致两个切换冲突
    //这种情况在iOS5上最为明显
    dispatchBlock();
}


- (void)clearActionBlock
{
    self.delegate = nil;
    objc_setAssociatedObject(self,&kUIActionSheetBlockAddress,nil,OBJC_ASSOCIATION_COPY);
}


@end