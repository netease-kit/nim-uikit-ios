// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "XKitServiceManager.h"
#import "XKitLog.h"

static NSString *tag = @"XKitServiceManager";

@interface XKitServiceManager ()

@property(nonatomic, strong) NSMutableDictionary *services;

@end
@implementation XKitServiceManager

+ (instancetype)getInstance {
  static XKitServiceManager *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = self.new;
    instance.services = [NSMutableDictionary dictionary];
  });
  return instance;
}

- (void)registerService:(NSString *)serviceName service:(id<XKitService>)service {
  //  [XKitLog infoLog:tag
  //              desc:[NSString stringWithFormat:@"registerService:%@ %@", serviceName, service]];
  if (serviceName.length <= 0) {
    return;
  }
  self.services[serviceName] = service;
}

- (id)callService:(NSString *)serviceName method:(NSString *)method param:(NSDictionary *)param {
  //  [XKitLog infoLog:tag
  //              desc:[NSString stringWithFormat:@"callService:%@ method:%@", serviceName,
  //              method]];
  id<XKitService> service;
  if ([_services.allKeys containsObject:serviceName]) {
    service = _services[serviceName];
  }
  if (service && [service respondsToSelector:@selector(onMethodCall:param:)]) {
    return [service onMethodCall:method param:param];
  } else {
    return nil;
  }
}

- (id)getRegisterServer:(NSString *)serverName {
  return [self.services objectForKey:serverName];
}

- (BOOL)serviceIsRegister:(NSString *)serviceName {
  id object = [self getRegisterServer:serviceName];
  if (nil != object) {
    return YES;
  }
  return NO;
}
@end
