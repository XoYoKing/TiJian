//
//  AppointmentViewController.m
//  TiJian
//
//  Created by lichaowei on 15/11/13.
//  Copyright © 2015年 lcw. All rights reserved.
//

#import "AppointmentViewController.h"

#import "PersonalCustomViewController.h"//个性化定制
#import "PhysicalTestResultController.h"//测试结果
#import "ChooseHopitalController.h"//选择分院和时间
#import "AppointDetailController.h"//预约详情
#import "GStoreHomeViewController.h"//商城
#import "GoneClassListViewController.h"
#import "AppointProgressDetailController.h"//已体检预约进度
#import "GoHealthProductDetailController.h" //go健康详情页或者服务详情页

#import "ProductModel.h"
#import "AppointmentCell.h"
#import "AppointModel.h"
#define kTagButton 300
#define kTagTableView 200

@interface AppointmentViewController ()<RefreshDelegate,UITableViewDataSource,UIScrollViewDelegate>
{
    RefreshTableView *_table;
    NSArray *_company;
    NSArray *_personal;
    NSArray *_expired;//已过期
    NSArray *_no_expired;//未过期
    NSArray *_finished;//已体检
    int _currentPage;//当前页面
    NSString *_companyName;//公司名字
}
@property(nonatomic,retain)UIScrollView *scroll;
@property(nonatomic,retain)UIView *allNoDataView;//全部没有数据view
@property(nonatomic,retain)UIView *noAppointView;//待预约view
@property(nonatomic,retain)UIView *appointedView;//已预约view
@property(nonatomic,retain)UIView *appointedOverView;//已预约过期view
@property(nonatomic,retain)UIView *appointedExamedView;//预约已体检view

@end

@implementation AppointmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.myTitle = @"体检预约";
    [self setMyViewControllerLeftButtonType:MyViewControllerLeftbuttonTypeBack WithRightButtonType:MyViewControllerRightbuttonTypeNull];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationForAppointSuccess) name:NOTIFICATION_APPOINT_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationForAppointSuccess) name:NOTIFICATION_APPOINT_CANCEL_SUCCESS object:nil];
    //更新预约
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationForUpdateAppointSuccess) name:NOTIFICATION_APPOINT_UPDATE_SUCCESS object:nil];
    
    //创建视图
    [self prepareView];
    //请求数据
    [self tableViewWithIndex:0].isHaveLoaded = YES;
    [[self tableViewWithIndex:0] showRefreshHeader:YES];
    [self buttonWithIndex:0].selected = YES;
    _currentPage = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 通知处理

- (void)notificationForAppointSuccess
{
    //刷新预约情况
    [[self tableViewWithIndex:0]showRefreshHeader:YES];//全部
    [[self tableViewWithIndex:1]showRefreshHeader:YES];//已预约
    [[self tableViewWithIndex:2]showRefreshHeader:YES];//已预约
}

/**
 *  更新预约成功
 */
- (void)notificationForUpdateAppointSuccess
{
    //刷新预约情况
    [[self tableViewWithIndex:2]showRefreshHeader:YES];//已过期
    [[self tableViewWithIndex:3]showRefreshHeader:YES];//已预约
    [[self tableViewWithIndex:0]showRefreshHeader:YES];//全部

}

#pragma mark - 视图创建

-(UIView *)allNoDataView
{
    if (!_allNoDataView) {
        _allNoDataView = [self noDataView];
    }
    return _allNoDataView;
}

/**
 *  待预约为空时
 *
 *  @return
 */
- (UIView *)noAppointView
{
    if (!_noAppointView) {
        
        _noAppointView = [self noDataView];
    }
    return _noAppointView;
}

- (UIView *)noDataView
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, DEVICE_HEIGHT - 64)];
    view.backgroundColor = DEFAULT_VIEW_BACKGROUNDCOLOR;
    CGFloat width = FitScreen(96);
    width = iPhone4 ? width * 0.8 : width;
    
    UIImageView *icon = [[UIImageView alloc]initWithFrame:CGRectMake(38, 55, width, width)];
    icon.image = [UIImage imageNamed:@"hema"];
    [view addSubview:icon];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, icon.bottom - 5, DEVICE_WIDTH, 15) title:@"您还没有任何套餐可以预约" font:14 align:NSTextAlignmentCenter textColor:[UIColor colorWithHexString:@"323232"]];
    [view addSubview:label];
    
    label = [[UILabel alloc]initWithFrame:CGRectMake(0, label.bottom + 5, DEVICE_WIDTH, 15) title:@"您可以先" font:14 align:NSTextAlignmentCenter textColor:[UIColor colorWithHexString:@"323232"]];
    [view addSubview:label];
    
    width = DEVICE_WIDTH / 3.f;
    CGFloat aver = width / 5.f;
    for (int i = 0; i < 2; i ++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(aver * 2 + (width + aver) * i, label.bottom + 35, width, 30);
        [view addSubview:btn];
        [btn addCornerRadius:5.f];
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        if (i == 0) {
            [btn setBorderWidth:0.5 borderColor:DEFAULT_TEXTCOLOR];
            [btn setTitle:@"购买套餐" forState:UIControlStateNormal];
            [btn setTitleColor:DEFAULT_TEXTCOLOR forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(clickToBuy) forControlEvents:UIControlEventTouchUpInside];
        }else
        {
            [btn setBorderWidth:0.5 borderColor:[UIColor colorWithHexString:@"ec7d24"]];
            [btn setTitle:@"定制专属套餐" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor colorWithHexString:@"ec7d24"] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(clickToCustomization:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    return view;
}

/**
 *  已预约为空时
 *
 *  @return
 */
- (UIView *)appointedView
{
    if (_appointedView) {
        
        return _appointedView;
    }
    
    _appointedView = [self viewForResultWithTitle:@"您还没有预约任何套餐"];
        
    return _appointedView;
}

/**
 *  已预约过期
 *
 *  @return
 */
-(UIView *)appointedOverView
{
    if (_appointedOverView) {
        return _appointedOverView;
    }
    _appointedOverView = [self viewForResultWithTitle:@"您还没有已过期预约"];
    return _appointedOverView;
}

-(UIView *)appointedExamedView
{
    if (_appointedExamedView) {
        return _appointedExamedView;
    }
    _appointedExamedView = [self viewForResultWithTitle:@"您还没用预约已体检"];
    return _appointedExamedView;
}

- (UIView *)viewForResultWithTitle:(NSString *)title
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, DEVICE_HEIGHT - 64)];
    CGFloat width = FitScreen(96);
    width = iPhone4 ? width * 0.8 : width;
    
    UIImageView *icon = [[UIImageView alloc]initWithFrame:CGRectMake(38, 55, width, width)];
    icon.image = [UIImage imageNamed:@"hema"];
    [view addSubview:icon];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, icon.bottom - 5, DEVICE_WIDTH, 15) title:title font:14 align:NSTextAlignmentCenter textColor:[UIColor colorWithHexString:@"323232"]];
    [view addSubview:label];
    return view;
}

- (RefreshTableView *)tableViewWithIndex:(int)index
{
    return (RefreshTableView *)[self.view viewWithTag:kTagTableView + index];
}
- (UIButton *)buttonWithIndex:(int)index
{
    return (UIButton *)[self.view viewWithTag:kTagButton + index];
}

- (void)prepareView
{
    NSArray *arr = @[@"全部",@"未预约",@"已预约",@"已过期",@"已体检"];
    int sum = (int)arr.count;
    
    self.scroll = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 45, DEVICE_WIDTH, DEVICE_HEIGHT - 45 - 64)];
    _scroll.pagingEnabled = YES;
    _scroll.delegate = self;
    [self.view addSubview:_scroll];
    _scroll.showsHorizontalScrollIndicator = NO;
    _scroll.contentSize = CGSizeMake(DEVICE_WIDTH * sum, _scroll.height);
    
    //scrollView 和 系统手势冲突问题
    [_scroll.panGestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
    
    CGFloat width = DEVICE_WIDTH / sum;
    for (int i = 0; i < sum; i ++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(width * i, 0, width, 45);
        [btn setTitle:arr[i] forState:UIControlStateNormal];
        [btn setTitleColor:DEFAULT_TEXTCOLOR_TITLE forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor colorWithHexString:@"f68326"] forState:UIControlStateSelected];
        btn.titleLabel.font = [UIFont systemFontOfSize:16];
        btn.backgroundColor = [UIColor whiteColor];
        [btn addTarget:self action:@selector(clickToSwap:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = kTagButton + i;
        [self.view addSubview:btn];
        
        RefreshTableView *table = [[RefreshTableView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH * i, 0, DEVICE_WIDTH, _scroll.height) style:UITableViewStylePlain];
        table.refreshDelegate = self;
        table.dataSource = self;
        [_scroll addSubview:table];
        table.separatorStyle = UITableViewCellSeparatorStyleNone;
        table.tag = kTagTableView + i;
    }

}

#pragma mark - 网络请求

- (void)netWorkForListWithTable:(RefreshTableView *)table
{
    int index = (int)table.tag - kTagTableView;
    NSDictionary *params;
    NSString *api;
    
    NSString *authkey = [UserInfo getAuthkey];
    
    //全部
    if (table == [self tableViewWithIndex:0]) {
        
        api = GET_ALL_APPOINTS;
        params = @{@"authcode":authkey,
                   @"level":@"2"};
    }
    //待预约
    else if (table == [self tableViewWithIndex:1]) {
        
        api = GET_NO_APPOINTS;
        params = @{@"authcode":authkey,
                   @"level":@"2"};
    }
    //已预约
    else if (table == [self tableViewWithIndex:2])
    {
        api = GET_APPOINT;
        params = @{@"authcode":authkey,
                   @"expired":@"0",
                   @"level":@"2"};
    }
    //已过期
    else if (table == [self tableViewWithIndex:3])
    {
        api = GET_APPOINT;
        params = @{@"authcode":authkey,
                   @"expired":@"1",
                   @"level":@"2"};
    }
    //已体检
    else if (table == [self tableViewWithIndex:4])
    {
        api = GET_FINISHED_APPOINT;
        params = @{@"authcode":authkey,
                   @"level":@"2"};
    }
    __weak typeof(self)weakSelf = self;
    __weak typeof(table)weakTable = table;
    [[YJYRequstManager shareInstance]requestWithMethod:YJYRequstMethodGet api:api parameters:params constructingBodyBlock:nil completion:^(NSDictionary *result) {
        NSLog(@"success result %@",result);
        [weakSelf parseDataWithResult:result withIndex:index];
        
    } failBlock:^(NSDictionary *result) {
        
        NSLog(@"fail result %@",result);
        [weakTable loadFail];
        
    }];
}

#pragma mark - 数据解析处理

- (void)parseDataWithResult:(NSDictionary *)result
                  withIndex:(int)index
{
    NSDictionary *setmeal_list = result[@"appoint_list"];

    //全部
    if (index == 0)
    {
        
        if (![setmeal_list isKindOfClass:[NSDictionary class]]) {
            
            [[self tableViewWithIndex:index]finishReloadingData];
            return;
        }
        
        _company = [ProductModel modelsFromArray:setmeal_list[@"company"]];
        _personal = [ProductModel modelsFromArray:setmeal_list[@"personal"]];
        _no_expired = [AppointModel modelsFromArray:setmeal_list[@"no_expired"]];
        _expired = [AppointModel modelsFromArray:setmeal_list[@"expired"]];
        _finished = [AppointModel modelsFromArray:setmeal_list[@"finished"]];
        
        if (_company.count == 0 &&
            _personal.count == 0 &&
            _no_expired.count == 0 &&
            _expired.count == 0 &&
            _finished.count == 0) {
            
            //没有待预约
            
            UIView *view = self.allNoDataView;
            [[self tableViewWithIndex:index] addSubview:view];
            
        }else
        {
            [self.allNoDataView removeFromSuperview];
            self.allNoDataView = nil;
        }
        
        _companyName = nil;
        /**
         *  获取公司名字,单个人只可能有一个公司套餐或者代金卷
         */
        ProductModel *p_model = [_company lastObject];
            NSDictionary *company_info = p_model.company_info;
            if ([company_info isKindOfClass:[NSDictionary class]]) {
                _companyName = company_info[@"company_name"];
            }
        
        [[self tableViewWithIndex:index] finishReloadingData];
        
    }
    //待预约
    if (index == 1)
    {
       setmeal_list = result[@"setmeal_list"];

        if (![setmeal_list isKindOfClass:[NSDictionary class]]) {
            
            [[self tableViewWithIndex:index]finishReloadingData];
            return;
        }
        
        _company = [ProductModel modelsFromArray:setmeal_list[@"company"]];
        _personal = [ProductModel modelsFromArray:setmeal_list[@"personal"]];
        
        
        if (_company.count == 0 && _personal.count == 0) {
            
            //没有待预约
            
            UIView *view = self.noAppointView;
            [[self tableViewWithIndex:index] addSubview:view];
            
        }else
        {
            [self.noAppointView removeFromSuperview];
            self.noAppointView = nil;
        }
        
        [[self tableViewWithIndex:index] finishReloadingData];
        
        
    }
    //已预约
    else if (index == 2)
    {
        
        NSArray *temp = [AppointModel modelsFromArray:result[@"appoint_list"]];
        if (temp.count == 0) {
            [[self tableViewWithIndex:index]addSubview:self.appointedView];
        }else
        {
            [self.appointedView removeFromSuperview];
            self.appointedView = nil;
        }
        [[self tableViewWithIndex:index] reloadData:temp pageSize:1000];
        
    }else if (index == 3){
        
        NSArray *temp = [AppointModel modelsFromArray:result[@"appoint_list"]];
        if (temp.count == 0) {
            [[self tableViewWithIndex:index]addSubview:self.appointedOverView];
        }else
        {
            [self.appointedOverView removeFromSuperview];
            self.appointedOverView = nil;
        }
        [[self tableViewWithIndex:index] reloadData:temp pageSize:1000];

    }else if (index == 4){ //已体检部分
        
        NSArray *temp = [AppointModel modelsFromArray:result[@"appoint_list"]];
        if (temp.count == 0) {
            [[self tableViewWithIndex:index]addSubview:self.appointedExamedView];
        }else
        {
            [self.appointedExamedView removeFromSuperview];
            self.appointedExamedView = nil;
        }
        [[self tableViewWithIndex:index] reloadData:temp pageSize:1000];
        
    }
}

#pragma mark - 事件处理

/**
 *  更改button状态
 *
 *  @param index 选中index
 */
- (void)updateButtonStateWithSelectedIndex:(int)index
{
    if (index == _currentPage) {
        
        return;
    }else
    {
        _currentPage = index;
    }
    
    NSLog(@"%s",__FUNCTION__);
    for (int i = 0; i < 5; i ++) {
        [self buttonWithIndex:i].selected = (index == i);
    }
    
    if (![self tableViewWithIndex:index].isHaveLoaded) {
        [[self tableViewWithIndex:index] showRefreshHeader:YES];
    }
}

- (void)clickToSwap:(UIButton *)sender
{
    int index = (int)sender.tag - kTagButton;
    [self updateButtonStateWithSelectedIndex:index];
    [_scroll setContentOffset:CGPointMake(DEVICE_WIDTH * index, 0) animated:NO];
}

- (void)clickToBuy
{
    GStoreHomeViewController *cc= [[GStoreHomeViewController alloc]init];
    cc.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:cc animated:YES];
}
- (void)clickToCustomization:(PropertyButton *)sender
{
    //友盟统计
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic safeSetValue:@"体检预约页" forKey:@"fromPage"];
    [[MiddleTools shareInstance]umengEvent:@"Customization" attributes:dic number:[NSNumber numberWithInt:1]];
    
    ProductModel *aModel = [sender isKindOfClass:[PropertyButton class]] ? sender.aModel : nil;
    
    //先判断是否个性化定制过
    BOOL isOver = [UserInfo getCustomState];
    if (isOver) {
        //已经个性化定制过
        PhysicalTestResultController *physical = [[PhysicalTestResultController alloc]init];
        physical.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:physical animated:YES];
    }else
    {
        PersonalCustomViewController *custom = [[PersonalCustomViewController alloc]init];
        custom.vouchers_id = aModel.coupon_id;
        custom.lastViewController = self;
        [self.navigationController pushViewController:custom animated:YES];
    }
}

/**
 *  使用代金券购买
 */
- (void)clickToBugUseVoucher:(PropertyButton *)sender
{
//    checkuper_info" =                 {
//    age = 28;
//    gender = 1;
//    "id_card" = 371311199999999999;
//    mobile = 18612389982;
//    "order_checkuper_id" = 0;
//    "user_name" = "\U674e\U671d\U4f1f";
    
    ProductModel *aModel = sender.aModel;
    UserInfo *user;
    NSDictionary *checkuper_info = aModel.checkuper_info;
    if ([checkuper_info isKindOfClass:[NSDictionary class]]) {
        
        NSString *idcard = [checkuper_info objectForKey:@"id_card"];
        NSString *name = checkuper_info[@"family_user_name"];
        if (idcard && name) {
            user = [[UserInfo alloc]init];
            user.id_card = idcard;
            user.appellation = @"本人";
            user.family_uid = @"0";
            user.family_user_name = name;
            user.gender = NSStringFromInt([checkuper_info[@"gender"] intValue]);
            user.mobile = checkuper_info[@"mobile"];
        }
    }
    
    GoneClassListViewController *cc = [[GoneClassListViewController alloc]init];
    cc.haveChooseGender = YES;
    cc.className = @"使用代金券";
    cc.vouchers_id = aModel.coupon_id;//代金券
    if (user) {
        cc.user_voucher = user;
    }
    cc.uc_id = aModel.uc_id;
    cc.brandId = aModel.brand_id;
    cc.brandName = aModel.brand_name;
    [self.navigationController pushViewController:cc animated:YES];
}

/**
 *  预约go健康
 *
 *  @param aModel
 */
- (void)appointGoHealthWithProductId:(NSString *)p_id
                         productName:(NSString *)p_name
                             orderId:(NSString *)o_id
{
    NSString *product_id = p_id;
    NSString *product_name = p_name;
    NSString *orderId = o_id;
    
    GoHealthAppointViewController *goHealthAppoint = [[GoHealthAppointViewController alloc]init];
    goHealthAppoint.orderId = orderId;
    goHealthAppoint.productId = product_id;
    goHealthAppoint.productName = product_name;
    [self.navigationController pushViewController:goHealthAppoint animated:YES];
}

/**
 *  查看go健康服务详情
 *
 *  @param aModel
 */
- (void)clickToGoServiceWithModel:(AppointModel *)aModel
{
    NSString *report_html = aModel.report_html;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params safeSetString:report_html forKey:@"report_html"];
    [MiddleTools pushToGoHealthServiceId:aModel.serviceId productId:aModel.product_id orderNum:aModel.order_no fromViewController:self extensionParams:params];
}

#pragma mark - 代理

#pragma - mark UIScrollDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView == _scroll) {
        
        int page = floor((scrollView.contentOffset.x - DEVICE_WIDTH / 2) / DEVICE_WIDTH) + 1;//只要大于半页就算下一页
        [self updateButtonStateWithSelectedIndex:page];
        
    }
    
}

#pragma - mark RefreshDelegate <NSObject>

- (void)loadNewDataForTableView:(RefreshTableView *)tableView
{
    [self netWorkForListWithTable:tableView];
}
- (void)loadMoreDataForTableView:(RefreshTableView *)tableView
{
    [self netWorkForListWithTable:tableView];
}
- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath tableView:(RefreshTableView *)tableView
{
    int index = (int)tableView.tag - kTagTableView;
    
    //全部、未预约
    if (index == 0 || index == 1) {
        
        ProductModel *aModel;
        int index_row = (int)indexPath.row;
        if (indexPath.section == 0) {
            if (index_row < _company.count) {
                aModel = _company[index_row];
            }
        }else if (indexPath.section == 1){
            if (index_row < _personal.count) {
                aModel = _personal[index_row];
            }
        }else if (indexPath.section == 2){
            if (index_row < _no_expired.count) {
                aModel = _no_expired[index_row];
            }
        }else if (indexPath.section == 3){
            if (index_row < _expired.count) {
                aModel = _expired[index_row];
            }
        }else if (indexPath.section == 4){
            if (index_row < _finished.count) {
                aModel = _finished[index_row];
            }
        }
        
        int type = [aModel.type intValue];//1 公司购买套餐 2 公司代金券 3 普通套餐
        int c_type = [aModel.c_type intValue];//c_type=1 1为海马医生预约 2为go健康预约

        if ([aModel isKindOfClass:[ProductModel class]] &&
            type == 2) { //代金券
            return;
        }
        
        //公司、个人套餐 预约操作
        if (indexPath.section == 0 ||
            indexPath.section == 1) {
            
            if (c_type == 2) { //go健康
                
                int no_appointed_num = [aModel.no_appointed_num intValue];
                if (no_appointed_num > 0) {
                    [self appointGoHealthWithProductId:aModel.product_id productName:aModel.product_name orderId:aModel.order_id];
                }else
                {
                    [LTools showMBProgressWithText:@"此套餐已预约完成!" addToView:self.view];
                }
            }else
            {
                ChooseHopitalController *choose = [[ChooseHopitalController alloc]init];
                choose.gender = [aModel.gender intValue];
                //公司
                if (type == 1) {
                    
                    NSString *order_checkuper_id = aModel.checkuper_info[@"order_checkuper_id"];
                    NSString *companyId = aModel.company_info[@"company_id"];
                    
                    [choose companyAppointWithOrderId:aModel.order_id
                                            productId:aModel.product_id
                                            companyId:companyId order_checkuper_id:order_checkuper_id
                                         noAppointNum:[aModel.no_appointed_num intValue]
                                               gender:[aModel.gender intValue]];
                }else
                {
                    [choose appointWithProductId:aModel.product_id
                                         orderId:aModel.order_id
                                    noAppointNum:[aModel.no_appointed_num intValue]];
                    choose.lastViewController = self;//需要选择体检人的时候需要传
                }
                
                [self.navigationController pushViewController:choose animated:YES];
            }
        
        }
        else //跳转详情页
        {
            
            BOOL progress = NO;
            if (indexPath.section == 2){
                if (index_row < _no_expired.count) {
                    aModel = _no_expired[index_row];
                }
            }else if (indexPath.section == 3){
                if (index_row < _expired.count) {
                    aModel = _expired[index_row];
                }
            }else if (indexPath.section == 4){
                if (index_row < _finished.count) {
                    aModel = _finished[index_row];
                }
                progress = YES;
            }
            
            //已预约、已过期、已体检 都为AppointModel,否则不执行
            if (![aModel isKindOfClass:[AppointModel class]]) {
                return;
            }
            AppointModel *appointModel = (AppointModel *)aModel;
            
            int type = [aModel.c_type intValue];//1海马 2go健康
            if (type == 2) { //go健康
                
                [self clickToGoServiceWithModel:appointModel];
                
            }else
            {
                if (progress) {
                    AppointProgressDetailController *detail = [[AppointProgressDetailController alloc]init];
                    detail.appointId = appointModel.appoint_id;
                    [self.navigationController pushViewController:detail animated:YES];
                }else
                {
                    AppointDetailController *detail = [[AppointDetailController alloc]init];
                    detail.appoint_id = appointModel.appoint_id;
                    [self.navigationController pushViewController:detail animated:YES];
                }
            }
        }
        
    }
    else if (index == 4) //已体检
    {
        AppointModel *aModel = tableView.dataArray[indexPath.row];
        int type = [aModel.c_type intValue];
        
        if (type == 2) { //go健康
            
            [self clickToGoServiceWithModel:aModel];
            return;
        }
        
        AppointProgressDetailController *detail = [[AppointProgressDetailController alloc]init];
        detail.appointId = aModel.appoint_id;
        [self.navigationController pushViewController:detail animated:YES];
    }
    else
    {
        AppointModel *aModel = tableView.dataArray[indexPath.row];
        int type = [aModel.c_type intValue];
        if (type == 2) { //go健康
            
            [self clickToGoServiceWithModel:aModel];
            return;
        }
        AppointDetailController *detail = [[AppointDetailController alloc]init];
        detail.appoint_id = aModel.appoint_id;
        [self.navigationController pushViewController:detail animated:YES];
    }
}

- (CGFloat)heightForRowIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    int index = (int)tableView.tag - kTagTableView;
    if (index == 0 || index == 1) {
        
        if (indexPath.section == 2 ||
            indexPath.section == 3 ||
            indexPath.section == 4)
        {
            return 60.f;
        }
        ProductModel *aModel;
        if (indexPath.section == 0) {
            if (indexPath.row < _company.count) {
                aModel = _company[indexPath.row];
            }
            
        }else
        {
            if (indexPath.row < _personal.count) {
                aModel = _personal[indexPath.row];
            }
        }
        
        return [AppointmentCell heightForCellWithType:[aModel.type intValue]];
    }
    
    return 60.f;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section tableView:(UITableView *)tableView
{
    int index = (int)tableView.tag - kTagTableView;
    if (index == 0 || index == 1) {
        
        UIView *head = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 40.f)];
        head.backgroundColor = [UIColor colorWithHexString:@"f7f7f7"];
        
        if (_companyName== nil) {
            _companyName = @"公司购买套餐";
        }
        
        NSString *title = @"套餐";
        if (section == 0) {
            title = _companyName;
        }else if (section == 1){
            title = @"个人购买套餐";
        }else if (section == 2){
            title = @"已预约";
        }else if (section == 3){
            title = @"已过期";
        }else if (section == 4){
            title = @"已体检";
        }
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, DEVICE_WIDTH - 30, 40) title:title font:14 align:NSTextAlignmentLeft textColor:[UIColor colorWithHexString:@"989898"]];
        [head addSubview:label];
        return head;
    }
    return nil;
}
- (CGFloat)heightForHeaderInSection:(NSInteger)section tableView:(UITableView *)tableView
{
    int index = (int)tableView.tag - kTagTableView;
    if (index == 0 || index == 1) {
        
        if (section == 0) {
            
            if (_company.count == 0) {
                return 0.f;
            }
        }
        if (section == 1) {
            if (_personal.count == 0) {
                return 0.f;
            }
        }
        
        if (section == 2) {
            if (_no_expired.count == 0) {
                return 0.f;
            }
        }
        
        if (section == 3) {
            if (_expired.count == 0) {
                return 0.f;
            }
        }
        
        if (section == 4) {
            if (_finished.count == 0) {
                return 0.f;
            }
        }
        return 40.f;
    }
    return 0.f;
}

-(CGFloat)heightForFooterInSection:(NSInteger)section tableView:(RefreshTableView *)tableView
{
    int index = (int)tableView.tag - kTagTableView;
    if (index == 0 || index == 1)
    {
        return 5.f;
    }
    return 0.f;
}
-(UIView *)viewForFooterInSection:(NSInteger)section tableView:(RefreshTableView *)tableView
{
    int index = (int)tableView.tag - kTagTableView;
    if (index == 0 || index) {
        
        UIView *head = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 40.f)];
        head.backgroundColor = DEFAULT_VIEW_BACKGROUNDCOLOR;
        return head;
    }
    return nil;
}

#pragma - mark UITableViewDataSource

#pragma - mark UITableViewDataSource<NSObject>

- (NSInteger)tableView:(RefreshTableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    int index = (int)tableView.tag - kTagTableView;
    if (index == 0 || index == 1) {
        
        if (section == 0) {
            return _company.count;
        }else if (section == 1){
            return _personal.count;
        }else if (section == 2){
            return _no_expired.count;
        }else if (section == 3){
            return _expired.count;
        }else if (section == 4){
            return _finished.count;
        }
    }
    return tableView.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    int index = (int)tableView.tag - kTagTableView;
    
    //未预约 以及 （全部里面第一部分公司套餐、第二部分个人套餐）
    if (index == 1 ||
        (index == 0 && (indexPath.section == 0 || indexPath.section == 1)) ){
        
        AppointmentCell *cell = nil;
        ProductModel *aModel = nil;
        if (indexPath.section == 0) {
            if (indexPath.row < _company.count) {
                aModel = _company[indexPath.row];
            }
        }else
        {
            if (indexPath.row < _personal.count) {
                
                aModel = _personal[indexPath.row];
            }
        }
        if ([aModel.type intValue] == 2) { //代金券
            
            static NSString *identifier = @"AppointmentCell2";
            cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[AppointmentCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier type:2];
            }
            
            cell.buyButton.aModel = aModel;
            [cell.buyButton addTarget:self action:@selector(clickToBugUseVoucher:) forControlEvents:UIControlEventTouchUpInside];
            cell.customButton.aModel = aModel;
            [cell.customButton addTarget:self action:@selector(clickToCustomization:) forControlEvents:UIControlEventTouchUpInside];
            
        }else
        {
            static NSString *identifier = @"AppointmentCell1";
            cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[AppointmentCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier type:1];
            }
        }
        
        cell.contentView.backgroundColor = [UIColor colorWithHexString:@"f7f7f7"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [cell setCellWithModel:aModel];
        
        return cell;
    }
    
    static NSString *identifier = @"identify";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 5, DEVICE_WIDTH, 55)];
        view.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:view];
        
        CGFloat nameWidth = 120;
        CGFloat timeWidth = 70;
        CGFloat centerWidth = DEVICE_WIDTH - nameWidth - timeWidth - 20;
        UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, nameWidth, 55) title:nil font:14 align:NSTextAlignmentLeft textColor:DEFAULT_TEXTCOLOR_TITLE];
        [view addSubview:nameLabel];
        nameLabel.tag = 100;
        
        UILabel *centerLabel = [[UILabel alloc]initWithFrame:CGRectMake(nameLabel.right, 0, centerWidth, 55) title:nil font:14 align:NSTextAlignmentCenter textColor:DEFAULT_TEXTCOLOR_TITLE];
        [view addSubview:centerLabel];
        centerLabel.tag = 101;
        
        UILabel *timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 10 - timeWidth, 0, timeWidth, 55) title:nil font:13 align:NSTextAlignmentRight textColor:DEFAULT_TEXTCOLOR_TITLE];
        [view addSubview:timeLabel];
        timeLabel.tag = 102;
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UILabel *nameLabel = [cell.contentView viewWithTag:100];
    UILabel *centerLabel = [cell.contentView viewWithTag:101];
    UILabel *timeLabel = [cell.contentView viewWithTag:102];
    RefreshTableView *table = (RefreshTableView *)tableView;
    AppointModel *aModel;
    
    if (index == 0) {
        //全部里面 未过期、已过期
        if (indexPath.section == 2) {
            if (indexPath.row < _no_expired.count) {
                aModel = _no_expired[indexPath.row];
            }
            
        }else if (indexPath.section == 3){
            if (indexPath.row < _expired.count) {
                aModel = _expired[indexPath.row];
            }
            
        }else if (indexPath.section == 4){
            if (indexPath.row < _finished.count) {
                aModel = _finished[indexPath.row];
            }
        }
    }else
    {
        if (indexPath.row < table.dataArray.count) {
            aModel = table.dataArray[indexPath.row];
        }
    }
    
    int type = [aModel.c_type intValue];
    
    NSString *leftText = @"";
    NSString *centerText = @"";
//    NSString *rightText = @"";
    NSString *name = aModel.user_name;
    
    if (type == 2)//go健康
    {
        leftText = [NSString stringWithFormat:@"%@",name];
        [nameLabel setAttributedText:[LTools attributedString:leftText keyword:@"" color:DEFAULT_TEXTCOLOR_TITLE_THIRD]];
        centerText = aModel.report_status;
        
    }else
    {
        leftText = [NSString stringWithFormat:@"%@ (%@)",aModel.user_relation,name];
        [nameLabel setAttributedText:[LTools attributedString:leftText keyword:name color:DEFAULT_TEXTCOLOR_TITLE_THIRD]];
        centerText = aModel.center_name;
    }
    
    //未过期(已预约)
    if (index == 2 || (index == 0 && indexPath.section == 2)) {
        
        timeLabel.text = [LTools timeString:aModel.appointment_exam_time withFormat:@"yyyy.MM.dd"];
        
    }
    //已过期
    else if (index == 3 || (index == 0 && indexPath.section == 3)){
        
        NSString *days = NSStringFromInt([aModel.days intValue]);
        
        NSString *text;
        if ([days intValue] == 0) {
            text = @"今日体检";
        }else
        {
            text = [NSString stringWithFormat:@"过期%@天",days];
        }
        [timeLabel setAttributedText:[LTools attributedString:text keyword:days color:[UIColor colorWithHexString:@"f88326"]]];
        
    }
    //已体检
    else if (index == 4 || (index == 0 && indexPath.section == 4)){
        
        NSString *days = aModel.report_status;
        timeLabel.text = days;
        timeLabel.textColor = DEFAULT_TEXTCOLOR_ORANGE;
        
        centerText = aModel.center_name;
    }
    
    centerLabel.text = centerText;
//    if (type == 2){ //go健康
//        text = [NSString stringWithFormat:@"%@",name];
//        [nameLabel setAttributedText:[LTools attributedString:text keyword:@"" color:DEFAULT_TEXTCOLOR_TITLE_THIRD]];
//        
//        centerLabel.text = aModel.report_status;
//    }else
//    {
//        text = [NSString stringWithFormat:@"%@ (%@)",aModel.user_relation,name];
//        [nameLabel setAttributedText:[LTools attributedString:text keyword:name color:DEFAULT_TEXTCOLOR_TITLE_THIRD]];
//        centerLabel.text = aModel.center_name;//分院
//    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(RefreshTableView *)tableView
{
    int index = (int)tableView.tag - kTagTableView;
    if (index == 0) {
        return 5;
    }else if (index == 1){
        return 2;
    }
    return 1;
}

@end
