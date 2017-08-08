//
//  NTESSearchLocalHistoryObject.h
//  NIM
//
//  Created by chris on 15/7/8.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NTESSearchLocalHistoryType){
    SearchLocalHistoryTypeEntrance,
    SearchLocalHistoryTypeContent,
};

@class NTESSearchLocalHistoryObject;
@protocol NTESSearchObjectRefresh <NSObject>

- (void)refresh:(NTESSearchLocalHistoryObject *)object;

@end

@interface NTESSearchLocalHistoryObject : NSObject

@property (nonatomic,copy)   NSString *content;

@property (nonatomic,assign) CGFloat uiHeight;

@property (nonatomic,assign) NTESSearchLocalHistoryType type;

@property (nonatomic,readonly) NIMMessage *message;

- (instancetype)initWithMessage:(NIMMessage *)message;

@end
