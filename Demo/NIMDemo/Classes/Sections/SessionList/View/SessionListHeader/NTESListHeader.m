//
//  NTESSessionListHeader.m
//  NIM
//
//  Created by chris on 15/3/23.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESListHeader.h"
#import "UIView+NTES.h"
#import "Reachability.h"
#import "NTESClientUtil.h"

@interface NTESListHeader()

@end


@implementation NTESListHeader

- (void)refreshWithType:(NTESListHeaderType)type value:(id)value{
    switch (type) {
        case ListHeaderTypeCommonText:
            [self refreshWithCommonText:value];
            break;
        case ListHeaderTypeNetStauts:
            [self refreshWithNetStatus:[value integerValue]];
            break;
        case ListHeaderTypeLoginClients:
            [self refreshWithClients:value];
            break;
        default:
            break;
    }
    [self sizeToFit];
}


- (CGSize)sizeThatFits:(CGSize)size{
    CGFloat height = 0;
    for (UIView *subView in self.subviews) {
        [subView sizeToFit];
        height += subView.height;
    }
    return CGSizeMake(self.width,height);
}


- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat top = 0;
    for (UIView *subView in self.subviews) {
        subView.top = top;
        top = top + subView.height;
        subView.centerX = self.width * .5f;
    }
}


#pragma mark - Private
- (void)refreshWithClients:(NSArray *)clients{
    NSString *text = nil;
    if (clients.count) {
        //目前的踢人逻辑是web和pc不能共存，移动端不能共存，所以这里取第一个显示就可以了
        NIMLoginClient *client = clients.firstObject;
        NSString *name = [NTESClientUtil clientName:client.type];
        text = name.length? [NSString stringWithFormat:@"正在使用云信%@版",name] : @"正在使用云信未知版本";
    }
    [self addRow:ListHeaderTypeLoginClients content:text viewClassName:@"NTESMutiClientsHeaderView"];
}


- (void)refreshWithNetStatus:(NIMLoginStep)step{
    NSString *text = nil;
    switch (step) {
        case NIMLoginStepLinkFailed:
            text = @"当前网络不可用，请检查网络设置";
            break;
        case NIMLoginStepLoginFailed:
            text = @"登录失败";
            break;
        case NIMLoginStepNetChanged:
        {
            if ([[Reachability reachabilityForInternetConnection] isReachable])
            {
                text = @"网络正在切换,识别中....";
            }
            else
            {
                text = @"当前网络不可用";
            }
        }
            break;
        default:
            break;
    }
    [self refreshWithCommonText:text];
}

- (void)refreshWithCommonText:(NSString *)text{
    [self addRow:ListHeaderTypeCommonText content:text viewClassName:@"NTESTextHeaderView"];
}


//参数viewClassName的Class 必须是UIControl的子类并实现<NTESSessionListHeaderView>协议
- (void)addRow:(NTESListHeaderType)type content:(NSString *)content viewClassName:(NSString *)viewClassName{
    UIControl<NTESListHeaderView> *rowView = (UIControl<NTESListHeaderView> *)[self viewWithTag:type];
    if ([content length])
    {
        if (!rowView) {
            Class clazz = NSClassFromString(viewClassName);
            rowView = [[clazz alloc] initWithFrame:CGRectMake(0, 0, self.width, 0)];
            rowView.backgroundColor = [self fillBackgroundColor:type];
            __block NSInteger insert = self.subviews.count;
            [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                UIView *view = obj;
                if (view.tag > type) {
                    insert = idx;
                    *stop = YES;
                }
            }];
            rowView.tag = type;
            [self insertSubview:rowView atIndex:insert];
            [rowView addTarget:self action:@selector(didSelectRow:) forControlEvents:UIControlEventTouchUpInside];
        }
        [rowView setContentText:content];
    }
    else
    {
        [rowView removeFromSuperview];
    }
}


- (void)didSelectRow:(id)sender{
    UIControl *view = sender;
    if ([self.delegate respondsToSelector:@selector(didSelectRowType:)]) {
        [self.delegate didSelectRowType:view.tag];
    }
}


- (UIColor *) fillBackgroundColor:(NTESListHeaderType)type{
    NSDictionary *dict = @{
                           @(ListHeaderTypeNetStauts)    : [UIColor yellowColor],
                           @(ListHeaderTypeCommonText)   : UIColorFromRGB(0xefefef),
                           @(ListHeaderTypeLoginClients) : UIColorFromRGB(0xefefef)
                           };
    return dict[@(type)];
}

@end



