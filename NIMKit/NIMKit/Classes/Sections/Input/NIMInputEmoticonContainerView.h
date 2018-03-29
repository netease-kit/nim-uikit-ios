//
//  NIMInputEmoticonContainerView.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMPageView.h"
#import "NIMSessionConfig.h"

@class NIMInputEmoticonCatalog;
@class NIMInputEmoticonTabView;

@protocol NIMInputEmoticonProtocol <NSObject>

- (void)didPressSend:(id)sender;

- (void)selectedEmoticon:(NSString*)emoticonID catalog:(NSString*)emotCatalogID description:(NSString *)description;

@end


@interface NIMInputEmoticonContainerView : UIView<NIMPageViewDataSource,NIMPageViewDelegate>

@property (nonatomic, strong)  NIMPageView *emoticonPageView;
@property (nonatomic, strong)  UIPageControl  *emotPageController;
@property (nonatomic, strong)  NSArray                    *totalCatalogData;
@property (nonatomic, strong)  NIMInputEmoticonCatalog    *currentCatalogData;
@property (nonatomic, readonly)NSArray            *allEmoticons;
@property (nonatomic, strong)  NIMInputEmoticonTabView   *tabView;
@property (nonatomic, weak)    id<NIMInputEmoticonProtocol>  delegate;
@property (nonatomic, weak)    id<NIMSessionConfig> config;

@end

