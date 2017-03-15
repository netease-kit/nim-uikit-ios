//
//  NIMCommonTableData.h
//  NIM
//
//  Created by chris on 15/6/26.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SepLineLeft 15 //分割线距左边距离

//section key
#define HeaderTitle  @"headerTitle"
#define FooterTitle  @"footerTitle"
#define HeaderHeight @"headerHeight"
#define FooterHeight @"footerHeight"
#define RowContent   @"row"

//row key
#define Title         @"title"
#define DetailTitle   @"detailTitle"
#define CellClass     @"cellClass"
#define CellAction    @"action"
#define ExtraInfo     @"extraInfo"
#define RowHeight     @"rowHeight"
#define SepLeftEdge   @"leftEdge"


//common key
#define Disable       @"disable"      //cell不可见
#define ShowAccessory @"accessory"    //cell显示>箭头
#define ForbidSelect  @"forbidSelect" //cell不响应select事件

@interface NIMCommonTableSection : NSObject

@property (nonatomic,copy)   NSString *headerTitle;

@property (nonatomic,copy)   NSArray *rows;

@property (nonatomic,copy)   NSString *footerTitle;

@property (nonatomic,assign) CGFloat  uiHeaderHeight;

@property (nonatomic,assign) CGFloat  uiFooterHeight;

- (instancetype) initWithDict:(NSDictionary *)dict;

+ (NSArray *)sectionsWithData:(NSArray *)data;

@end




@interface NIMCommonTableRow : NSObject

@property (nonatomic,strong) NSString *title;

@property (nonatomic,copy  ) NSString *detailTitle;

@property (nonatomic,copy  ) NSString *cellClassName;

@property (nonatomic,copy  ) NSString *cellActionName;

@property (nonatomic,assign) CGFloat  uiRowHeight;

@property (nonatomic,assign) CGFloat  sepLeftEdge;

@property (nonatomic,assign) BOOL     showAccessory;

@property (nonatomic,assign) BOOL     forbidSelect;

@property (nonatomic,strong) id extraInfo;

- (instancetype) initWithDict:(NSDictionary *)dict;

+ (NSArray *)rowsWithData:(NSArray *)data;

@end




