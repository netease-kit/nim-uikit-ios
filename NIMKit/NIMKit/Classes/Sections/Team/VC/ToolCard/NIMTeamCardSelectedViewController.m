//
//  NIMTeamCardSelectedViewController.m
//  NIMKit
//
//  Created by Netease on 2019/7/16.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "NIMTeamCardSelectedViewController.h"
#import "NIMGlobalMacro.h"

@interface NIMTeamCardSelectedViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray <id <NIMKitSelectCardData>> *datas;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, assign) NSInteger oriSelectedIndex;

@end

@implementation NIMTeamCardSelectedViewController

+ (instancetype)instanceWithTitle:(NSString *)title
                            items:(NSMutableArray <id <NIMKitSelectCardData>> *)items
                           result:(NIMSelectedCompletion)result {
    NIMTeamCardSelectedViewController *vc = [[NIMTeamCardSelectedViewController alloc] initWithItems:items];
    vc.titleString = title ?: @"";
    vc.resultHandle = result;
    return vc;
}

- (instancetype)initWithItems:(NSMutableArray <id <NIMKitSelectCardData>> *)items {
    if (self = [super init]) {
        _datas = items;
        _selectedIndex = -1;
        __weak typeof(self) weakSelf = self;
        [items enumerateObjectsUsingBlock:^(id<NIMKitSelectCardData>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.selected) {
                weakSelf.selectedIndex = idx;
            }
        }];
        _oriSelectedIndex = _selectedIndex;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = _titleString ?: @"";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成".nim_localized style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _tableView.frame = self.view.bounds;
}

#pragma mark - Action
- (void)onDone:(id)sender {
    if (_oriSelectedIndex != _selectedIndex) {
        id <NIMKitSelectCardData> bodyData = _datas[_selectedIndex];
        if (_resultHandle) {
            _resultHandle(bodyData);
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _datas.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    id <NIMKitSelectCardData> bodyData = _datas[indexPath.row];
    static NSString *NIMTeamTableCellReuseId = @"cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NIMTeamTableCellReuseId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NIMTeamTableCellReuseId];
    }
    cell.accessoryType  = [bodyData selected]? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.textLabel.text = bodyData.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    _selectedIndex = indexPath.row;
    [_datas enumerateObjectsUsingBlock:^(id<NIMKitSelectCardData>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL selected = (idx == indexPath.row);
        [obj setSelected:selected];
    }];
    [self.tableView reloadData];
}

#pragma mark - Getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.bounces = NO;
        _tableView.sectionHeaderHeight = CGFLOAT_MIN;
        _tableView.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
    }
    return _tableView;
}
@end
