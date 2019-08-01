//
//  NIMKitUrlManager.m
//  NIMKit
//
//  Created by Netease on 2019/7/15.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMKitUrlManager.h"
#import "NIMKitTimerHolder.h"
#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

NSString *const kNIMKitUrlDataKey = @"kNIMKitUrlDataKey";

@interface NIMKitUrlManager ()<NIMKitTimerHolderDelegate>

@property (nonatomic, strong) NSMutableDictionary *dic;

@property (nonatomic, strong) NIMKitTimerHolder *timer;

@property (nonatomic, assign) BOOL needSync;

@end

@implementation NIMKitUrlManager

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[NIMKitUrlManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _dic = [self loadLocalFile];
        if (!_dic) {
            _dic = [NSMutableDictionary dictionary];
        }
        _timer = [[NIMKitTimerHolder alloc] init];
        [_timer startTimer:5.0f delegate:self repeats:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (void)queryQriginalUrlWithShortUrl:(NSString *)shortUrl
                          completion:(NIMKitUrlCompletion)completion {
    NSError *error = nil;
    if (!shortUrl) {
        error = [NSError errorWithDomain:@"nimkit.url.query" code:0x1000 userInfo:nil];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    NSString *ret = _dic[shortUrl];
    if (ret.length != 0) {
        if (completion) {
            completion(ret, nil);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].resourceManager fetchNOSURLWithURL:shortUrl
                                                completion:^(NSError * _Nullable error, NSString * _Nullable urlString) {
        if (!error && urlString) {
            [weakSelf storeShortUrl:shortUrl originalUrl:urlString];
        }
        if (completion) {
            completion(urlString, error);
        }
    }];
    
}

- (void)storeShortUrl:(NSString *)shortUrl originalUrl:(NSString *)originalUrl {
    if (!shortUrl || !originalUrl) {
        return;
    }
    if ([shortUrl isEqualToString:originalUrl]) {
        return;
    }
    if (!_dic[shortUrl]) {
        _dic[shortUrl] = [originalUrl copy];
        _needSync = YES;
    }
}

- (NSString *)originalUrlWithShortUrl:(NSString *)shortUrl {
    return _dic[shortUrl];
}

- (NSMutableDictionary *)loadLocalFile {
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] objectForKey:kNIMKitUrlDataKey];
    return [NSMutableDictionary dictionaryWithDictionary:dic];
}

- (void)syncToLocal {
    if (_needSync) {
        [[NSUserDefaults standardUserDefaults] setObject:_dic forKey:kNIMKitUrlDataKey];
        _needSync = NO;
    }
}

- (void)onNIMKitTimerFired:(NIMKitTimerHolder *)holder {
    if (holder != _timer) {
        return;
    }
    [self syncToLocal];
}

- (void)onEnterBackground:(NSNotification *)note {
    [self syncToLocal];
}

- (void)onTerminate:(NSNotification *)note {
    [self syncToLocal];
}

@end
