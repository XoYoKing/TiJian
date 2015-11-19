//
//  PeopleManageController.m
//  TiJian
//
//  Created by lichaowei on 15/11/6.
//  Copyright © 2015年 lcw. All rights reserved.
//

#import "PeopleManageController.h"
#import "AddPeopleViewController.h"
#import "AppointModel.h"

@interface PeopleManageController ()<UITableViewDataSource,RefreshDelegate>
{
    RefreshTableView *_table;
    UIButton *_arrowBtn;
    BOOL _isOpen;//是否展开
    UIView *_view_tableHeader;
    BOOL _isEdit;//是否在编辑
    UILabel *_numLabel;//位数
    int _deleteIndex;//待删除下标
    NSMutableArray *_selectedArray;//选中
    
    //此套餐可以预约个数
    int _noAppointNum;//未预约个数
    //提交预约参数
    NSString *_order_id;//订单id
    NSString *_product_id;//单品id
    NSString *_exam_center_id;//体检机构id
    NSString *_date;// 预约体检日期（如：2015-11-13）
    
    //个人特有
    UIImageView *_selectedIcon;//选择本人的icon
    BOOL _isMyselfSelected;//是否选择自己

}



@end

@implementation PeopleManageController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.myTitleLabel.text = self.isChoose ? @"选择体检人" : @"家人管理";
    [self setMyViewControllerLeftButtonType:MyViewControllerLeftbuttonTypeBack WithRightButtonType:MyViewControllerRightbuttonTypeNull];
    
    self.view.backgroundColor = DEFAULT_VIEW_BACKGROUNDCOLOR;
    [self createNavigationbarTools];
    
    _table = [[RefreshTableView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH,DEVICE_HEIGHT - 64)];
    _table.refreshDelegate = self;
    _table.dataSource = self;
    _table.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_table];
    
    _selectedArray = [NSMutableArray array];
    _isOpen = YES;//默认打开
    _isEdit = NO;//默认非编辑
    _isMyselfSelected = NO;//默认未选择自己
    _table.tableHeaderView = [self tableHeadView];
    
    if (self.isChoose) {
        UIView *view = [self tableFooterView];
        [self.view addSubview:view];
        view.top = DEVICE_HEIGHT - view.height - 64;
        _table.height = DEVICE_HEIGHT - 64 - view.height;
    }
    
    [_table showRefreshHeader:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma - mark 网络请求

- (void)getFamily
{
    NSString *authkey = [LTools cacheForKey:USER_AUTHOD];
    
    authkey = @"WiUHflsiULYOtVfKVeVciwitUbMD9lKjAi8CM186ATEFNVVgBGVWZAUzV2FSNA5+BjI=";

    
//    __weak typeof(self)weakSelf = self;
    __weak typeof(_table)weakTable = _table;
    [[YJYRequstManager shareInstance]requestWithMethod:YJYRequstMethodPost api:GET_FAMILY parameters:@{@"authcode":authkey} constructingBodyBlock:nil completion:^(NSDictionary *result) {
        
        NSArray *temp = [UserInfo modelsFromArray:result[@"family_list"]];
        [weakTable reloadData:temp pageSize:1000 noDataView:nil];
        _numLabel.text = [NSString stringWithFormat:@"%d位",(int)weakTable.dataArray.count];
        
    } failBlock:^(NSDictionary *result) {
        
        [weakTable loadFail];
    }];
}

- (void)deleteFamily:(int)index
{
    UserInfo *aModel = _table.dataArray[index];

    NSString *authey = [LTools cacheForKey:USER_AUTHOD];
    NSDictionary *params = @{@"authcode":authey,
                             @"family_uids":aModel.family_uid};
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self)weakSelf = self;
    __weak typeof(_table)weakTable = _table;
    [[YJYRequstManager shareInstance]requestWithMethod:YJYRequstMethodPost api:DEL_FAMILY parameters:params constructingBodyBlock:nil completion:^(NSDictionary *result) {
        
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
        [weakTable.dataArray removeObjectAtIndex:index];
        [weakTable reloadData];
        
    } failBlock:^(NSDictionary *result) {
        
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
        
    }];
}

/**
 *  预约参数传值
 *
 *  @param orderId
 *  @param productId
 *  @param examCenterId     体检机构id
 *  @param date             预约的时间 格式如：2015-11-13
 *  @param noAppointNum     套餐未预约个数
 */
- (void)setAppointOrderId:(NSString *)orderId
                productId:(NSString *)productId
             examCenterId:(NSString *)examCenterId
                     date:(NSString *)date
             noAppointNum:(int)noAppointNum
{
    //提交预约参数
    _order_id = orderId;//订单id
    _product_id = productId;//单品id
    _exam_center_id = examCenterId;//体检机构id
    _date = date;// 预约体检日期（如：2015-11-13）
    _noAppointNum = noAppointNum;
}

/**
 *  提交预约信息
 */
- (void)networkForMakeAppoint
{
//    3、提交预约信息
//http://123.57.56.167:85/index.php?d=api&c=appoint&m=make_appoint

//    NSString *authey = [LTools cacheForKey:USER_AUTHOD];
//    NSDictionary *params = @{@"authcode":authey,
//                             @"order_id":_order_id,
//                             @"product_id":_product_id,
//                             @"exam_center_id":_exam_center_id,
//                             @"date":_date,
//                             @"company_id":_company_id ? : @"", //公司订单才有的
//                             @"order_checkuper_id":_order_checkuper_id ? : @"", //公司订单才有的
//                             };
    
    //个人
    //家人id 多个用英文逗号隔开（若是个人买单，则要传）
    
    NSString *family_uid = [_selectedArray componentsJoinedByString:@","];
    //myself 是否包括本人 1是 0不是（若是个人买单，则要传）
    NSString *myself = _isMyselfSelected ? @"1" : @"0";
    
    NSString *authkey = [LTools cacheForKey:USER_AUTHOD];

    NSDictionary *params = @{@"authcode":authkey,
                             @"order_id":_order_id,
                             @"product_id":_product_id,
                             @"exam_center_id":_exam_center_id,
                             @"date":_date,
                             @"family_uid":family_uid,
                             @"myself":myself
                             };
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self)weakSelf = self;
//    __weak typeof(_table)weakTable = _table;
    [[YJYRequstManager shareInstance]requestWithMethod:YJYRequstMethodPost api:MAKE_APPOINT parameters:params constructingBodyBlock:nil completion:^(NSDictionary *result) {
        
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
        
        [LTools showMBProgressWithText:@"恭喜您预约成功！" addToView:weakSelf.view];
        [weakSelf performSelector:@selector(appointSuccess) withObject:nil afterDelay:0.5];
        NSLog(@"预约成功 result");
        
    } failBlock:^(NSDictionary *result) {
        
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
        
    }];
}

#pragma - mark 事件处理

- (void)appointSuccess
{
    //预约成功通知
    [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_APPOINT_SUCCESS object:nil];
//    AppointResultController *result = [[AppointResultController alloc]init];
//    [self.navigationController pushViewController:result animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

/**
 *  去预约
 */
- (void)clickToAppoint
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"是否确定预约体检" delegate:self cancelButtonTitle:@"稍等" otherButtonTitles:@"确定", nil];
    [alert show];
}

/**
 *  查看本人信息
 */
- (void)clickToMe
{
    if (self.isChoose) {
        
        if (_isMyselfSelected) {
            
            _selectedIcon.hidden = YES;
            _isMyselfSelected = NO;
            
        }else
        {
            if ([self enableSelectNewPeople]) {
                
                _isMyselfSelected = YES;
                _selectedIcon.hidden = NO;
            }
        }
        
        return;
    }
    
    UserInfo *userInfo = [UserInfo userInfoForCache];
    [self clickToUserInfo:userInfo];
}

/**
 *  跳转至用户详情页
 *
 *  @param aModel
 */
- (void)clickToUserInfo:(UserInfo *)aModel
{
    AddPeopleViewController *add = [[AddPeopleViewController alloc]init];
    add.actionStyle = ACTIONSTYLE_DETTAILT;
    add.userModel = aModel;
    __weak typeof(_table)weakTable = _table;
    
    [add setUpdateParamsBlock:^(NSDictionary *params){
        
        NSLog(@"params %@",params);
        [weakTable showRefreshHeader:YES];
    }];
    
    [self.navigationController pushViewController:add animated:YES];
}

/**
 *  点击打开或者关闭
 *
 *  @param sender
 */
- (void)clickToAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    _arrowBtn.selected = sender.selected;
    
    _isOpen = !sender.selected;
    
    [_table reloadData];
    
}

/**
 *  添加新人
 */
- (void)clickToAdd:(UIButton *)sender
{
    AddPeopleViewController *add = [[AddPeopleViewController alloc]init];
    __weak typeof(_table)weakTable = _table;
    
    [add setUpdateParamsBlock:^(NSDictionary *params){
        
        NSLog(@"params %@",params);
        [weakTable showRefreshHeader:YES];
    }];
    
    [self.navigationController pushViewController:add animated:YES];
}

/**
 *  编辑状态、可删除人
 *
 *  @param sender
 */
- (void)clickToEdit:(UIButton *)sender
{
    _isEdit = !_isEdit;
    [_table reloadData];
}

/**
 *  判断是否可以选择更多人
 *
 *  @return 是否
 */
- (BOOL)enableSelectNewPeople
{
    int selectNum = (int)_selectedArray.count;//可选
    if (_isMyselfSelected) { //是否选择本人
        
        selectNum += 1;
    }
    
    //已选择小于剩余总数
    if (selectNum < _noAppointNum) {
        
        return YES;
    }
    
    NSString *text = [NSString stringWithFormat:@"共可约%d人,已选%d人",_noAppointNum,selectNum];
    
    NSLog(@"NONO");
    [LTools alertText:text viewController:self];
    
    return NO;
}

#pragma - mark 创建视图

- (void)createNavigationbarTools
{
    
    if (self.isChoose) {
        //添加
        UIButton *heartButton = [[UIButton alloc]initWithframe:CGRectMake(0, 0, 44, 44) buttonType:UIButtonTypeCustom nornalImage:[UIImage imageNamed:@"personal_jiaren_tianjia"] selectedImage:nil target:self action:@selector(clickToAdd:)];
        [heartButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        UIBarButtonItem *comment_item=[[UIBarButtonItem alloc]initWithCustomView:heartButton];
        self.navigationItem.rightBarButtonItem = comment_item;
        return;
        
    }
    
    UIButton *rightView=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 88, 44)];
    rightView.backgroundColor=[UIColor clearColor];
    
    //添加
    UIButton *heartButton = [[UIButton alloc]initWithframe:CGRectMake(0, 0, 44, 44) buttonType:UIButtonTypeCustom nornalImage:[UIImage imageNamed:@"personal_jiaren_tianjia"] selectedImage:nil target:self action:@selector(clickToAdd:)];
    [heartButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    
    
    //删除
    UIButton *collectButton = [[UIButton alloc]initWithframe:CGRectMake(44, 0, 44, 44) buttonType:UIButtonTypeCustom nornalImage:[UIImage imageNamed:@"personal_jiaren_shanchu"] selectedImage:nil target:self action:@selector(clickToEdit:)];
    [collectButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    
    
    [rightView addSubview:heartButton];
    [rightView addSubview:collectButton];
    
    UIBarButtonItem *comment_item=[[UIBarButtonItem alloc]initWithCustomView:rightView];
    
    self.navigationItem.rightBarButtonItem = comment_item;
}

- (UIView *)tableFooterView
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 30 + 45)];
    view.backgroundColor = [UIColor clearColor];
    
    //确认预约按钮
    UIButton *sureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [sureBtn setTitle:@"确认预约" forState:UIControlStateNormal];
    sureBtn.backgroundColor = DEFAULT_TEXTCOLOR;
    sureBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [sureBtn addCornerRadius:2.f];
    [sureBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [view addSubview:sureBtn];
    sureBtn.frame = CGRectMake(27, 15, DEVICE_WIDTH - 27 * 2, 45);
    [sureBtn addTarget:self action:@selector(clickToAppoint) forControlEvents:UIControlEventTouchUpInside];
    
    return view;
}

- (UIView *)tableHeadView
{
    UIView *headView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 67)];
    
    UIView *bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 6, DEVICE_WIDTH, 56)];
    bgView.backgroundColor = [UIColor whiteColor];
    [headView addSubview:bgView];
    //本人
    UILabel *titleLable = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 35, bgView.height) title:@"本人" font:16 align:NSTextAlignmentLeft textColor:[UIColor blackColor]];
    [bgView addSubview:titleLable];
    
    NSString *name = [UserInfo userInfoForCache].user_name;
    UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(titleLable.right + 60, 0, 200, bgView.height) title:name font:15 align:NSTextAlignmentLeft textColor:[UIColor colorWithHexString:@"313131"]];
    [bgView addSubview:nameLabel];
    
    //选择体检人
    if (self.isChoose) {
        
        //图标 对号
        UIImageView *icon = [[UIImageView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 15 - 14.5, 0, 14.5, 50)];
        icon.image = [UIImage imageNamed:@"duihao"];
        icon.contentMode = UIViewContentModeCenter;
        [bgView addSubview:icon];
        icon.hidden = YES;
        
        _selectedIcon = icon;
        
    }else
    {
        UIImageView *editImage = [[UIImageView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 15 - 7, (67-14)/2.f, 7, 14)];
        editImage.image = [UIImage imageNamed:@"personal_jiantou_r"];
        [bgView addSubview:editImage];
    }
    
    [bgView addTaget:self action:@selector(clickToMe) tag:0];
    
    return headView;
}

#pragma - mark UIAlertViewDelegate <NSObject>

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1){
        
        if(self.isChoose)
        {
            [self networkForMakeAppoint];//提交预约
            return;
        }
        
        [self deleteFamily:_deleteIndex];
    }
}


#pragma - mark RefreshDelegate

- (void)loadNewDataForTableView:(UITableView *)tableView
{
    [self getFamily];
}
- (void)loadMoreDataForTableView:(UITableView *)tableView
{
    
}
//新加
- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    UserInfo *aModel = _table.dataArray[indexPath.row];

    if (_isEdit) {//在编辑
        NSLog(@"删除");
        _deleteIndex = (int)indexPath.row;
        NSString *text = [NSString stringWithFormat:@"是否删除\"%@\"\"%@\"?",aModel.appellation,aModel.family_user_name];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:text delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
    }else
    {
        NSString *uid = aModel.family_uid;
        //选择人
        if (self.isChoose) {
            
            if ([_selectedArray containsObject:uid]) {
                [_selectedArray removeObject:uid];

            }else
            {
                
                if ([self enableSelectNewPeople]) {
                    
                    [_selectedArray addObject:uid];

                }else
                {
                    return;
                }
            }
            
            [tableView reloadData];

            
            return;
        }
        
        [self clickToUserInfo:aModel];
    }
}
- (CGFloat)heightForRowIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    return 56.f;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section tableView:(UITableView *)tableView
{
    if (!_view_tableHeader) {
        _view_tableHeader = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 56)];
        _view_tableHeader.backgroundColor = [UIColor whiteColor];
        //本人
        UILabel *titleLable = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 35, _view_tableHeader.height) title:@"家人" font:16 align:NSTextAlignmentLeft textColor:[UIColor blackColor]];
        [_view_tableHeader addSubview:titleLable];
        
        NSString *name = [NSString stringWithFormat:@"%d位",(int)_table.dataArray.count];
        UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(titleLable.right + 60, 0, 200, _view_tableHeader.height) title:name font:15 align:NSTextAlignmentLeft textColor:[UIColor colorWithHexString:@"313131"]];
        [_view_tableHeader addSubview:nameLabel];
        _numLabel = nameLabel;
        
        _arrowBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _arrowBtn.frame = CGRectMake(DEVICE_WIDTH - 15 - 13, (67-7)/2.f, 13, 7);
        [_view_tableHeader addSubview:_arrowBtn];
        [_arrowBtn setImage:[UIImage imageNamed:@"personal_jiaren_jiantou_b"] forState:UIControlStateNormal];
        [_arrowBtn setImage:[UIImage imageNamed:@"personal_jiaren_jiantou_t"] forState:UIControlStateSelected];
        [_view_tableHeader addTaget:self action:@selector(clickToAction:) tag:0];
        
        //line
        UIImageView *line = [[UIImageView alloc]initWithFrame:CGRectMake(0, _view_tableHeader.height - 0.5, DEVICE_WIDTH, 0.5)];
        line.backgroundColor = DEFAULT_LINECOLOR;
        [_view_tableHeader addSubview:line];
    }
    
    return _view_tableHeader;
}
- (CGFloat)heightForHeaderInSection:(NSInteger)section tableView:(UITableView *)tableView
{
    return 56.f;
}

////meng新加
//-(CGFloat)heightForFooterInSection:(NSInteger)section tableView:(UITableView *)tableView
//{
//    return 0.01f;
//}
//
//-(UIView *)viewForFooterInSection:(NSInteger)section tableView:(UITableView *)tableView
//{
//    return [UIView new];
//}



#pragma - mark UITableViewDataSource<NSObject>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    if (!_isOpen) {
        return 0.f;
    }
    return _table.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString *identifier = @"GProductCellTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        
        UIView *bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 56)];
        bgView.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:bgView];
        
        if (self.isChoose) {
            //图标 对号
            UIImageView *icon = [[UIImageView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 15 - 14.5, 0, 14.5, 50)];
            icon.image = [UIImage imageNamed:@"duihao"];
            icon.contentMode = UIViewContentModeCenter;
            [cell.contentView addSubview:icon];
            icon.tag = 103;
        }else
        {
            UIImageView *arrow = [[UIImageView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 15 - 7, (56-7-15)/2.f, 7, 14)];
            arrow.image = [UIImage imageNamed:@"personal_jiantou_r"];
            [bgView addSubview:arrow];
        }
        
        //本人
        UILabel *titleLable = [[UILabel alloc]initWithFrame:CGRectMake(15 * 2, 0, 100, bgView.height) title:nil font:16 align:NSTextAlignmentLeft textColor:[UIColor blackColor]];
        [bgView addSubview:titleLable];
        titleLable.tag = 100;
        
        NSString *name = nil;
        UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(titleLable.right, 0, DEVICE_WIDTH - titleLable.right - 10, bgView.height) title:name font:15 align:NSTextAlignmentLeft textColor:[UIColor colorWithHexString:@"313131"]];
        [bgView addSubview:nameLabel];
        nameLabel.tag = 101;
        
        //line
        UIImageView *line = [[UIImageView alloc]initWithFrame:CGRectMake(0, 56 - 0.5, DEVICE_WIDTH, 0.5)];
        line.backgroundColor = DEFAULT_LINECOLOR;
        [cell.contentView addSubview:line];
        
        //删除按钮
        UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        deleteBtn.backgroundColor = [UIColor colorWithHexString:@"ed1f1f"];
        deleteBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        deleteBtn.frame = CGRectMake(DEVICE_WIDTH, 0, 70, 56);
        [bgView addSubview:deleteBtn];
        deleteBtn.tag = 102;
        deleteBtn.userInteractionEnabled = NO;

    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    
    UILabel *title = [cell.contentView viewWithTag:100];
    UILabel *nameLabel = [cell.contentView viewWithTag:101];
    UIButton *deleteBtn = (UIButton *)[cell.contentView viewWithTag:102];
    
    UIImageView *icon = [cell.contentView viewWithTag:103];
    
    [UIView animateWithDuration:0.5 animations:^{
        deleteBtn.left = _isEdit ? DEVICE_WIDTH - 70 : DEVICE_WIDTH;

    }];
    
    UserInfo *aModel = _table.dataArray[indexPath.row];
    title.text = aModel.appellation;
    nameLabel.text = aModel.family_user_name;
    
    NSString *uid = aModel.family_uid;
    if ([_selectedArray containsObject:uid]) {
        icon.hidden = NO;
    }else
    {
        icon.hidden = YES;
    }
    
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


@end
