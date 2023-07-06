// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Type encoding's type.
 */
typedef NS_OPTIONS(NSUInteger, YXEncodingType) {
  YXEncodingTypeMask = 0xFF,      ///< mask of type value
  YXEncodingTypeUnknown = 0,      ///< unknown
  YXEncodingTypeVoid = 1,         ///< void
  YXEncodingTypeBool = 2,         ///< bool
  YXEncodingTypeInt8 = 3,         ///< char / BOOL
  YXEncodingTypeUInt8 = 4,        ///< unsigned char
  YXEncodingTypeInt16 = 5,        ///< short
  YXEncodingTypeUInt16 = 6,       ///< unsigned short
  YXEncodingTypeInt32 = 7,        ///< int
  YXEncodingTypeUInt32 = 8,       ///< unsigned int
  YXEncodingTypeInt64 = 9,        ///< long long
  YXEncodingTypeUInt64 = 10,      ///< unsigned long long
  YXEncodingTypeFloat = 11,       ///< float
  YXEncodingTypeDouble = 12,      ///< double
  YXEncodingTypeLongDouble = 13,  ///< long double
  YXEncodingTypeObject = 14,      ///< id
  YXEncodingTypeClass = 15,       ///< Class
  YXEncodingTypeSEL = 16,         ///< SEL
  YXEncodingTypeBlock = 17,       ///< block
  YXEncodingTypePointer = 18,     ///< void*
  YXEncodingTypeStruct = 19,      ///< struct
  YXEncodingTypeUnion = 20,       ///< union
  YXEncodingTypeCString = 21,     ///< char*
  YXEncodingTypeCArray = 22,      ///< char[10] (for example)

  YXEncodingTypeQualifierMask = 0xFF00,     ///< mask of qualifier
  YXEncodingTypeQualifierConst = 1 << 8,    ///< const
  YXEncodingTypeQualifierIn = 1 << 9,       ///< in
  YXEncodingTypeQualifierInout = 1 << 10,   ///< inout
  YXEncodingTypeQualifierOut = 1 << 11,     ///< out
  YXEncodingTypeQualifierBycopy = 1 << 12,  ///< bycopy
  YXEncodingTypeQualifierByref = 1 << 13,   ///< byref
  YXEncodingTypeQualifierOneway = 1 << 14,  ///< oneway

  YXEncodingTypePropertyMask = 0xFF0000,         ///< mask of property
  YXEncodingTypePropertyReadonly = 1 << 16,      ///< readonly
  YXEncodingTypePropertyCopy = 1 << 17,          ///< copy
  YXEncodingTypePropertyRetain = 1 << 18,        ///< retain
  YXEncodingTypePropertyNonatomic = 1 << 19,     ///< nonatomic
  YXEncodingTypePropertyWeak = 1 << 20,          ///< weak
  YXEncodingTypePropertyCustomGetter = 1 << 21,  ///< getter=
  YXEncodingTypePropertyCustomSetter = 1 << 22,  ///< setter=
  YXEncodingTypePropertyDynamic = 1 << 23,       ///< @dynamic
};

/**
 Get the type from a Type-Encoding string.

 @discussion See also:
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

 @param typeEncoding  A Type-Encoding string.
 @return The encoding type.
 */
YXEncodingType YXEncodingGetType(const char *typeEncoding);

/**
 Instance variable information.
 */
@interface YXClassIvarInfo : NSObject
@property(nonatomic, assign, readonly) Ivar ivar;               ///< ivar opaque struct
@property(nonatomic, strong, readonly) NSString *name;          ///< Ivar's name
@property(nonatomic, assign, readonly) ptrdiff_t offset;        ///< Ivar's offset
@property(nonatomic, strong, readonly) NSString *typeEncoding;  ///< Ivar's type encoding
@property(nonatomic, assign, readonly) YXEncodingType type;     ///< Ivar's type

/**
 Creates and returns an ivar info object.

 @param ivar ivar opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithIvar:(Ivar)ivar;
@end

/**
 Method information.
 */
@interface YXClassMethodInfo : NSObject
@property(nonatomic, assign, readonly) Method method;   ///< method opaque struct
@property(nonatomic, strong, readonly) NSString *name;  ///< method name
@property(nonatomic, assign, readonly) SEL sel;         ///< method's selector
@property(nonatomic, assign, readonly) IMP imp;         ///< method's implementation
@property(nonatomic, strong, readonly)
    NSString *typeEncoding;  ///< method's parameter and return types
@property(nonatomic, strong, readonly) NSString *returnTypeEncoding;  ///< return value's type
@property(nullable, nonatomic, strong, readonly)
    NSArray<NSString *> *argumentTypeEncodings;  ///< array of arguments' type

/**
 Creates and returns a method info object.

 @param method method opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithMethod:(Method)method;
@end

/**
 Property information.
 */
@interface YXClassPropertyInfo : NSObject
@property(nonatomic, assign, readonly) objc_property_t property;  ///< property's opaque struct
@property(nonatomic, strong, readonly) NSString *name;            ///< property's name
@property(nonatomic, assign, readonly) YXEncodingType type;       ///< property's type
@property(nonatomic, strong, readonly) NSString *typeEncoding;    ///< property's encoding value
@property(nonatomic, strong, readonly) NSString *ivarName;        ///< property's ivar name
@property(nullable, nonatomic, strong, readonly) Class cls;       ///< may be nil
@property(nullable, nonatomic, strong, readonly) NSArray<NSString *> *protocols;  ///< may nil
@property(nonatomic, assign, readonly) SEL getter;  ///< getter (nonnull)
@property(nonatomic, assign, readonly) SEL setter;  ///< setter (nonnull)

/**
 Creates and returns a property info object.

 @param property property opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithProperty:(objc_property_t)property;
@end

/**
 Class information for a class.
 */
@interface YXClassInfo : NSObject
@property(nonatomic, strong, readonly) Class cls;                 ///< class object
@property(nullable, nonatomic, strong, readonly) Class superCls;  ///< super class object
@property(nullable, nonatomic, strong, readonly) Class metaCls;   ///< class's meta class object
@property(nonatomic, readonly) BOOL isMeta;             ///< whether this class is meta class
@property(nonatomic, strong, readonly) NSString *name;  ///< class name
@property(nullable, nonatomic, strong, readonly)
    YXClassInfo *superClassInfo;  ///< super class's class info
@property(nullable, nonatomic, strong, readonly)
    NSDictionary<NSString *, YXClassIvarInfo *> *ivarInfos;  ///< ivars
@property(nullable, nonatomic, strong, readonly)
    NSDictionary<NSString *, YXClassMethodInfo *> *methodInfos;  ///< methods
@property(nullable, nonatomic, strong, readonly)
    NSDictionary<NSString *, YXClassPropertyInfo *> *propertyInfos;  ///< properties

/**
 If the class is changed (for example: you add a method to this class with
 'class_addMethod()'), you should call this method to refresh the class info cache.

 After called this method, `needUpdate` will returns `YES`, and you should call
 'classInfoWithClass' or 'classInfoWithClassName' to get the updated class info.
 */
- (void)setNeedUpdate;

/**
 If this method returns `YES`, you should stop using this instance and call
 `classInfoWithClass` or `classInfoWithClassName` to get the updated class info.

 @return Whether this class info need update.
 */
- (BOOL)needUpdate;

/**
 Get the class info of a specified Class.

 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.

 @param cls A class.
 @return A class info, or nil if an error occurs.
 */
+ (nullable instancetype)classInfoWithClass:(Class)cls;

/**
 Get the class info of a specified Class.

 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.

 @param className A class name.
 @return A class info, or nil if an error occurs.
 */
+ (nullable instancetype)classInfoWithClassName:(NSString *)className;

@end

NS_ASSUME_NONNULL_END
