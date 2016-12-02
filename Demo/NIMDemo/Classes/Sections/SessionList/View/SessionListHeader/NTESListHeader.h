//
//  NTESSessionListHeader.h
//  NIM
//
//  Created by chris on 15/3/23.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NTESListHeaderType) {
    ListHeaderTypeCommonText = 1,
    ListHeaderTypeNetStauts,
    ListHeaderTypeLoginClients,
};

@protocol NTESListHeaderView <NSObject>

@required
- (void)setContentText:(NSString *)content;

@end

@protocol NTESListHeaderDelegate <NSObject>

@optional

- (void)didSelectRowType:(NTESListHeaderType)type;

@end

@interface NTESListHeader : UIView

@property (nonatomic,weak) id<NTESListHeaderDelegate> delegate;

- (void)refreshWithType:(NTESListHeaderType)type value:(id)value;


@end
