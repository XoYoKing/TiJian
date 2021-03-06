//
//  MyCouponViewController.m
//  TiJian
//
//  Created by gaomeng on 15/11/29.
//  Copyright © 2015年 lcw. All rights reserved.
//

#import "MyCouponViewController.h"
#import "MyCouponTableViewCell.h"
#import "ConfirmOrderViewController.h"
#import "ProductModel.h"
@interface MyCouponViewController ()<UIScrollViewDelegate,UITableViewDelegate,UITableViewDataSource>
{
    int _buttonNum;//button个数
    UIScrollView *_scroll;
    UITableView *_tab0;
    UITableView *_tab1;
    
    YJYRequstManager* _requst;//网络请求单例
    
    NSMutableArray *_tab0Array;//可用的数据源
    NSMutableArray *_tab1Array;//不可用的数据源
    
    
    UIButton *_use_btn;
    
    NSString *_theUrl;//使用说明url
    NSString *_targetTitle;//web页面的标题
    
    
}
@end

@implementation MyCouponViewController

//-(void)viewWillDisappear:(BOOL)animated{
//    [super viewWillDisappear:animated];
//    //代理置空，否则会闪退
////    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
////        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
////    }
//    
//    //scrollView 和 系统手势冲突问题
////    [_scroll.panGestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
//    
//}


- (void)dealloc
{
    NSLog(@"%s",__FUNCTION__);
}




- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
    if (self.type == GCouponType_youhuiquan) {//优惠券
        [self setMyViewControllerLeftButtonType:0 WithRightButtonType:MyViewControllerRightbuttonTypeText];
        self.myTitle = @"我的优惠券";
        _theUrl = URL_YOUHUIQUANSHUOMING;
        _targetTitle = @"优惠券使用规则";
    }else if (self.type == GCouponType_daijinquan){//代金券
        [self setMyViewControllerLeftButtonType:0 WithRightButtonType:MyViewControllerRightbuttonTypeText];
        self.myTitle = @"我的代金券";
        _theUrl = URL_DAIJINQUANSHUOMING;
        _targetTitle = @"代金券使用规则";
    }else if (self.type == GCouponType_use_youhuiquan){//使用优惠券
        [self setMyViewControllerLeftButtonType:0 WithRightButtonType:MyViewControllerRightbuttonTypeText];
        self.myTitle = @"使用优惠券";
        _theUrl = URL_YOUHUIQUANSHUOMING;
        _targetTitle = @"优惠券使用规则";
    }else if (self.type == GCouponType_use_daijinquan){//使用代金券
        [self setMyViewControllerLeftButtonType:0 WithRightButtonType:MyViewControllerRightbuttonTypeText];
        self.myTitle = @"使用代金券";
        _theUrl = URL_DAIJINQUANSHUOMING;
        _targetTitle = @"代金券使用规则";
    }
    
    
    self.rightString = @"使用规则";
    
    
    
    self.view.backgroundColor = RGBCOLOR(245, 245, 245);
    
    [self prepareNetData];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(ResultView *)resultViewWithType:(PageResultType)type
{
    NSString *content;
//    NSString *btnTitle;
//    SEL selector = NULL;
    if (type == PageResultType_requestFail) {
        
        content = @"获取数据异常,点击重新加载";
//        btnTitle = @"重新加载";
//        selector = @selector(clickToResfresh);
        
    }else if (type == PageResultType_nodata){
        
        if (self.type == GCouponType_daijinquan || self.type == GCouponType_disUse_daijinquan || self.type == GCouponType_use_daijinquan) {
            content = @"您还没有可用的代金券";
        }else if (self.type == GCouponType_disUse_youhuiquan || self.type == GCouponType_use_youhuiquan || self.type == GCouponType_youhuiquan){
            content = @"您还没有可用的优惠券";
        }
        
//        btnTitle = @"立即上传";
//        selector = @selector(clickToUploadReport);
        
    }
    
    ResultView *result = [[ResultView alloc]initWithImage:[UIImage imageNamed:@"hema_heart"]
                                                    title:@"温馨提示"
                                                  content:content];
    
    
    
    return result;
}








#pragma mark - 重载方法
-(void)rightButtonTap:(UIButton *)sender{
    
    NSString *urlstring = [NSString stringWithFormat:@"%@%@",SERVER_URL,_theUrl];
    [MiddleTools pushToWebFromViewController:self weburl:urlstring title:_targetTitle moreInfo:NO hiddenBottom:YES];
}


#pragma mark - 视图创建
//创建上方选择btn 和 下方展示tab
-(void)creatUpBtnAndDownScrollView{
    
    
    int abelCount = 0;
    int disAbelCount = 0;
    
    for (NSArray * arr in _tab0Array) {
        abelCount +=arr.count;
    }
    
    for (NSArray *arr in _tab1Array) {
        disAbelCount +=  arr.count;
    }
    
    
    NSString *ableNum = [NSString stringWithFormat:@"可用优惠券(%d)",abelCount];
    NSString *noAbleNum = [NSString stringWithFormat:@"不可用优惠券(%d)",disAbelCount];
    
    if (self.type == GCouponType_daijinquan || self.type == GCouponType_use_daijinquan) {
        ableNum = [NSString stringWithFormat:@"可用代金券(%d)",abelCount];
        noAbleNum = [NSString stringWithFormat:@"不可用代金券(%d)",disAbelCount];
    }
    
    
    NSArray *titles = @[ableNum,noAbleNum];
    int count = (int)titles.count;
    CGFloat width = DEVICE_WIDTH / count;
    _buttonNum = count;
    
    
    UIView *upline = [[UIView alloc]initWithFrame:CGRectMake(0, 35, DEVICE_WIDTH, 5)];
    upline.backgroundColor = RGBCOLOR(235, 235, 235);
    [self.view addSubview:upline];
    
    _scroll = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 40, DEVICE_WIDTH, DEVICE_HEIGHT - 64 - 40)];
    _scroll.delegate = self;
    _scroll.contentSize = CGSizeMake(DEVICE_WIDTH * count, _scroll.height);
    _scroll.showsHorizontalScrollIndicator = NO;
    _scroll.pagingEnabled = YES;
    [self.view addSubview:_scroll];
    
    //scrollView 和 系统手势冲突问题
    [_scroll.panGestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
    
    for (int i = 0; i < count; i ++) {
        //横滑上方的按钮
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [self.view addSubview:btn];
        btn.tag = 100 + i;
        btn.frame = CGRectMake(width * i, 0, width, 40);
        [btn setTitleColor:[UIColor colorWithHexString:@"646464"] forState:UIControlStateNormal];
        [btn setTitleColor:RGBCOLOR(235, 110, 21) forState:UIControlStateSelected];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [btn addTarget:self action:@selector(clickToSelect:) forControlEvents:UIControlEventTouchUpInside];
        btn.selected = YES;
        
        UITableView *_table = [[UITableView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH * i, 0, DEVICE_WIDTH,_scroll.height) style:UITableViewStyleGrouped];
        _table.backgroundColor = RGBCOLOR(245, 245, 245);
        _table.delegate = self;
        _table.dataSource = self;
        [_scroll addSubview:_table];
        _table.tag = 200 + i;
        
        
        
        
        
        if (_table.tag == 200) {
            if (_tab0Array.count == 0) {
                
                UIView *footView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 200)];
                
                UIView *imv_view = [[UIView alloc]initWithFrame:CGRectMake(0, 25, DEVICE_WIDTH, 175)];
                [footView addSubview:imv_view];
                
                UIView *immm = [self resultViewWithType:PageResultType_nodata];
                [imv_view addSubview:immm];
                _table.tableFooterView = footView;
            }
            _tab0 = _table;
        }else if (_table.tag == 201){
            if (_tab1Array.count == 0) {
                UIView *footView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 200)];
                
                UIView *imv_view = [[UIView alloc]initWithFrame:CGRectMake(0, 25, DEVICE_WIDTH, 175)];
                [footView addSubview:imv_view];
                
                UIView *immm = [self resultViewWithType:PageResultType_nodata];
                [imv_view addSubview:immm];
                _table.tableFooterView = footView;
            }
            _tab1 = _table;
        }
        
    }
    
    
    //默认选中第一个
    [self controlSelectedButtonTag:100];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    
    
    
}


#pragma mark - 逻辑处理 cell的回调

-(void)cellSelectBtnClickedWithIndex:(NSIndexPath *)theIndex select:(BOOL)theState{
    if (self.type == GCouponType_use_youhuiquan) {//使用优惠券
        NSArray *arr = _tab0Array[theIndex.section];
        CouponModel *model = arr[theIndex.row];
        
        
        if ([model.brand_id intValue] == 0) {//通用
            for (CouponModel *oneModel in arr) {
                oneModel.isUsed = NO;
            }
            model.isUsed = theState;
            
            
            //非通用都置NO
            for (NSArray *dd in _tab0Array) {
                for (model in dd) {
                    if ([model.brand_id intValue] != 0) {
                        model.isUsed = NO;
                    }
                }
            }
            
            
            
            
        }else{//非通用
            for (CouponModel *oneModel in arr) {
                if (oneModel.brand_id == model.brand_id) {
                    oneModel.isUsed = NO;
                }
            }
            model.isUsed = theState;
            
            //通用里的isUsed都置NO
            for (NSArray *dd in _tab0Array) {
                for (model in dd) {
                    if ([model.brand_id intValue] == 0) {
                        model.isUsed = NO;
                    }
                }
            }
            
            
        }
        
        
        
        
        
        
        
        
        //重置userchoose数组 用于解决cellforrow里 对勾点不掉的bug
        NSMutableArray *arr1 = [NSMutableArray arrayWithCapacity:1];
        for (NSArray *ar in _tab0Array) {
            for (CouponModel *model in ar) {
                if (model.isUsed) {
                    [arr1 addObject:model];
                }
            }
        }
        
        self.userChooseYouhuiquanArray = arr1;
        
        
        
        
        
        
//        if (self.userChooseDaijinquanArray.count>0 || self.userChooseYouhuiquanArray.count>0) {
//            _use_btn.backgroundColor = RGBCOLOR(237, 108, 22);
//        }else{
//            _use_btn.backgroundColor = RGBCOLOR(235, 236, 238);
//        }
        
        
        _use_btn.backgroundColor = RGBCOLOR(237, 108, 22);
        
        
        [_tab0 reloadData];
        
        
    }else if (self.type == GCouponType_use_daijinquan){//使用代金券
        NSArray *arr = _tab0Array[theIndex.section];
        CouponModel *model = arr[theIndex.row];
        
        if ([model.brand_id intValue] == 0) {//通用
            for (CouponModel *oneModel in arr) {
                oneModel.isUsed = NO;
            }
            model.isUsed = theState;
            
            
            //非通用都置NO
            for (NSArray *dd in _tab0Array) {
                for (model in dd) {
                    if ([model.brand_id intValue] != 0) {
                        model.isUsed = NO;
                    }
                }
            }
            
            
            
        }else{//非通用
            for (CouponModel *oneModel in arr) {
                if ([oneModel.brand_id integerValue] == [model.brand_id integerValue]) {
                    oneModel.isUsed = NO;
                }
            }
            model.isUsed = theState;
            
            
            //通用都置NO
            for (NSArray *dd in _tab0Array) {
                for (model in dd) {
                    if ([model.brand_id intValue] == 0) {
                        model.isUsed = NO;
                    }
                }
            }
            
            
            
        }
        
        
        
        //重置userchoose数组 用于解决cellforrow里 对勾点不掉的bug
        NSMutableArray *arr1 = [NSMutableArray arrayWithCapacity:1];
        for (NSArray *ar in _tab0Array) {
            for (CouponModel *model in ar) {
                if (model.isUsed) {
                    [arr1 addObject:model];
                }
            }
        }
        self.userChooseDaijinquanArray = arr1;
        
        
        _use_btn.backgroundColor = RGBCOLOR(237, 108, 22);
        
        [_tab0 reloadData];
        
    }
    
    
    
}





#pragma mark - 网络请求
-(void)prepareNetData{
    
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    NSString *url;
    
    if (self.type == GCouponType_youhuiquan)//查看优惠券
    {
        url = USER_MYYOUHUIQUANLIST;
        [dic safeSetValue:[UserInfo getAuthkey] forKey:@"authcode"];
        
    }else if (self.type == GCouponType_use_youhuiquan){//使用优惠券
        url = ORDER_GETYOUHUIQUANLIST;
        [dic safeSetValue:[UserInfo getAuthkey] forKey:@"authcode"];
        [dic safeSetValue:self.coupon forKey:@"coupon"];
        
    }else if (self.type == GCouponType_daijinquan){//查看代金券
        url = USER_MYDAIJINQUANLIST;
        [dic safeSetValue:[UserInfo getAuthkey] forKey:@"authcode"];

    }else if (self.type == GCouponType_use_daijinquan){//使用代金券
        url = ORDER_GETDAIJIQUANLIST;
        
        int p_nums = 0;
        for (ProductModel *model in self.delegate.dataArray) {
            if (model.is_append.intValue != 1) {
                p_nums += [model.product_num intValue];
            }
            
        }
        
        [dic safeSetValue:[UserInfo getAuthkey] forKey:@"authcode"];
        [dic safeSetValue:self.brand_ids forKey:@"brand_ids"];
        [dic safeSetValue:[NSString stringWithFormat:@"%d",p_nums] forKey:@"product_num"];
        
       
        
        if (p_nums == 1) {
            for (ProductModel *model in self.delegate.dataArray) {

                [dic safeSetValue:[UserInfo getAuthkey] forKey:@"authcode"];
                [dic safeSetValue:self.brand_ids forKey:@"brand_ids"];
                [dic safeSetValue:[NSString stringWithFormat:@"%d",p_nums] forKey:@"product_num"];
                [dic safeSetValue:model.product_id forKey:@"product_id"];
            }
            
        }
    }
    
    
    if (!_requst) {
        _requst = [YJYRequstManager shareInstance];
    }
    [_requst requestWithMethod:YJYRequstMethodGet api:url parameters:dic constructingBodyBlock:nil completion:^(NSDictionary *result) {
        
        NSDictionary *listDic = [result dictionaryValueForKey:@"list"];
        __weak typeof (self)bself = self;
        [bself requestFinishWithDic:listDic];
        
        
    } failBlock:^(NSDictionary *result) {
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
    }];
    
}


-(void)requestFinishWithDic:(NSDictionary *)listDic{
    //可用
    NSDictionary *enableDic = [listDic dictionaryValueForKey:@"enable"];
    //不可用
    NSDictionary *disableDic = [listDic dictionaryValueForKey:@"disable"];
    
    //可用
    _tab0Array = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *tab0_tongyongArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *tab0_feitongyongArray = [NSMutableArray arrayWithCapacity:1];
    
    //不可用
    _tab1Array = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *tab1_tongyongArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *tab1_feitongyongArray = [NSMutableArray arrayWithCapacity:1];
    
    //可用里的通用
    NSArray *enableDic_common_Array = [enableDic arrayValueForKey:@"common"];
    //可用里的非通用
    NSArray *enableDic_uncommon_Array = [enableDic arrayValueForKey:@"uncommon"];
    
    //不可用里的通用
    NSArray *disableDic_common_Array = [disableDic arrayValueForKey:@"common"];
    //不可用里的非通用
    NSArray *disableDic_uncommon_Array = [disableDic arrayValueForKey:@"uncommon"];
    
    //dic转model
    //可用-通用
    for (NSDictionary *dic in enableDic_common_Array) {
        CouponModel *model = [[CouponModel alloc]initWithDictionary:dic];
        if (model) {
            [tab0_tongyongArray addObject:model];
        }
    }
    
    //可用-非通用
    for (NSDictionary *dic in enableDic_uncommon_Array) {
        CouponModel *model = [[CouponModel alloc]initWithDictionary:dic];
        if (model) {
            [tab0_feitongyongArray addObject:model];
        }
    }
    
    //不可用-通用
    for (NSDictionary *dic in disableDic_common_Array) {
        CouponModel *model = [[CouponModel alloc]initWithDictionary:dic];
        if (model) {
            [tab1_tongyongArray addObject:model];
        }
    }
    
    //不可用-非通用
    for (NSDictionary *dic in disableDic_uncommon_Array) {
        CouponModel *model = [[CouponModel alloc]initWithDictionary:dic];
        if (model) {
            [tab1_feitongyongArray addObject:model];
        }
    }
    
    
    
    if (tab0_tongyongArray.count>0) {
        [_tab0Array addObject:tab0_tongyongArray];
    }
    
    if (tab0_feitongyongArray.count>0) {
        [_tab0Array addObject:tab0_feitongyongArray];
    }
    
    if (tab1_tongyongArray.count>0) {
        [_tab1Array addObject:tab1_tongyongArray];
    }
    
    if (tab1_feitongyongArray.count>0) {
        [_tab1Array addObject:tab1_feitongyongArray];
    }
    
    
    [_tab0 reloadData];
    [_tab1 reloadData];
    
    
    
    [self creatUpBtnAndDownScrollView];
    
    
    if (_tab0Array.count>0) {
        
        if (self.type == GCouponType_use_daijinquan || self.type == GCouponType_use_youhuiquan) {
            UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 55)];
            
            _use_btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [_use_btn setFrame:CGRectMake(33, 10, DEVICE_WIDTH - 65, 40)];
            _use_btn.layer.cornerRadius = 4;
            
            
            
            
            
            _use_btn.backgroundColor = RGBCOLOR(237, 108, 22);
            
            _use_btn.titleLabel.font = [UIFont systemFontOfSize:15];
            [_use_btn setTitle:@"确 定" forState:UIControlStateNormal];
            [_use_btn addTarget:self action:@selector(useBtnClicked) forControlEvents:UIControlEventTouchUpInside];
            [view addSubview:_use_btn];
            
            _tab0.tableFooterView = view;
        }
    }
    
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}




//确定按钮
-(void)useBtnClicked
{
    if (self.type == GCouponType_use_youhuiquan) {//使用优惠券
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
        for (NSArray *ar in _tab0Array) {
            for (CouponModel *model in ar) {
                if (model && model.isUsed) {
                    if ([model.type intValue] == 4) {
                        model.type = @"1";
                        model.full_money = @"0";
                        model.minus_money = model.newer_money;
                    }
                    [arr addObject:model];
                }
            }
        }
        self.delegate.userSelectYouhuiquanArray = arr;
    }else if (self.type == GCouponType_use_daijinquan){//使用代金券
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
        for (NSArray *ar in _tab0Array) {
            for (CouponModel *model in ar) {
                if (model && model.isUsed) {
                    [arr addObject:model];
                }
            }
        }
        self.delegate.userSelectDaijinquanArray = arr;
    }
    
    [self.delegate jisuanPrice];
    [self.navigationController popViewControllerAnimated:YES];
}





#pragma mark - UITableViewDelegate && UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    NSInteger num = 0;
    if (tableView.tag == 200) {//可用
        num = _tab0Array.count;
    }else if (tableView.tag == 201){//不可用
        num = _tab1Array.count;
    }
    return num;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger num = 0;
    if (tableView.tag == 200) {//可用
        NSArray *arr = _tab0Array[section];
        num = arr.count;
    }else if (tableView.tag == 201){
        NSArray *arr = _tab1Array[section];
        num = arr.count;
    }
    
    return num;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    CGFloat height = 0.01;
    height = 45;
    return height;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    CGFloat height = 0.01;
    return height;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat height = 70;
    return height;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc]initWithFrame:CGRectZero];
    
    [view setFrame:CGRectMake(0, 0, DEVICE_WIDTH, 45)];
    view.backgroundColor = RGBCOLOR(244, 245, 246);
    
    CouponModel *model;
    if (tableView.tag == 200) {//可用
        NSArray *arr = _tab0Array[section];
        model = arr[0];
    }else if (tableView.tag == 201){//不可用
        NSArray *arr = _tab1Array[section];
        model = arr[0];
    }
    
    
    UIImageView *logoImv = [[UIImageView alloc]initWithFrame:CGRectMake(15, 15, 15, 15)];
    [view addSubview:logoImv];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(logoImv.frame)+10, 0, 100, 45)];
    label.font = [UIFont systemFontOfSize:13];
    label.textColor = RGBCOLOR(134, 135, 136);
    [view addSubview:label];
    
    if ([model.brand_id intValue] != 0) {//非通用
        if (self.type == GCouponType_youhuiquan || self.type == GCouponType_use_youhuiquan) {
            label.text = @"品牌优惠券";
            [logoImv setImage:[UIImage imageNamed:@"coupon_feitongyong.png"]];
        }else if (self.type == GCouponType_daijinquan || self.type == GCouponType_use_daijinquan){
            label.text = @"品牌代金券";
            [logoImv setImage:[UIImage imageNamed:@"coupon_feitongyong.png"]];
        }
        
    }else{//通用
        if (self.type == GCouponType_youhuiquan || self.type == GCouponType_use_youhuiquan) {
            label.text = @"通用优惠券";
            [logoImv setImage:[UIImage imageNamed:@"coupon_tongyong.png"]];
        }else if (self.type == GCouponType_daijinquan || self.type == GCouponType_use_daijinquan){
            label.text = @"通用代金券";
            [logoImv setImage:[UIImage imageNamed:@"coupon_tongyong.png"]];
        }
        
    }
    
    
    return view;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *view = [[UIView alloc]initWithFrame:CGRectZero];
    return view;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    int tableViewTag = (int)tableView.tag;
    if (tableViewTag == 200) {//可用
        static NSString *identify = @"counponCell_canuse";
        MyCouponTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
        if (!cell) {
            
            cell = [[MyCouponTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identify index:indexPath type:self.type];
            cell.delegate = self;
        }
        
        NSArray *arr = _tab0Array[indexPath.section];
        CouponModel *model = arr[indexPath.row];
        
        [cell loadDataWithModel:model type:self.type];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }else if (tableViewTag == 201){//不可用
        static NSString *identify = @"counponCell_disabelUse";
        MyCouponTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
        if (!cell) {
            GCouponType aa;
            if (self.type == GCouponType_use_daijinquan || self.type == GCouponType_daijinquan) {
                aa = GCouponType_disUse_daijinquan;
            }else if (self.type == GCouponType_use_youhuiquan || self.type == GCouponType_youhuiquan){
                aa = GCouponType_disUse_youhuiquan;
            }
            cell = [[MyCouponTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identify index:indexPath type:aa];
            cell.delegate = self;
        }
        
        NSArray *arr = _tab1Array[indexPath.section];
        CouponModel *model = arr[indexPath.row];
        
        [cell loadDataWithModel:model type:self.type];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        
        return cell;
    }
    
    return [[UITableViewCell alloc]init];
}


#pragma - mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    
    
    if (scrollView == _scroll) {
        int page = floor((scrollView.contentOffset.x - DEVICE_WIDTH / 2) / DEVICE_WIDTH) + 1;//只要大于半页就算下一页
        NSLog(@"page %d",page);
        
        //选中状态
        [self controlSelectedButtonTag:page + 100];
    }
    
    
    
    
}

#pragma mark - 点击处理





/**
 *  获取button 根据tag
 */
- (UIButton *)buttonForTag:(int)tag
{
    return (UIButton *)[self.view viewWithTag:tag];
}


/**
 *  控制button选中状态
 */
- (void)controlSelectedButtonTag:(int)tag
{
    for (int i = 0; i < _buttonNum; i ++) {
        
        [self buttonForTag:100 + i].selected = (i + 100 == tag) ? YES : NO;
    }
    
}


/**
 *  点击button
 *
 *  @param sender
 */
- (void)clickToSelect:(UIButton *)sender
{
    [self controlSelectedButtonTag:(int)sender.tag];
    
    __weak typeof(_scroll)weakScroll = _scroll;
    [UIView animateWithDuration:0.1 animations:^{
        
        [weakScroll setContentOffset:CGPointMake(DEVICE_WIDTH * (sender.tag - 100), 0)];
    }];
}



@end
