//
//  NTESContactDataMember.m
//  NIM
//
//  Created by chris on 15/9/21.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESContactDataMember.h"
#import "NTESSpellingCenter.h"

@implementation NTESContactDataMember

- (CGFloat)uiHeight{
    return 50;
}

//userId和Vcname必有一个有值，根据有值的状态push进不同的页面

- (NSString *)vcName{
    return nil;
}

- (NSString *)reuseId{
    return @"NTESContactDataItem";
}

- (NSString *)cellName{
    return @"NIMContactDataCell";
}

- (NSString *)badge{
    return @"";
}

- (NSString *)groupTitle {
    NSString *title = [[NTESSpellingCenter sharedCenter] firstLetter:self.info.showName].capitalizedString;
    unichar character = [title characterAtIndex:0];
    if (character >= 'A' && character <= 'Z') {
        return title;
    }else{
        return @"#";
    }
}

- (NSString *)userId{
    return self.info.infoId;
}

- (UIImage *)icon{
    return self.info.avatarImage;
}

- (NSString *)avatarUrl{
    return self.info.avatarUrlString;
}

- (NSString *)memberId{
    return self.info.infoId;
}

- (NSString *)showName{
    return self.info.showName;
}

- (BOOL)showAccessoryView{
    return NO;
}

- (id)sortKey {
    return [[NTESSpellingCenter sharedCenter] spellingForString:self.info.showName].shortSpelling;
}

- (BOOL)isEqual:(id)object{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    return [self.info.infoId isEqualToString:[[object info] infoId]];
}


@end
