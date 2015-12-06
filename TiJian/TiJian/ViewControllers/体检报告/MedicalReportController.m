//
//  MedicalReportController.m
//  TiJian
//
//  Created by lichaowei on 15/12/4.
//  Copyright © 2015年 lcw. All rights reserved.
//

#import "MedicalReportController.h"
#import "AddReportViewController.h"
#import "ReportDetailController.h"

@interface MedicalReportController ()<RefreshDelegate,UITableViewDataSource>
{
    RefreshTableView *_table;
}

@end

@implementation MedicalReportController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.myTitle = @"体检报告";
    self.rightImage = [UIImage imageNamed:@"personal_jiaren_tianjia"];
    [self setMyViewControllerLeftButtonType:MyViewControllerLeftbuttonTypeNull WithRightButtonType:MyViewControllerRightbuttonTypeOther];
    [self prepareRefreshTableView];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(actionForNotify:) name:NOTIFICATION_REPORT_ADD_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(actionForNotify:) name:NOTIFICATION_REPORT_DEL_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(actionForNotify:) name:NOTIFICATION_LOGOUT object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(actionForNotify:) name:NOTIFICATION_LOGIN object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 通知

- (void)actionForNotify:(NSNotification *)notify
{
    [_table refreshNewData];
}

#pragma mark - 视图创建

- (void)prepareRefreshTableView
{
    _table = [[RefreshTableView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, DEVICE_HEIGHT - 64 - 49) style:UITableViewStylePlain];
    _table.refreshDelegate = self;
    _table.dataSource = self;
    _table.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_table];
    [_table showRefreshHeader:YES];
}

-(UIView *)resultView
{
    if (_resultView) {
        return _resultView;
    }
    ResultView *result = [[ResultView alloc]initWithImage:[UIImage imageNamed:@"hema_heart"]
                                                    title:@"温馨提示"
                                                  content:@"您还没有上传过体检报告,赶快去上传吧"];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 140, 36);
    [btn addCornerRadius:5.f];
    btn.backgroundColor = DEFAULT_TEXTCOLOR;
    [btn setTitle:@"立即上传" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [btn addTarget:self action:@selector(clickToUploadReport) forControlEvents:UIControlEventTouchUpInside];
    [result setBottomView:btn];
    
    self.resultView = result;
    
    return result;
}

#pragma mark - 网络请求

- (void)netWorkForList
{
    if (![LoginViewController isLogin]) {
        
        [_table reloadData:nil pageSize:G_PER_PAGE noDataView:self.resultView];

        return;
    }
    NSDictionary *params = @{@"authcode":[LTools cacheForKey:USER_AUTHOD],
                                 @"page":NSStringFromInt(_table.pageNum),
                             @"per_page":NSStringFromInt(G_PER_PAGE)};;
    NSString *api = REPORT_LIST;
    
    __weak typeof(self)weakSelf = self;
    __weak typeof(_table)weakTable = _table;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[YJYRequstManager shareInstance]requestWithMethod:YJYRequstMethodGet api:api parameters:params constructingBodyBlock:nil completion:^(NSDictionary *result) {
        NSLog(@"success result %@",result);
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
        
        NSArray *temp = [UserInfo modelsFromArray:result[@"list"]];
        [weakTable reloadData:temp pageSize:G_PER_PAGE];
        
    } failBlock:^(NSDictionary *result) {
        
        NSLog(@"fail result %@",result);
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
        [weakTable loadFailWithView:nil pageSize:G_PER_PAGE];
        
    }];
}

#pragma mark - 数据解析处理

#pragma mark - 事件处理
/**
 *  去上传报告
 */
- (void)clickToUploadReport
{
    [LoginViewController loginToDoWithViewController:self loginBlock:^(BOOL success) {
        if (success) {
            
            AddReportViewController *add = [[AddReportViewController alloc]init];
            add.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:add animated:YES];
        }
    }];
}

- (void)rightButtonTap:(UIButton *)sender
{
    [self clickToUploadReport];
}

#pragma mark - 代理

#pragma - mark RefreshDelegate <NSObject>

- (void)loadNewDataForTableView:(UITableView *)tableView
{
    [self netWorkForList];
}
- (void)loadMoreDataForTableView:(UITableView *)tableView
{
    [self netWorkForList];
}
- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    UserInfo *user = _table.dataArray[indexPath.row];
    ReportDetailController *detail = [[ReportDetailController alloc]init];
    detail.reportId = user.report_id;
    detail.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detail animated:YES];
}
- (CGFloat)heightForRowIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    return 55.f + 5.f;
}

-(CGFloat)heightForFooterInSection:(NSInteger)section tableView:(RefreshTableView *)tableView
{
    return 5.f;
}

-(UIView *)viewForFooterInSection:(NSInteger)section tableView:(RefreshTableView *)tableView
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 5)];
    view.backgroundColor = DEFAULT_VIEW_BACKGROUNDCOLOR;
    return view;
}

#pragma - mark UITableViewDataSource

#pragma - mark UITableViewDataSource<NSObject>

- (NSInteger)tableView:(RefreshTableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return tableView.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString *identifier = @"identify";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 5, DEVICE_WIDTH, 55)];
        view.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:view];
        
        UIImageView *iconImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 55, 55)];
        iconImage.image = [UIImage imageNamed:@"report_b"];
        iconImage.contentMode = UIViewContentModeCenter;
        [view addSubview:iconImage];
        
        UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(iconImage.right, 11, 200, 16) title:nil font:15 align:NSTextAlignmentLeft textColor:DEFAULT_TEXTCOLOR_TITLE];
        [view addSubview:titleLabel];
        titleLabel.tag = 200;
        
        UILabel *timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(iconImage.right, titleLabel.bottom, titleLabel.width, 20) title:nil font:12 align:NSTextAlignmentLeft textColor:DEFAULT_TEXTCOLOR_TITLE_SUB];
        [view addSubview:timeLabel];
        timeLabel.tag = 201;
        
        //箭头
        UIImageView *arrow = [[UIImageView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 35, 0, 35, 55)];
        arrow.image = [UIImage imageNamed:@"personal_jiantou_r"];
        arrow.contentMode = UIViewContentModeCenter;
        [view addSubview:arrow];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = DEFAULT_VIEW_BACKGROUNDCOLOR;
    UILabel *titleLabel = [cell.contentView viewWithTag:200];
    UILabel *timeLabel = [cell.contentView viewWithTag:201];
    UserInfo *user = _table.dataArray[indexPath.row];
    titleLabel.text = [NSString stringWithFormat:@"%@  %@的体检报告",user.appellation,user.family_user_name];
    timeLabel.text = user.checkup_time;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

@end
