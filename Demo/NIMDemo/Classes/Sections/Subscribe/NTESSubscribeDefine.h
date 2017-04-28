//
//  NTESSubscribeDefine.h
//  NIM
//
//  Created by chris on 2017/4/5.
//  Copyright © 2017年 Netease. All rights reserved.
//

#ifndef NTESSubscribeDefine_h
#define NTESSubscribeDefine_h

extern NSString *const NTESSubscribeNetState;

extern NSString *const NTESSubscribeOnlineState;

typedef NS_ENUM(NSInteger, NTESCustomStateValue) {
    NTESCustomStateValueOnlineExt = 10001,
};


typedef NS_ENUM(NSInteger, NTESOnlineState){
    NTESOnlineStateNormal, //在线
    NTESOnlineStateBusy,   //忙碌
    NTESOnlineStateLeave,  //离开
};


#endif /* NTESSubscribeDefine_h */
