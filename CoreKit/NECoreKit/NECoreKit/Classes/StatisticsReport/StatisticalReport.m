// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "StatisticalReport.h"
#import "YXModel.h"

#import "NEReportConstans.h"
#import "ReportActionInfo.h"
#import "ReportModuleInfo.h"
#import "YXModel.h"

static int apiTimeOut = 10;

@interface StatisticalReport () <NSURLSessionDelegate>

@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) dispatch_queue_t dispatchQueue;
@property(nonatomic, strong) NSOperationQueue *operationQueue;
@property(nonatomic, strong) dispatch_semaphore_t sema;
@property(nonatomic, strong) dispatch_queue_t reportQueue;

@property(nonatomic, strong) NSMutableArray<NSDictionary *> *items;
@property(nonatomic, strong) NSString *filePath;
@property(nonatomic, strong) NSURL *reportURL;

@property(nonatomic, assign) BOOL hasInit;

@property(nonatomic, strong) ReportConfig *config;

@property(nonatomic, assign) NSInteger cacheCount;

@property(nonatomic, strong) NSMutableDictionary<NSString *, ReportModuleInfo *> *mouduleInfos;

@property(nonatomic, strong) NSMutableDictionary<NSString *, ApiEventInfo *> *moduleEvents;

@property(nonatomic, strong) NSMutableArray<ReportModuleInfo *> *defaultKeyReportCache;

@property(nonatomic, strong) NSLock *moduleEventLock;

@end

@implementation StatisticalReport

+ (instancetype)sharedInstance {
  static id instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = self.new;
  });
  return instance;
}

- (void)reportConfig:(ReportConfig *)config {
  if (self.hasInit == YES) {
    return;
  }
  self.config = config;
  self.hasInit = YES;
  if (config.cacheCount > 0) {
    self.cacheCount = config.cacheCount;
  }
}

- (void)setDefaultKey:(NSString *)defaultKey {
  _defaultKey = defaultKey;
  [self reportDefaultKey];
}

- (void)reportDefaultKey {
  if (self.defaultKeyReportCache.count > 0) {
    for (ReportModuleInfo *item in self.defaultKeyReportCache) {
      [self reportWithServiceName:item.serviceName
                   withReprotType:REPORT_TYPE_INIT
                         withData:nil
                     withRightNow:false];
    }

    [self.defaultKeyReportCache removeAllObjects];
  }
}

- (void)registerModule:(NSString *)serviceName
           withVersion:(NSString *)versionName
          moduleAppKey:(NSString *)moduleAppKey {
  if (serviceName.length <= 0) {
    return;
  }
  ReportModuleInfo *info = [self.mouduleInfos objectForKey:serviceName];
  if (info == nil) {
    info = [[ReportModuleInfo alloc] init];
    [self.mouduleInfos setObject:info forKey:serviceName];
  }
  NSString *appKey = moduleAppKey;
  if (!appKey || appKey.length <= 0) {
    appKey = self.defaultKey;
  }
  info.serviceName = serviceName;
  info.versionName = versionName;
  info.appkey = appKey;
  if (self.hasInit && appKey.length > 0) {
    [self reportWithServiceName:serviceName
                 withReprotType:REPORT_TYPE_INIT
                       withData:nil
                   withRightNow:true];
  } else {
    [self.defaultKeyReportCache addObject:info];
  }
}

- (ReportModuleInfo *)moudelInfo:(NSString *)serviceName {
  return [self.mouduleInfos objectForKey:serviceName];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.requestTimeOut = 30;
    self.cacheCount = 10;
    self.sema = dispatch_semaphore_create(1);
    self.dispatchQueue =
        dispatch_queue_create("com.netease.yunxin.kit.xkit.dispatchqueue", DISPATCH_QUEUE_SERIAL);
    self.reportQueue =
        dispatch_queue_create("com.netease.yunxin.kit.xkit.reportqueue", DISPATCH_QUEUE_SERIAL);
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.underlyingQueue = self.dispatchQueue;
    self.session =
        [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                      delegate:self
                                 delegateQueue:self.operationQueue];

    self.mouduleInfos = [[NSMutableDictionary alloc] init];
    self.moduleEvents = [[NSMutableDictionary alloc] init];
    self.defaultKeyReportCache = [NSMutableArray array];
    self.items = NSMutableArray.array;
    self.moduleEventLock = [[NSLock alloc] init];
    NSString *reportDir =
        [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject
            stringByAppendingPathComponent:@"NEXkit/Report"];
    if (![NSFileManager.defaultManager fileExistsAtPath:reportDir isDirectory:nil]) {
      NSError *error;
      [NSFileManager.defaultManager createDirectoryAtPath:reportDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    }
    self.filePath = [reportDir stringByAppendingPathComponent:@"items"];
    self.reportURL = [NSURL URLWithString:URL_REPORT];
    dispatch_async(self.reportQueue, ^{
      NSArray *items = [NSKeyedUnarchiver unarchiveObjectWithFile:self.filePath];
      if (items) {
        [self.items addObjectsFromArray:items];
      }
    });
  }
  return self;
}

- (void)reportWithServiceName:(NSString *)serviceName
               withReprotType:(NSString *)reportType
                     withData:(id)data
                 withRightNow:(BOOL)rightNow {
  ReportModuleInfo *info = [self moudelInfo:serviceName];
  if (info == nil) {
    return;
  }
  BaseReportData *reportData = [[BaseReportData alloc] initWithConfig:self.config];
  reportData.data = data;
  NSTimeInterval nowtime = [[NSDate date] timeIntervalSince1970] * 1000;
  reportData.timeStamp = (long)nowtime;
  reportData.component = serviceName;
  reportData.version = info.versionName;
  reportData.reportType = reportType;
  if (rightNow == YES) {
    [self report:reportData];
  } else {
    NSDictionary *dic = [reportData yx_modelToJSONObject];
    [self reportEvent:dic];
  }
}

#pragma mark-- report

- (void)reportWithServiceName:(NSString *)serviceName
                   withPVInfo:(ReportPVInfo *)pvInfo
                 withRightNow:(BOOL)rightNow {
  [self reportWithServiceName:serviceName
               withReprotType:REPORT_TYPE_PV
                     withData:pvInfo
                 withRightNow:rightNow];
}

- (void)reportWithServiceName:(NSString *)serviceName
                   withUVInfo:(ReportUVInfo *)uvInfo
                 withRightNow:(BOOL)rightNow {
  [self reportWithServiceName:serviceName
               withReprotType:REPORT_TYPE_UV
                     withData:uvInfo
                 withRightNow:rightNow];
}

- (void)reportApiCallbackEvent:(NSString *)serviceName
                          info:(ApiCallbackEventInfo *)info
                      rightNow:(BOOL)rightNow {
  [self reportWithServiceName:serviceName
               withReprotType:REPORT_TYPE_EVENT_API
                     withData:info
                 withRightNow:rightNow];
}
- (void)reportCallbackEvent:(NSString *)serviceName
                       info:(CallbackEventInfo *)info
                   rightNow:(BOOL)rightNow {
  [self reportWithServiceName:serviceName
               withReprotType:REPORT_TYPE_EVENT_CALLBACK
                     withData:info
                 withRightNow:rightNow];
}

- (NSNumber *)beginReport:(NSString *)api params:(NSString *)params {
  ApiEventInfo *event = [[ApiEventInfo alloc] init];
  event.api = api;
  event.params = params;
  /// 获取当前时间戳
  NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970] * 1000;
  event.time = nowTime;
  long times = [[NSNumber numberWithInt:nowTime] longValue];
  NSNumber *requestIdNumber =
      @([[NSString stringWithFormat:@"%ld%d", times, arc4random() % 10000] integerValue]);
  long realRequestId = [requestIdNumber longValue];
  event.requestId = realRequestId;
  [self.moduleEventLock lock];
  [self.moduleEvents setValue:event forKey:[NSString stringWithFormat:@"%ld", realRequestId]];
  [self.moduleEventLock unlock];
  return [NSNumber numberWithLong:realRequestId];
}

- (void)endReport:(NSString *)serviceName
        requestId:(NSNumber *)requestId
             code:(NSNumber *)code
         response:(NSString *)response
         rightNow:(BOOL)rightNow {
  [self.moduleEventLock lock];
  ApiEventInfo *apiEvent =
      [self.moduleEvents objectForKey:[NSString stringWithFormat:@"%@", requestId]];
  if (apiEvent) {
    if (code != nil) {
      apiEvent.code = code;
    }
    if (response) {
      apiEvent.response = response;
    }
    /// 获取当前时间戳
    NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970] * 1000;
    apiEvent.costTime = nowTime - apiEvent.time;
    /// 数据上报
    [self.moduleEventLock unlock];
    [self reportWithServiceName:serviceName
                 withReprotType:REPORT_TYPE_EVENT_API
                       withData:apiEvent
                   withRightNow:rightNow];
    /// 数据移出
    [self.moduleEventLock lock];
    [self.moduleEvents removeObjectForKey:[NSString stringWithFormat:@"%@", requestId]];
    [self.moduleEventLock unlock];
  } else {
    /// 出现异常
    [self.moduleEventLock unlock];
  }
}

- (void)report:(nullable BaseReportData *)data {
  dispatch_async(self.reportQueue, ^{
    /// 超时数据移出
    [self checkReportData];
    NSTimeInterval nowtime = [[NSDate date] timeIntervalSince1970] * 1000;
    data.timeStamp = (long)nowtime;
    NSString *reportJson = [data yx_modelToJSONString];
    NSData *bodyData = [reportJson dataUsingEncoding:NSUTF8StringEncoding];
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.reportURL];
    [request setTimeoutInterval:self.requestTimeOut];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:bodyData];
    [request setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Content-type"];
    NSURLSessionDataTask *task = [self.session
        dataTaskWithRequest:request
          completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                              NSError *_Nullable error) {
            if (error) {
              dispatch_semaphore_signal(self.sema);
              return;
            }
            NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
            if (resp.statusCode != 200) {
              dispatch_semaphore_signal(self.sema);
              return;
            }
            dispatch_semaphore_signal(self.sema);
          }];
    [task resume];
  });
}

- (void)checkReportData {
  [self.moduleEventLock lock];
  for (NSString *key in self.moduleEvents.allKeys) {
    ApiEventInfo *apiEventInfo = self.moduleEvents[key];
    if (apiEventInfo.costTime > 0) {
      /// 已经走了End
      if (apiEventInfo.costTime > (apiTimeOut * 10)) {
        /// 数据刨除
        [self.moduleEvents removeObjectForKey:key];
      }
    }
  }
  [self.moduleEventLock unlock];
}
- (void)reportEvent:(nullable NSDictionary *)event {
  if (!event) return;
  dispatch_async(self.reportQueue, ^{
    [self.items addObject:event];
    if (self.items.count > self.cacheCount) {
      [self flush];
      return;
    }
    BOOL res = [NSKeyedArchiver archiveRootObject:self.items toFile:self.filePath];
    if (!res) {
      // NCKLogError(@"Save items failed: %@", self.items);  // Not gonna happen
    }
  });
}

- (void)flushAsync {
  NSLog(@"self.items count : %lu", (unsigned long)self.items.count);
  if (!self.items.count) return;
  dispatch_async(self.reportQueue, ^{
    [self flush];
  });
}

- (void)flush {
  if (!self.items.count) return;
  dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.reportURL];
  [request setHTTPMethod:@"POST"];

  NSError *error;
  NSData *bodyData = [NSJSONSerialization dataWithJSONObject:self.items options:0 error:&error];
  //  NCKLogInfo(@"report data : %@", [[NSString alloc] initWithData:bodyData
  //                                                        encoding:NSUTF8StringEncoding]);
  [request setHTTPBody:bodyData];
  [request setTimeoutInterval:self.requestTimeOut];
  [request setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Content-type"];

  NSURLSessionDataTask *task =
      [self.session dataTaskWithRequest:request
                      completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                                          NSError *_Nullable error) {
                        if (error) {
                          NSLog(@"Report failed: \n event: %@ \n error: %@ \n", self.items, error);
                          dispatch_semaphore_signal(self.sema);
                          return;
                        }
                        NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
                        if (resp.statusCode != 200) {
                          NSLog(@"Report failed: \n event: %@ \n statusCode: %@ \n", self.items,
                                @(resp.statusCode));
                          dispatch_semaphore_signal(self.sema);
                          return;
                        }
                        [NSFileManager.defaultManager removeItemAtPath:self.filePath error:nil];
                        NSLog(@"Report events succeed: %@!", self.items);
                        [self.items removeAllObjects];
                        dispatch_semaphore_signal(self.sema);
                      }];
  [task resume];
}

@end
