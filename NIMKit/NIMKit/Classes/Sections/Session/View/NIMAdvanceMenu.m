//
//  NIMAdvanceMenu.m
//  NIMKit
//
//  Created by He on 2020/3/26.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "NIMAdvanceMenu.h"
#import "NIMPageView.h"
#import "NIMMediaItem.h"
#import "UIView+NIM.h"
#import "NIMKit.h"
#import "NIMInputEmoticonButton.h"
#import "NIMInputEmoticonDefine.h"
#import "NIMInputEmoticonManager.h"
#import "UIButton+NIMKit.h"

static const NSInteger NIMMaxItemCountInPage = 8;
static const NSInteger NIMButtonItemWidth = 60;
static const NSInteger NIMButtonItemHeight = 60;
static const NSInteger NIMPageColumnCount  = 4;
static const NSInteger NIMButtonTopPadding = 5;

static const NSInteger kNIMEmoticonsCountInPage = 7;


@interface NIMAdvanceMenu () <NIMPageViewDataSource,NIMEmoticonButtonTouchDelegate>

@property (nonatomic,copy) NSArray *items;
@property (nonatomic,copy) NSArray *emoticons;
@property (nonatomic,copy) NSArray *mediaButtons;
@property (nonatomic,copy) NSArray *mediaItems;
@property (nonatomic,strong) UIView *panelView;
@property (nonatomic,strong) NIMPageView *pageView;
@property (nonatomic,strong) UIView *underLine;
@property (nonatomic,strong) NIMPageView *emotionView;
@property (nonatomic,assign) CGRect contentFrame;
@property (nonatomic,strong) UITapGestureRecognizer *tapGesutreRecoginzer;
@property (nonatomic,strong) NIMInputEmoticonLayout *layout;

@end

@implementation NIMAdvanceMenu

- (instancetype)initWithFrame:(CGRect)frame
                     emotions:(nullable NSArray *)quickEmotions
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        _contentFrame = frame;
        _emoticons = [quickEmotions copy];

        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
        _panelView = [[UIView alloc] initWithFrame:frame];
        _panelView.backgroundColor = [UIColor whiteColor];
        _panelView.layer.cornerRadius = 5.f;
        [self addSubview:_panelView];
        
        _pageView = [[NIMPageView alloc] initWithFrame:CGRectZero];
        _pageView.backgroundColor = [UIColor whiteColor];
        _pageView.layer.cornerRadius = 5.f;
        _pageView.dataSource = self;
        _tapGesutreRecoginzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBlank:)];
        [self addGestureRecognizer:_tapGesutreRecoginzer];
        [self addSubview:_pageView];
        
        if (quickEmotions.count > 0)
        {
            _underLine = [[UIView alloc] init];
            _underLine.backgroundColor = [UIColor grayColor];
            [self addSubview:_underLine];
            
            _emotionView = [[NIMPageView alloc] init];
            _emotionView.dataSource = self;
            _emotionView.scrollView.scrollEnabled = NO;
            [self addSubview:_emotionView];
        }
    }
    return self;
}

- (void)showWithMessage:(NIMMessage *)message
{
    [self genMediaButtonsWithMessage:message];
    [self.pageView reloadData];
    self.hidden = NO;
    [self setNeedsLayout];
}

- (void)dismiss
{
    self.hidden = YES;
}

- (void)setConfig:(id<NIMSessionConfig>)config
{
    _config = config;
    [self genMediaButtonsWithMessage:nil];
    [self.pageView reloadData];
}

- (void)genMediaButtonsWithMessage:(NIMMessage *)message
{
    NSMutableArray *mediaButtons = [NSMutableArray array];
    NSMutableArray *mediaItems = [NSMutableArray array];
    NSArray *items;
    if (!self.config)
    {
        items = [[NIMKit sharedKit].config defaultMenuItemsWithMessage:message];
    }
    else if([self.config respondsToSelector:@selector(menuItemsWithMessage:)])
    {
        items = [self.config menuItemsWithMessage:message];
    }
    [items enumerateObjectsUsingBlock:^(NIMMediaItem *item, NSUInteger idx, BOOL *stop) {
        [mediaItems addObject:item];
        
        UIButton *btn = [[UIButton alloc] init];
        btn.tag = idx;
        [btn setImage:item.normalImage forState:UIControlStateNormal];
        [btn setImage:item.selectedImage forState:UIControlStateHighlighted];
        [btn setTitle:item.title forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [mediaButtons addObject:btn];

    }];
    _mediaButtons = mediaButtons;
    _mediaItems = mediaItems;
}

- (CGSize)pageViewSize
{
    return CGSizeMake(self.contentFrame.size.width, NIMButtonTopPadding * 3 + NIMButtonItemHeight* 2);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.panelView.frame = self.contentFrame;
    self.panelView.nim_centerX = self.nim_centerX;
    self.panelView.nim_centerY = self.nim_centerY - 20;
    
    self.pageView.nim_size = [self pageViewSize];
    self.pageView.nim_top = self.panelView.nim_top;
    self.pageView.nim_centerX = self.panelView.nim_centerX;
    self.panelView.nim_bottom = self.pageView.nim_bottom + NIMButtonTopPadding;
    
    CGFloat heightOfEmotion = self.emoticons.count ? self.layout.cellHeight : 0;
    if (heightOfEmotion != 0)
    {
        self.underLine.nim_width = self.pageView.nim_width - 2 * 10;
        self.underLine.nim_height = 1;
        self.underLine.nim_centerX = self.pageView.nim_centerX;
        self.underLine.nim_top = self.pageView.nim_bottom + 2;
       
        self.emotionView.frame = CGRectMake(0, 0, self.contentFrame.size.width, heightOfEmotion - 4);
        self.emotionView.nim_top = self.underLine.nim_bottom + 2;
        self.emotionView.nim_centerX = self.underLine.nim_centerX;
        self.panelView.nim_bottom = self.emotionView.nim_bottom + NIMButtonTopPadding;
    }
    [self.mediaButtons enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj nim_verticalCenterImageAndTitleWithSpacing:5];
    }];
}

- (void)dealloc
{
    _pageView.dataSource = nil;
}


#pragma mark PageViewDataSource
- (NSInteger)numberOfPages:(NIMPageView *)pageView
{
    if ([pageView isEqual:self.emotionView])
    {
        if (self.emoticons.count == 0)
        {
            return 0;
        }
        
        NSInteger count = self.emoticons.count / kNIMEmoticonsCountInPage;
        if (self.emoticons.count % kNIMEmoticonsCountInPage)
        {
            count ++;
        }
        return count + 1;
    }
    
    NSInteger count = [_mediaButtons count] / NIMMaxItemCountInPage;
    count = ([_mediaButtons count] % NIMMaxItemCountInPage == 0) ? count: count + 1;
    return MAX(count, 1);
}

- (UIView*)mediaPageView:(NIMPageView*)pageView beginItem:(NSInteger)begin endItem:(NSInteger)end
{
    UIView *subView = [[UIView alloc] init];
    NSInteger span = ([self pageViewSize].width - NIMPageColumnCount * NIMButtonItemWidth) / (NIMPageColumnCount +1);
    CGFloat startY          = NIMButtonTopPadding;
    NSInteger coloumnIndex = 0;
    NSInteger rowIndex = 0;
    NSInteger indexInPage = 0;
    for (NSInteger index = begin; index < end; index ++)
    {
        UIButton *button = [_mediaButtons objectAtIndex:index];
        [button addTarget:self action:@selector(onTouchButton:) forControlEvents:UIControlEventTouchUpInside];
        //计算位置
        rowIndex    = indexInPage / NIMPageColumnCount;
        coloumnIndex= indexInPage % NIMPageColumnCount;
        CGFloat x = span + (NIMButtonItemWidth + span) * coloumnIndex;
        CGFloat y = 0.0;
        if (rowIndex > 0)
        {
            y = rowIndex * NIMButtonItemHeight + startY + NIMButtonTopPadding;
        }
        else
        {
            y = rowIndex * NIMButtonItemHeight + startY;
        }
        [button setFrame:CGRectMake(x, y, NIMButtonItemWidth, NIMButtonItemHeight)];
        [subView addSubview:button];
        indexInPage ++;
    }
    return subView;
}

- (UIView*)oneLineMediaInPageView:(NIMPageView *)pageView
                       viewInPage: (NSInteger)index
                            count:(NSInteger)count
{
    UIView *subView = [[UIView alloc] init];
    NSInteger span = ([self pageViewSize].width - count * NIMButtonItemWidth) / (count +1);
    
    for (NSInteger btnIndex = 0; btnIndex < count; btnIndex ++)
    {
        UIButton *button = [_mediaButtons objectAtIndex:btnIndex];
        [button addTarget:self action:@selector(onTouchButton:) forControlEvents:UIControlEventTouchUpInside];
        CGRect iconRect = CGRectMake(span + (NIMButtonItemWidth + span) * btnIndex, 58, NIMButtonItemWidth, NIMButtonItemHeight);
        [button setFrame:iconRect];
        [subView addSubview:button];
    }
    return subView;
}

- (UIView*)emojPageView:(NIMPageView*)pageView page:(NSInteger)page
{
    CGFloat padding = 2;
    NIMInputEmoticonLayout *layout = self.layout;
    UIView *subView = [[UIView alloc] init];
    NSInteger iconHeight    = layout.imageHeight - padding;
    NSInteger iconWidth     = layout.imageWidth - padding;
    CGFloat startX          = ((layout.cellWidth - padding) - iconWidth) / 2;
    CGFloat startY          = ((layout.cellHeight - padding) - iconHeight) / 2;
    int32_t coloumnIndex = 0;
    int32_t rowIndex = 0;
    int32_t indexInPage = 0;
    NSInteger begin = page * kNIMEmoticonsCountInPage;
    NSInteger end   = begin + kNIMEmoticonsCountInPage;
    end = end > self.emoticons.count ? (self.emoticons.count) : end;
    for (NSInteger index = begin; index < end; index ++)
    {
        NIMInputEmoticon *data = [self.emoticons objectAtIndex:index];
        
        NIMInputEmoticonButton *button = [NIMInputEmoticonButton iconButtonWithData:data catalogID:NIMKit_EmojiCatalog delegate:self];
        //计算表情位置
        rowIndex    = indexInPage / layout.columes;
        coloumnIndex= indexInPage % layout.columes;
        CGFloat x = startX + coloumnIndex * (layout.cellWidth + padding);
        CGFloat y = rowIndex * (layout.cellHeight - padding) + startY;
        CGRect iconRect = CGRectMake(x, y, iconWidth, iconHeight);
        [button setFrame:iconRect];
        [subView addSubview:button];
        indexInPage ++;
    }
    return subView;
}


- (UIView *)pageView:(NIMPageView *)pageView viewInPage:(NSInteger)index
{
    if ([pageView isEqual:self.emotionView])
    {
        return [self emojPageView:pageView
                             page:index];
    }
    
    if ([_mediaButtons count] == 2 || [_mediaButtons count] == 3) //一行显示2个或者3个
    {
        return [self oneLineMediaInPageView:pageView viewInPage:index count:[_mediaButtons count]];
    }
    
    if (index < 0)
    {
        assert(0);
        index = 0;
    }
    NSInteger begin = index * NIMMaxItemCountInPage;
    NSInteger end = (index + 1) * NIMMaxItemCountInPage;
    if (end > [_mediaButtons count])
    {
        end = [_mediaButtons count];
    }
    return [self mediaPageView:pageView beginItem:begin endItem:end];
}

#pragma mark - button actions
- (void)onTapBlank:(UITapGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:self];
    if (CGRectContainsPoint(self.pageView.frame, point))
    {
        return;
    }
    
    self.hidden = YES;
    if ([self.actionDelegate respondsToSelector:@selector(didReplyCancelled)])
    {
        [self.actionDelegate didReplyCancelled];
    }
}

- (void)onTouchButton:(id)sender
{
    NSInteger index = [(UIButton *)sender tag];
    NIMMediaItem *item = _mediaItems[index];
    [self dismiss];
    if (_actionDelegate && [_actionDelegate respondsToSelector:@selector(onTapMediaItem:)]) {
        BOOL handled = [_actionDelegate onTapMediaItem:item];
        if (!handled) {
            NSAssert(0, @"invalid item selector!");
        }
    }
    
}


#pragma mark - NIMEmoticonButtonTouchDelegate

- (void)selectedEmoticon:(NIMInputEmoticon*)emoticon catalogID:(NSString*)catalogID
{
    if ([self.actionDelegate respondsToSelector:@selector(onSelectEmoticon:)])
    {
        [self.actionDelegate onSelectEmoticon:emoticon];
    }
}


- (NIMInputEmoticonLayout *)layout
{
    if (!_layout)
    {
        _layout = [[NIMInputEmoticonLayout alloc] initEmojiLayout:self.nim_width];
    }
    return _layout;
}

@end
