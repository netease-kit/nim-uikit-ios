//
//  NIMKitMessageAtModel.m
//  NIMKit
//
//  Created by chris on 2016/12/7.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMKitMessageAtModel.h"

@implementation NIMKitMessageAtData
@end


@interface NIMKitMessageAtInfo()

@property (nonatomic,strong) NSMutableArray *atMessageListArray;

@end

@implementation NIMKitMessageAtInfo

- (id)initSendAtMessageInfo
{
    self = [super init];
    if (self)
    {
        self.atMessageListArray = [[NSMutableArray alloc] init];
    }
    return self;
}



- (void)addSendAtMessageData:(NIMKitMessageAtData *)data
{
    [self.atMessageListArray addObject:data];
}

- (NSRange)deleteTextWithRange:(NSRange)range
                          text:(NSString*)text
{
//    [self valideUserIDListWithText:text];
    __block NSRange resultRange = NSMakeRange(NSNotFound, 0);
    __block NSInteger totalLength = range.location + range.length;
    [self.atMessageListArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NIMKitMessageAtData *data = (NIMKitMessageAtData*)obj;
        if (data.range.location + data.range.length == totalLength)
        {
            resultRange = data.range;
            [self.atMessageListArray removeObject:obj];
        }
    }];
    return resultRange;
}
- (void)addTextWithReplaceRange:(NSRange)replaceRange
                           text:(NSString*)text
{
    //[self valideUserIDListWithText:text];
    [self.atMessageListArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NIMKitMessageAtData *data = (NIMKitMessageAtData*)obj;
        if (replaceRange.location >= data.range.location
            && replaceRange.location < (data.range.location + data.range.length)) {
            [self.atMessageListArray removeObject:obj];
        }
    }];
}

@end
