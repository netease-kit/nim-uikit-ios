//
//  NIMKitRobotTemplateParser.m
//  NIMKit
//
//  Created by chris on 2017/6/25.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMKitRobotDefaultTemplateParser.h"
#import "NSDictionary+NIMKit.h"
#import <NIMSDK/NIMSDK.h>

// 三种容器类(可嵌套)标签名
#define NIMKitRobotElementNameTemplate @"template"
#define NIMKitRobotElementNameLayout   @"LinearLayout"
#define NIMKitRobotElementNameLink     @"link"


#define NNIMKitRobotResponseTypeText     @"01" //文本消息，
#define NNIMKitRobotResponseTypeImage    @"02" //图片消息，
#define NNIMKitRobotResponseTypeFast     @"03" //快速回复
#define NNIMKitRobotResponseTypeComplex  @"11" //复杂模板

@interface NIMKitRobotDefaultTemplateParser()<NSXMLParserDelegate>
{
    NSString *_currentTagName;
    
    NSString *_currentMessageId;
    
    //可以成为容器类的 Class ，即实现了 NIMKitRobotTemplateContainer 协议
    NSSet *_containerClass;
    
    //容器，用来区分 tag 间的层级关系
    NSMutableArray *_containers;
}

@property (nonatomic,strong) NSMutableDictionary *robotTemplates;

@property (nonatomic,strong) NSDictionary<NSString *, NSNumber *> *elementNameMapping;

@end

@implementation NIMKitRobotDefaultTemplateParser

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _elementNameMapping = @{
                              //属性特殊字段映射
                                @"text"  : @(NIMKitRobotTemplateItemTypeText),
                                @"image" : @(NIMKitRobotTemplateItemTypeImage),
                                @"link"  : @(NIMKitRobotTemplateItemTypeLink),
                            };
        _containerClass = [NSSet setWithObjects:@"NIMKitRobotTemplate",@"NIMKitRobotTemplateLayout",@"NIMKitRobotTemplateLinkItem",nil];
        _containers = [[NSMutableArray alloc] init];
        _robotTemplates = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)clean
{
    [self.robotTemplates removeAllObjects];
}

- (NIMKitRobotTemplate *)robotTemplate:(NIMMessage *)message
{
    NIMKitRobotTemplate *template = [self.robotTemplates objectForKey:message.messageId];
    if (template)
    {
        return template;
    }
    
    _currentMessageId = message.messageId;

    NIMRobotObject *object = (NIMRobotObject *)message.messageObject;
    NSString *flag = [object.response nimkit_jsonString:@"flag"];
    if ([flag isEqualToString:@"bot"])
    {
        return [self resolveBotTemplate:object];
    }
    if ([flag isEqualToString:@"faq"])
    {
        return [self resolveFaqTemplate:object];
    }
    NSAssert(0, @"invalid robot template");
    return nil;
}

- (NIMKitRobotTemplate *)resolveBotTemplate:(NIMRobotObject *)object
{
    NIMKitRobotTemplate *template = [[NIMKitRobotTemplate alloc] init];
    template.version = @"0.1"; //默认版本
    [self.robotTemplates setObject:template forKey:object.message.messageId];
    
    for (NSDictionary *dict in [object.response nimkit_jsonArray:@"message"])
    {
        if ([dict isKindOfClass:[NSDictionary class]])
        {
            NSString *templateText = [dict nimkit_jsonString:@"content"];
            NSString *type = [dict nimkit_jsonString:@"type"];
            if([type isEqualToString:NNIMKitRobotResponseTypeComplex] )
            {
                [self parse:templateText];
            }
            if ([type isEqualToString:NNIMKitRobotResponseTypeText])
            {
                NIMKitRobotTemplateLayout *layout = [self genTextRobotLayout:templateText];
                [template.items addObject:layout];
            }
            if ([type isEqualToString:NNIMKitRobotResponseTypeImage])
            {
                NIMKitRobotTemplateLayout *layout =  [self genImageRobotLayout:templateText];
                [template.items addObject:layout];
            }
        }
    }
    return template;
}

- (NIMKitRobotTemplate *)resolveFaqTemplate:(NIMRobotObject *)object
{
    NIMKitRobotTemplate *template = [[NIMKitRobotTemplate alloc] init];
    template.version = @"0.1"; //默认版本
    
    NSDictionary *match = [[object.response nimkit_jsonDict:@"message"]  nimkit_jsonArray:@"match"].firstObject;
    if ([match isKindOfClass:[NSDictionary class]])
    {
        NSString *answer = [match nimkit_jsonString:@"answer"];
        NIMKitRobotTemplateLayout *layout = [self genTextRobotLayout:answer];
        [template.items addObject:layout];
    }
    return template;
}


- (BOOL)parse:(NSString *)templateText
{
    NSData *data = [templateText dataUsingEncoding:NSUTF8StringEncoding];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    return [parser parse];
}

- (NIMKitRobotTemplateLayout *)genTextRobotLayout:(NSString *)templateText
{
    NIMKitRobotTemplateLayout *layout  = [[NIMKitRobotTemplateLayout alloc] init];
    NIMKitRobotTemplateItem *templateItem = [[NIMKitRobotTemplateItem alloc] init];
    templateItem.content = templateText;
    templateItem.itemType = NIMKitRobotTemplateItemTypeText;
    
    layout.items = [@[templateItem] mutableCopy];
    
    return layout;
}

- (NIMKitRobotTemplateLayout *)genImageRobotLayout:(NSString *)templateText
{
    NIMKitRobotTemplateLayout *layout  = [[NIMKitRobotTemplateLayout alloc] init];
    NIMKitRobotTemplateItem *templateItem = [[NIMKitRobotTemplateItem alloc] init];
    templateItem.url = templateText;
    templateItem.itemType = NIMKitRobotTemplateItemTypeImage;
    
    CGFloat defaultImageWidth  = 75.f;
    CGFloat defaultImageHeight = 75.f;
    
    templateItem.width  = @(defaultImageWidth).stringValue;
    templateItem.height = @(defaultImageHeight).stringValue;
    
    layout.items = [@[templateItem] mutableCopy];
    
    return layout;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    //由于系统XML解析器是一级一级解下去的，所以要记录好当前容器，用来表示嵌套关系
    //当遇到容器类时，总容器 _containers 会加上这个容器类的 items , 下一次解析即使用这个 items 容器
    //当解析节点结束时，如果节点为容器节点，则在总容器里 _containers 里去掉最后一个容器，下一次解析会自动用上一层的容器，符合 xml 的嵌套关系
    
    _currentTagName = elementName;
    NSObject *item = nil;
    if ([elementName isEqualToString:NIMKitRobotElementNameTemplate])
    {
        NIMKitRobotTemplate *robotTemplate = [self.robotTemplates objectForKey:_currentMessageId];
        item = robotTemplate;
    }
    else if ([elementName isEqualToString:NIMKitRobotElementNameLayout])
    {
        NIMKitRobotTemplateLayout *layout = [[NIMKitRobotTemplateLayout alloc] init];
        [_containers.lastObject addObject:layout];
        item = layout;
    }
    else
    {
        NIMKitRobotTemplateItem *templateItem;
        if ([elementName isEqualToString:NIMKitRobotElementNameLink])
        {
            templateItem = [[NIMKitRobotTemplateLinkItem alloc] init];
        }
        else
        {
            templateItem = [[NIMKitRobotTemplateItem alloc] init];
        }
        
        [_containers.lastObject addObject:templateItem];
        item = templateItem;
        templateItem.itemType = [self.elementNameMapping nimkit_jsonInteger:elementName];
    }
    
    if ([_containerClass containsObject:NSStringFromClass([item class])]) {
        id<NIMKitRobotTemplateContainer> container = (id<NIMKitRobotTemplateContainer>)item;
        [_containers addObject:container.items];
    }
    
    
    for (NSString *key in attributeDict)
    {
        id value = [attributeDict objectForKey:key];
        [item setValue:value forKey:key];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    _currentTagName = nil;
    if ([elementName isEqualToString:NIMKitRobotElementNameTemplate]
        || [elementName isEqualToString:NIMKitRobotElementNameLayout]
        || [elementName isEqualToString:NIMKitRobotElementNameLink])
    {
        [_containers removeLastObject];
    }
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([string isEqualToString:@""]) {
        return;
    }
    NIMKitRobotTemplateItem *templateItem = [(NSArray *)_containers.lastObject lastObject];
    
    if ([_currentTagName isEqualToString:@"text"] && templateItem) {
        //文本过长会分段解析，这里要追加
        NSString *content = templateItem.content? templateItem.content : @"";
        templateItem.content = [content stringByAppendingString:string];;
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"parser error: %@",parseError);
}
- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    NSLog(@"validation error: %@",validationError);
}

@end
