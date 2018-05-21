//
//  NIMKitRobotTemplateLayout.h
//  NIMKit
//
//  Created by chris on 2017/6/25.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,NIMKitRobotTemplateItemType) {
    NIMKitRobotTemplateItemTypeText,
    NIMKitRobotTemplateItemTypeImage,
    NIMKitRobotTemplateItemTypeLink,
    NIMKitRobotTemplateItemTypeLinkURL,
    NIMKitRobotTemplateItemTypeLinkBlock,
};

@protocol NIMKitRobotTemplateContainer <NSObject>

- (NSMutableArray *)items;

@end

@interface NIMKitRobotTemplateItem : NSObject

@property (nonatomic, assign) NIMKitRobotTemplateItemType itemType;

@property (nonatomic, copy) NSString *content;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *width;

@property (nonatomic, copy) NSString *height;

@property (nonatomic, copy) NSString *color;

@property (nonatomic, copy) NSString *url;

@property (nonatomic, copy) NSString *thumbUrl;

@property (nonatomic, copy) NSString *target;

@property (nonatomic, copy) NSString *params;

@end

@interface NIMKitRobotTemplateLinkItem : NIMKitRobotTemplateItem<NIMKitRobotTemplateContainer>

@property (nonatomic, strong) NSMutableArray<NIMKitRobotTemplateItem *> *items;

@end


@interface NIMKitRobotTemplateLayout : NSObject<NIMKitRobotTemplateContainer>

@property (nonatomic, strong) NSMutableArray<NIMKitRobotTemplateItem *> *items;

@end
