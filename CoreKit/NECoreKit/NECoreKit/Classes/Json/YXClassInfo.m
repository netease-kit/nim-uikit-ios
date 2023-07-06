// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "YXClassInfo.h"
#import <objc/runtime.h>

YXEncodingType YXEncodingGetType(const char *typeEncoding) {
  char *type = (char *)typeEncoding;
  if (!type) return YXEncodingTypeUnknown;
  size_t len = strlen(type);
  if (len == 0) return YXEncodingTypeUnknown;

  YXEncodingType qualifier = 0;
  bool prefix = true;
  while (prefix) {
    switch (*type) {
      case 'r': {
        qualifier |= YXEncodingTypeQualifierConst;
        type++;
      } break;
      case 'n': {
        qualifier |= YXEncodingTypeQualifierIn;
        type++;
      } break;
      case 'N': {
        qualifier |= YXEncodingTypeQualifierInout;
        type++;
      } break;
      case 'o': {
        qualifier |= YXEncodingTypeQualifierOut;
        type++;
      } break;
      case 'O': {
        qualifier |= YXEncodingTypeQualifierBycopy;
        type++;
      } break;
      case 'R': {
        qualifier |= YXEncodingTypeQualifierByref;
        type++;
      } break;
      case 'V': {
        qualifier |= YXEncodingTypeQualifierOneway;
        type++;
      } break;
      default: {
        prefix = false;
      } break;
    }
  }

  len = strlen(type);
  if (len == 0) return YXEncodingTypeUnknown | qualifier;

  switch (*type) {
    case 'v':
      return YXEncodingTypeVoid | qualifier;
    case 'B':
      return YXEncodingTypeBool | qualifier;
    case 'c':
      return YXEncodingTypeInt8 | qualifier;
    case 'C':
      return YXEncodingTypeUInt8 | qualifier;
    case 's':
      return YXEncodingTypeInt16 | qualifier;
    case 'S':
      return YXEncodingTypeUInt16 | qualifier;
    case 'i':
      return YXEncodingTypeInt32 | qualifier;
    case 'I':
      return YXEncodingTypeUInt32 | qualifier;
    case 'l':
      return YXEncodingTypeInt32 | qualifier;
    case 'L':
      return YXEncodingTypeUInt32 | qualifier;
    case 'q':
      return YXEncodingTypeInt64 | qualifier;
    case 'Q':
      return YXEncodingTypeUInt64 | qualifier;
    case 'f':
      return YXEncodingTypeFloat | qualifier;
    case 'd':
      return YXEncodingTypeDouble | qualifier;
    case 'D':
      return YXEncodingTypeLongDouble | qualifier;
    case '#':
      return YXEncodingTypeClass | qualifier;
    case ':':
      return YXEncodingTypeSEL | qualifier;
    case '*':
      return YXEncodingTypeCString | qualifier;
    case '^':
      return YXEncodingTypePointer | qualifier;
    case '[':
      return YXEncodingTypeCArray | qualifier;
    case '(':
      return YXEncodingTypeUnion | qualifier;
    case '{':
      return YXEncodingTypeStruct | qualifier;
    case '@': {
      if (len == 2 && *(type + 1) == '?')
        return YXEncodingTypeBlock | qualifier;
      else
        return YXEncodingTypeObject | qualifier;
    }
    default:
      return YXEncodingTypeUnknown | qualifier;
  }
}

@implementation YXClassIvarInfo

- (instancetype)initWithIvar:(Ivar)ivar {
  if (!ivar) return nil;
  self = [super init];
  if (self != nil) {
    _ivar = ivar;
    const char *name = ivar_getName(ivar);
    if (name) {
      _name = [NSString stringWithUTF8String:name];
    }
    _offset = ivar_getOffset(ivar);
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (typeEncoding) {
      _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
      _type = YXEncodingGetType(typeEncoding);
    }
  }
  return self;
}

@end

@implementation YXClassMethodInfo

- (instancetype)initWithMethod:(Method)method {
  if (!method) return nil;
  self = [super init];
  if (self != nil) {
    _method = method;
    _sel = method_getName(method);
    _imp = method_getImplementation(method);
    const char *name = sel_getName(_sel);
    if (name) {
      _name = [NSString stringWithUTF8String:name];
    }
    const char *typeEncoding = method_getTypeEncoding(method);
    if (typeEncoding) {
      _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
    }
    char *returnType = method_copyReturnType(method);
    if (returnType) {
      _returnTypeEncoding = [NSString stringWithUTF8String:returnType];
      free(returnType);
    }
    unsigned int argumentCount = method_getNumberOfArguments(method);
    if (argumentCount > 0) {
      NSMutableArray *argumentTypes = [NSMutableArray new];
      for (unsigned int i = 0; i < argumentCount; i++) {
        char *argumentType = method_copyArgumentType(method, i);
        NSString *type = argumentType ? [NSString stringWithUTF8String:argumentType] : nil;
        [argumentTypes addObject:type ? type : @""];
        if (argumentType) free(argumentType);
      }
      _argumentTypeEncodings = argumentTypes;
    }
  }
  return self;
}

@end

@implementation YXClassPropertyInfo

- (instancetype)initWithProperty:(objc_property_t)property {
  if (!property) return nil;
  self = [super init];
  if (self != nil) {
    _property = property;
    const char *name = property_getName(property);
    if (name) {
      _name = [NSString stringWithUTF8String:name];
    }

    YXEncodingType type = 0;
    unsigned int attrCount;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
    if (attrs != nil) {
      for (unsigned int i = 0; i < attrCount; i++) {
        switch (attrs[i].name[0]) {
          case 'T': {  // Type encoding
            if (attrs[i].value) {
              _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
              type = YXEncodingGetType(attrs[i].value);

              if ((type & YXEncodingTypeMask) == YXEncodingTypeObject && _typeEncoding.length) {
                NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
                if (![scanner scanString:@"@\"" intoString:NULL]) continue;

                NSString *clsName = nil;
                if ([scanner
                        scanUpToCharactersFromSet:[NSCharacterSet
                                                      characterSetWithCharactersInString:@"\"<"]
                                       intoString:&clsName]) {
                  if (clsName.length) _cls = objc_getClass(clsName.UTF8String);
                }

                NSMutableArray *protocols = nil;
                while ([scanner scanString:@"<" intoString:NULL]) {
                  NSString *protocol = nil;
                  if ([scanner scanUpToString:@">" intoString:&protocol]) {
                    if (protocol.length) {
                      if (!protocols) protocols = [NSMutableArray new];
                      [protocols addObject:protocol];
                    }
                  }
                  [scanner scanString:@">" intoString:NULL];
                }
                _protocols = protocols;
              }
            }
          } break;
          case 'V': {  // Instance variable
            if (attrs[i].value) {
              _ivarName = [NSString stringWithUTF8String:attrs[i].value];
            }
          } break;
          case 'R': {
            type |= YXEncodingTypePropertyReadonly;
          } break;
          case 'C': {
            type |= YXEncodingTypePropertyCopy;
          } break;
          case '&': {
            type |= YXEncodingTypePropertyRetain;
          } break;
          case 'N': {
            type |= YXEncodingTypePropertyNonatomic;
          } break;
          case 'D': {
            type |= YXEncodingTypePropertyDynamic;
          } break;
          case 'W': {
            type |= YXEncodingTypePropertyWeak;
          } break;
          case 'G': {
            type |= YXEncodingTypePropertyCustomGetter;
            if (attrs[i].value) {
              _getter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
            }
          } break;
          case 'S': {
            type |= YXEncodingTypePropertyCustomSetter;
            if (attrs[i].value) {
              _setter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
            }
          }  // break; commented for code coverage in next line
          default:
            break;
        }
      }
      free(attrs);
      attrs = NULL;
    }

    _type = type;
    if (_name.length) {
      if (!_getter) {
        _getter = NSSelectorFromString(_name);
      }
      if (!_setter) {
        _setter = NSSelectorFromString(
            [NSString stringWithFormat:@"set%@%@:", [_name substringToIndex:1].uppercaseString,
                                       [_name substringFromIndex:1]]);
      }
    }
  }
  return self;
}

@end

@implementation YXClassInfo {
  BOOL _needUpdate;
}

- (instancetype)initWithClass:(Class)cls {
  if (!cls) return nil;
  self = [super init];
  if (self != nil) {
    _cls = cls;
    _superCls = class_getSuperclass(cls);
    _isMeta = class_isMetaClass(cls);
    if (!_isMeta) {
      _metaCls = objc_getMetaClass(class_getName(cls));
    }
    _name = NSStringFromClass(cls);
    [self _update];

    _superClassInfo = [self.class classInfoWithClass:_superCls];
  }
  return self;
}

- (void)_update {
  _ivarInfos = nil;
  _methodInfos = nil;
  _propertyInfos = nil;

  Class cls = self.cls;
  unsigned int methodCount = 0;
  Method *methods = class_copyMethodList(cls, &methodCount);
  if (methods) {
    NSMutableDictionary *methodInfos = [NSMutableDictionary new];
    _methodInfos = methodInfos;
    for (unsigned int i = 0; i < methodCount; i++) {
      YXClassMethodInfo *info = [[YXClassMethodInfo alloc] initWithMethod:methods[i]];
      if (info.name) methodInfos[info.name] = info;
    }
    free(methods);
  }
  unsigned int propertyCount = 0;
  objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
  if (properties) {
    NSMutableDictionary *propertyInfos = [NSMutableDictionary new];
    _propertyInfos = propertyInfos;
    for (unsigned int i = 0; i < propertyCount; i++) {
      YXClassPropertyInfo *info = [[YXClassPropertyInfo alloc] initWithProperty:properties[i]];
      if (info.name) propertyInfos[info.name] = info;
    }
    free(properties);
  }

  unsigned int ivarCount = 0;
  Ivar *ivars = class_copyIvarList(cls, &ivarCount);
  if (ivars) {
    NSMutableDictionary *ivarInfos = [NSMutableDictionary new];
    _ivarInfos = ivarInfos;
    for (unsigned int i = 0; i < ivarCount; i++) {
      YXClassIvarInfo *info = [[YXClassIvarInfo alloc] initWithIvar:ivars[i]];
      if (info.name) ivarInfos[info.name] = info;
    }
    free(ivars);
  }

  if (!_ivarInfos) _ivarInfos = @{};
  if (!_methodInfos) _methodInfos = @{};
  if (!_propertyInfos) _propertyInfos = @{};

  _needUpdate = NO;
}

- (void)setNeedUpdate {
  _needUpdate = YES;
}

- (BOOL)needUpdate {
  return _needUpdate;
}

+ (instancetype)classInfoWithClass:(Class)cls {
  if (!cls) return nil;
  static CFMutableDictionaryRef classCache;
  static CFMutableDictionaryRef metaCache;
  static dispatch_once_t onceToken;
  static dispatch_semaphore_t lock;
  dispatch_once(&onceToken, ^{
    classCache =
        CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks,
                                  &kCFTypeDictionaryValueCallBacks);
    metaCache =
        CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks,
                                  &kCFTypeDictionaryValueCallBacks);
    lock = dispatch_semaphore_create(1);
  });
  dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
  YXClassInfo *info = CFDictionaryGetValue(class_isMetaClass(cls) ? metaCache : classCache,
                                           (__bridge const void *)(cls));
  if (info && info->_needUpdate) {
    [info _update];
  }
  dispatch_semaphore_signal(lock);
  if (!info) {
    info = [[YXClassInfo alloc] initWithClass:cls];
    if (info) {
      dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
      CFDictionarySetValue(info.isMeta ? metaCache : classCache, (__bridge const void *)(cls),
                           (__bridge const void *)(info));
      dispatch_semaphore_signal(lock);
    }
  }
  return info;
}

+ (instancetype)classInfoWithClassName:(NSString *)className {
  Class cls = NSClassFromString(className);
  return [self classInfoWithClass:cls];
}

@end
