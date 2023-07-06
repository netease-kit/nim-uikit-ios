// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Provide some data-model method:

 * Convert json to any object, or convert any object to json.
 * Set object properties with a key-value dictionary (like KVC).
 * Implementations of `NSCoding`, `NSCopying`, `-hash` and `-isEqual:`.

 See `YXModel` protocol for custom methods.


 Sample Code:

     ********************** json convertor *********************
     @interface YXAuthor : NSObject
     @property (nonatomic, strong) NSString *name;
     @property (nonatomic, assign) NSDate *birthday;
     @end
     @implementation YXAuthor
     @end

     @interface YXBook : NSObject
     @property (nonatomic, copy) NSString *name;
     @property (nonatomic, assign) NSUInteger pages;
     @property (nonatomic, strong) YXAuthor *author;
     @end
     @implementation YXBook
     @end

     int main() {
         // create model from json
         YXBook *book = [YXBook yx_modelWithJSON:@"{\"name\": \"Harry Potter\", \"pages\": 256,
 \"author\": {\"name\": \"J.K.Rowling\", \"birthday\": \"1965-07-31\" }}"];

         // convert model to json
         NSString *json = [book yx_modelToJSONString];
         // {"author":{"name":"J.K.Rowling","birthday":"1965-07-31T00:00:00+0000"},"name":"Harry
 Potter","pages":256}
     }

     ********************** Coding/Copying/hash/equal *********************
     @interface YXShadow :NSObject <NSCoding, NSCopying>
     @property (nonatomic, copy) NSString *name;
     @property (nonatomic, assign) CGSize size;
     @end

     @implementation YXShadow
     - (void)encodeWithCoder:(NSCoder *)aCoder { [self yx_modelEncodeWithCoder:aCoder]; }
     - (id)initWithCoder:(NSCoder *)aDecoder { self = [super init]; return [self
 yx_modelInitWithCoder:aDecoder]; }
     - (id)copyWithZone:(NSZone *)zone { return [self yx_modelCopy]; }
     - (NSUInteger)hash { return [self yx_modelHash]; }
     - (BOOL)isEqual:(id)object { return [self yx_modelIsEqual:object]; }
     @end

 */
@interface NSObject (YXModel)

/**
 Creates and returns a new instance of the receiver from a json.
 This method is thread-safe.

 @param json  A json object in `NSDictionary`, `NSString` or `NSData`.

 @return A new instance created from the json, or nil if an error occurs.
 */
+ (nullable instancetype)yx_modelWithJSON:(id)json;

/**
 Creates and returns a new instance of the receiver from a key-value dictionary.
 This method is thread-safe.

 @param dictionary  A key-value dictionary mapped to the instance's properties.
 Any invalid key-value pair in dictionary will be ignored.

 @return A new instance created from the dictionary, or nil if an error occurs.

 @discussion The key in `dictionary` will mapped to the reciever's property name,
 and the value will set to the property. If the value's type does not match the
 property, this method will try to convert the value based on these rules:

     `NSString` or `NSNumber` -> c number, such as BOOL, int, long, float, NSUInteger...
     `NSString` -> NSDate, parsed with format "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss" or
 "yyyy-MM-dd". `NSString` -> NSURL. `NSValue` -> struct or union, such as CGRect, CGSize, ...
     `NSString` -> SEL, Class.
 */
+ (nullable instancetype)yx_modelWithDictionary:(NSDictionary *)dictionary;

/**
 Set the receiver's properties with a json object.

 @discussion Any invalid data in json will be ignored.

 @param json  A json object of `NSDictionary`, `NSString` or `NSData`, mapped to the
 receiver's properties.

 @return Whether succeed.
 */
- (BOOL)yx_modelSetWithJSON:(id)json;

/**
 Set the receiver's properties with a key-value dictionary.

 @param dic  A key-value dictionary mapped to the receiver's properties.
 Any invalid key-value pair in dictionary will be ignored.

 @discussion The key in `dictionary` will mapped to the reciever's property name,
 and the value will set to the property. If the value's type doesn't match the
 property, this method will try to convert the value based on these rules:

     `NSString`, `NSNumber` -> c number, such as BOOL, int, long, float, NSUInteger...
     `NSString` -> NSDate, parsed with format "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss" or
 "yyyy-MM-dd". `NSString` -> NSURL. `NSValue` -> struct or union, such as CGRect, CGSize, ...
     `NSString` -> SEL, Class.

 @return Whether succeed.
 */
- (BOOL)yx_modelSetWithDictionary:(NSDictionary *)dic;

/**
 Generate a json object from the receiver's properties.

 @return A json object in `NSDictionary` or `NSArray`, or nil if an error occurs.
 See [NSJSONSerialization isValidJSONObject] for more information.

 @discussion Any of the invalid property is ignored.
 If the reciver is `NSArray`, `NSDictionary` or `NSSet`, it just convert
 the inner object to json object.
 */
- (nullable id)yx_modelToJSONObject;

/**
 Generate a json string's data from the receiver's properties.

 @return A json string's data, or nil if an error occurs.

 @discussion Any of the invalid property is ignored.
 If the reciver is `NSArray`, `NSDictionary` or `NSSet`, it will also convert the
 inner object to json string.
 */
- (nullable NSData *)yx_modelToJSONData;

/**
 Generate a json string from the receiver's properties.

 @return A json string, or nil if an error occurs.

 @discussion Any of the invalid property is ignored.
 If the reciver is `NSArray`, `NSDictionary` or `NSSet`, it will also convert the
 inner object to json string.
 */
- (nullable NSString *)yx_modelToJSONString;

/**
 Copy a instance with the receiver's properties.

 @return A copied instance, or nil if an error occurs.
 */
- (nullable id)yx_modelCopy;

/**
 Encode the receiver's properties to a coder.

 @param aCoder  An archiver object.
 */
- (void)yx_modelEncodeWithCoder:(NSCoder *)aCoder;

/**
 Decode the receiver's properties from a decoder.

 @param aDecoder  An archiver object.

 @return self
 */
- (id)yx_modelInitWithCoder:(NSCoder *)aDecoder;

/**
 Get a hash code with the receiver's properties.

 @return Hash code.
 */
- (NSUInteger)yx_modelHash;

/**
 Compares the receiver with another object for equality, based on properties.

 @param model  Another object.

 @return `YES` if the reciever is equal to the object, otherwise `NO`.
 */
- (BOOL)yx_modelIsEqual:(id)model;

/**
 Description method for debugging purposes based on properties.

 @return A string that describes the contents of the receiver.
 */
- (NSString *)yx_modelDescription;

@end

/**
 Provide some data-model method for NSArray.
 */
@interface NSArray (YXModel)

/**
 Creates and returns an array from a json-array.
 This method is thread-safe.

 @param cls  The instance's class in array.
 @param json  A json array of `NSArray`, `NSString` or `NSData`.
              Example: [{"name","Mary"},{name:"Joe"}]

 @return A array, or nil if an error occurs.
 */
+ (nullable NSArray *)yx_modelArrayWithClass:(Class)cls json:(id)json;

@end

/**
 Provide some data-model method for NSDictionary.
 */
@interface NSDictionary (YXModel)

/**
 Creates and returns a dictionary from a json.
 This method is thread-safe.

 @param cls  The value instance's class in dictionary.
 @param json  A json dictionary of `NSDictionary`, `NSString` or `NSData`.
              Example: {"user1":{"name","Mary"}, "user2": {name:"Joe"}}

 @return A dictionary, or nil if an error occurs.
 */
+ (nullable NSDictionary *)yx_modelDictionaryWithClass:(Class)cls json:(id)json;
@end

/**
 If the default model transform does not fit to your model class, implement one or
 more method in this protocol to change the default key-value transform process.
 There's no need to add '<YXModel>' to your class header.
 */
@protocol YXModel <NSObject>
@optional

/**
 Custom property mapper.

 @discussion If the key in JSON/Dictionary does not match to the model's property name,
 implements this method and returns the additional mapper.

 Example:

    json:
        {
            "n":"Harry Pottery",
            "p": 256,
            "ext" : {
                "desc" : "A book written by J.K.Rowling."
            },
            "ID" : 100010
        }

    model:
        @interface YXBook : NSObject
        @property NSString *name;
        @property NSInteger page;
        @property NSString *desc;
        @property NSString *bookID;
        @end

        @implementation YXBook
        + (NSDictionary *)modelCustomPropertyMapper {
            return @{@"name"  : @"n",
                     @"page"  : @"p",
                     @"desc"  : @"ext.desc",
                     @"bookID": @[@"id", @"ID", @"book_id"]};
        }
        @end

 @return A custom mapper for properties.
 */
+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper;

/**
 The generic class mapper for container properties.

 @discussion If the property is a container object, such as NSArray/NSSet/NSDictionary,
 implements this method and returns a property->class mapper, tells which kind of
 object will be add to the array/set/dictionary.

  Example:
        @class YXShadow, YXBorder, YXAttachment;

        @interface YXAttributes
        @property NSString *name;
        @property NSArray *shadows;
        @property NSSet *borders;
        @property NSDictionary *attachments;
        @end

        @implementation YXAttributes
        + (NSDictionary *)modelContainerPropertyGenericClass {
            return @{@"shadows" : [YXShadow class],
                     @"borders" : YXBorder.class,
                     @"attachments" : @"YXAttachment" };
        }
        @end

 @return A class mapper.
 */
+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;

/**
 If you need to create instances of different classes during json->object transform,
 use the method to choose custom class based on dictionary data.

 @discussion If the model implements this method, it will be called to determine resulting class
 during `+modelWithJSON:`, `+modelWithDictionary:`, conveting object of properties of parent objects
 (both singular and containers via `+modelContainerPropertyGenericClass`).

 Example:
        @class YXCircle, YXRectangle, YXLine;

        @implementation YXShape

        + (Class)modelCustomClassForDictionary:(NSDictionary*)dictionary {
            if (dictionary[@"radius"] != nil) {
                return [YXCircle class];
            } else if (dictionary[@"width"] != nil) {
                return [YXRectangle class];
            } else if (dictionary[@"y2"] != nil) {
                return [YXLine class];
            } else {
                return [self class];
            }
        }

        @end

 @param dictionary The json/kv dictionary.

 @return Class to create from this dictionary, `nil` to use current class.

 */
+ (nullable Class)modelCustomClassForDictionary:(NSDictionary *)dictionary;

/**
 All the properties in blacklist will be ignored in model transform process.
 Returns nil to ignore this feature.

 @return An array of property's name.
 */
+ (nullable NSArray<NSString *> *)modelPropertyBlacklist;

/**
 If a property is not in the whitelist, it will be ignored in model transform process.
 Returns nil to ignore this feature.

 @return An array of property's name.
 */
+ (nullable NSArray<NSString *> *)modelPropertyWhitelist;

/**
 This method's behavior is similar to `- (BOOL)modelCustomTransformFromDictionary:(NSDictionary
 *)dic;`, but be called before the model transform.

 @discussion If the model implements this method, it will be called before
 `+modelWithJSON:`, `+modelWithDictionary:`, `-modelSetWithJSON:` and `-modelSetWithDictionary:`.
 If this method returns nil, the transform process will ignore this model.

 @param dic  The json/kv dictionary.

 @return Returns the modified dictionary, or nil to ignore this model.
 */
- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic;

/**
 If the default json-to-model transform does not fit to your model object, implement
 this method to do additional process. You can also use this method to validate the
 model's properties.

 @discussion If the model implements this method, it will be called at the end of
 `+modelWithJSON:`, `+modelWithDictionary:`, `-modelSetWithJSON:` and `-modelSetWithDictionary:`.
 If this method returns NO, the transform process will ignore this model.

 @param dic  The json/kv dictionary.

 @return Returns YES if the model is valid, or NO to ignore this model.
 */
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;

/**
 If the default model-to-json transform does not fit to your model class, implement
 this method to do additional process. You can also use this method to validate the
 json dictionary.

 @discussion If the model implements this method, it will be called at the end of
 `-modelToJSONObject` and `-modelToJSONString`.
 If this method returns NO, the transform process will ignore this json dictionary.

 @param dic  The json dictionary.

 @return Returns YES if the model is valid, or NO to ignore this model.
 */
- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
