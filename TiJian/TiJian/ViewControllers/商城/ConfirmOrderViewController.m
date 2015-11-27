//
//  ConfirmOrderViewController.m
//  TiJian
//
//  Created by gaomeng on 15/11/12.
//  Copyright © 2015年 lcw. All rights reserved.
//


//确认订单

#import "ConfirmOrderViewController.h"
#import "ProductModel.h"
#import "AddAddressController.h"
#import "PayActionViewController.h"
#import "GconfirmOrderCell.h"
#import "AddressModel.h"
#import "GuserAddressViewController.h"
#import "ShoppingAddressController.h"

@interface ConfirmOrderViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
{
    UITableView *_tab;
    UIView *_addressView;
    
    YJYRequstManager *_request;
    AFHTTPRequestOperation *_request_confirmOrder;
    AFHTTPRequestOperation *_request_address;
    
    CGFloat _sumPrice_pay;
    
    NSMutableArray *_addressArray;
    
    
    UIView *_tabFooterView;
    
    NSString *_selectAddressId;//选中的地址
    
    
    NSMutableArray *_theData;//本类内部使用的二维数组
    
    
    
    
    
}
@end

@implementation ConfirmOrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
    [self setMyViewControllerLeftButtonType:MyViewControllerLeftbuttonTypeBack WithRightButtonType:MyViewControllerRightbuttonTypeNull];
    self.myTitle = @"确认订单";
    
    _sumPrice_pay = 0;
    
    
    
    
    [self makeDyadicArray];
    
    
    [self prepareNetData];
    
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - 逻辑处理

//一维数组(里面装产品model)做成二维数组(以品牌id区分)
-(void)makeDyadicArray{
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithCapacity:1];
    for (ProductModel *model in self.dataArray) {
        if (![dic objectForKey:model.brand_id]) {
            NSMutableArray * arr = [NSMutableArray arrayWithCapacity:1];
            [arr addObject:model];
            [dic setValue:arr forKey:model.brand_id];
        }else{
            NSMutableArray *arr = [dic objectForKey:model.brand_id];
            [arr addObject:model];
        }
    }
    
    NSArray *keys = [dic allKeys];
    
    _theData = [NSMutableArray arrayWithCapacity:1];
    
    for (NSString *key in keys) {
        NSMutableArray *arr = [dic objectForKey:key];
        [_theData addObject:arr];
    }
}




#pragma mark - 请求网络数据

//获取用户收货地址
-(void)prepareNetData{
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *dic = @{
                          @"authcode":[GMAPI testAuth]
                          };
    
    if (!_request) {
        _request = [YJYRequstManager shareInstance];
    }
    
    _request_address = [_request requestWithMethod:YJYRequstMethodGet api:ORDER_GET_DEFAULT_ADDRESS parameters:dic constructingBodyBlock:nil completion:^(NSDictionary *result) {
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        _addressArray = [NSMutableArray arrayWithCapacity:1];
        
        NSArray *arr = [result arrayValueForKey:@"list"];
        for (NSDictionary *dic in arr) {
            AddressModel *model = [[AddressModel alloc]initWithDictionary:dic];
            [_addressArray addObject:model];
        }
        
        AddressModel *theModel = nil;
        for (AddressModel *model in _addressArray) {
            if ([model.default_address intValue] == 1) {
                theModel = model;
            }
        }
        
        [self creatTab];
        [self creatAddressViewWithModel:theModel];
        [self creatDownView];
        
        
        
    } failBlock:^(NSDictionary *result) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
}




#pragma mark - 视图创建
-(void)creatTab{
    _tab = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, DEVICE_HEIGHT - 64 - 50) style:UITableViewStyleGrouped];
    _tab.delegate = self;
    _tab.dataSource = self;
    [self.view addSubview:_tab];
    
    [self creatTabFooterViewWithUseScore:NO];
    
}


//创建 更新 tabFooterView
-(void)creatTabFooterViewWithUseScore:(BOOL)state{
    
    if (!_tabFooterView) {
        _tabFooterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 435)];
        _tabFooterView.backgroundColor = [UIColor whiteColor];
    }else{
        for (UIView *view in _tabFooterView.subviews) {
            [view removeFromSuperview];
        }
    }
    
    //第一条分割线
    UIView *line1 = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 5)];
    line1.backgroundColor = RGBCOLOR(244, 245, 246);
    [_tabFooterView addSubview:line1];
    
    //留言view
    UIView *liuyanView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(line1.frame), DEVICE_WIDTH, 50)];
    liuyanView.backgroundColor = [UIColor whiteColor];
    [_tabFooterView addSubview:liuyanView];
    
    UILabel *tLabel = [[UILabel alloc]initWithFrame:CGRectMake(7, 0, 80, 50)];
    tLabel.font = [UIFont systemFontOfSize:15];
    tLabel.text = @"给卖家留言:";
    [liuyanView addSubview:tLabel];
    
    UITextField *liuyantf = [[UITextField alloc]initWithFrame:CGRectMake(CGRectGetMaxX(tLabel.frame)+10, 0, DEVICE_WIDTH - 7-7-10 - tLabel.frame.size.width, 50)];
    liuyantf.font = [UIFont systemFontOfSize:15];
    liuyantf.placeholder = @"选填";
    [liuyanView addSubview:liuyantf];
    
    //第二条分割线
    UIView *line2 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(liuyanView.frame), DEVICE_WIDTH, 2)];
    line2.backgroundColor = RGBCOLOR(244, 245, 246);
    [_tabFooterView addSubview:line2];
    
    //联系卖家
    UIButton *chatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [chatBtn setFrame:CGRectMake(0, CGRectGetMaxY(line2.frame), DEVICE_WIDTH/2, 45)];
    [chatBtn setImage:[UIImage imageNamed:@"order_chat.png"] forState:UIControlStateNormal];
    [chatBtn setTitle:@"联系卖家" forState:UIControlStateNormal];
    [chatBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
    chatBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [chatBtn setTitleColor:RGBCOLOR(93, 148, 201) forState:UIControlStateNormal];
    [_tabFooterView addSubview:chatBtn];
    
    
    //竖条
    UIView *line_shu = [[UIView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(chatBtn.frame), chatBtn.frame.origin.y+10, 1, 25)];
    line_shu.backgroundColor = RGBCOLOR(244, 245, 246);
    [_tabFooterView addSubview:line_shu];
    
    //拨打电话
    UIButton *phoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [phoneBtn setFrame:CGRectMake(CGRectGetMaxX(line_shu.frame), chatBtn.frame.origin.y, DEVICE_WIDTH/2, 45)];
    [phoneBtn setImage:[UIImage imageNamed:@"order_phone.png"] forState:UIControlStateNormal];
    [phoneBtn setTitle:@"拨打电话" forState:UIControlStateNormal];
    [phoneBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
    phoneBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [phoneBtn setTitleColor:RGBCOLOR(93, 148, 201) forState:UIControlStateNormal];
    [_tabFooterView addSubview:phoneBtn];
    
    //第3条分割线
    UIView *line3 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(phoneBtn.frame), DEVICE_WIDTH, 5)];
    line3.backgroundColor = RGBCOLOR(244, 245, 246);
    [_tabFooterView addSubview:line3];
    
    //优惠券
    UIView *youhuiquanView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(line3.frame), DEVICE_WIDTH, 44)];
    youhuiquanView.backgroundColor = [UIColor whiteColor];
    [youhuiquanView addTaget:self action:@selector(youhuiquanViewClicked) tag:0];
    
    UILabel *y_tLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 50, 44)];
    y_tLabel.font = [UIFont systemFontOfSize:15];
    y_tLabel.text = @"优惠券";
    y_tLabel.textColor = [UIColor blackColor];
    [youhuiquanView addSubview:y_tLabel];
    
    UIImageView *jiantou_y = [[UIImageView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 20, 14, 8, 16)];
    [jiantou_y setImage:[UIImage imageNamed:@"personal_jiantou_r.png"]];
    [youhuiquanView addSubview:jiantou_y];
    
    [_tabFooterView addSubview:youhuiquanView];
    
    //第4条分割线
    UIView *line4 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(youhuiquanView.frame), DEVICE_WIDTH, 1)];
    line4.backgroundColor = RGBCOLOR(244, 245, 246);
    [_tabFooterView addSubview:line4];
    
    
    //代金券
    UIView *daijinquanView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(line4.frame), DEVICE_WIDTH, 44)];
    daijinquanView.backgroundColor = [UIColor whiteColor];
    [daijinquanView addTaget:self action:@selector(daijinquanViewClicked) tag:0];
    [_tabFooterView addSubview:daijinquanView];
    
    UILabel *daijinquanLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 50, 44)];
    daijinquanLabel.text = @"代金券";
    daijinquanLabel.font = [UIFont systemFontOfSize:15];
    daijinquanLabel.textColor = [UIColor blackColor];
    [daijinquanView addSubview:daijinquanLabel];
    
    UIImageView *jiantou_d = [[UIImageView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 20, 14, 8, 16)];
    [jiantou_d setImage:[UIImage imageNamed:@"personal_jiantou_r.png"]];
    [daijinquanView addSubview:jiantou_d];
    
    
    //第5条分割线
    UIView *line5 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(daijinquanView.frame), DEVICE_WIDTH, 1)];
    line5.backgroundColor = RGBCOLOR(244, 245, 246);
    [_tabFooterView addSubview:line5];
    

    
    //积分
    UIView *jifenView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(line5.frame), DEVICE_WIDTH, 44)];
    jifenView.backgroundColor = [UIColor whiteColor];
    [_tabFooterView addSubview:jifenView];
    UILabel *jifenLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 30, 44)];
    jifenLabel.text = @"积分";
    jifenLabel.font = [UIFont systemFontOfSize:15];
    jifenLabel.textColor = [UIColor blackColor];
    [jifenView addSubview:jifenLabel];
    
    UILabel *jifenMiaoshuLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(jifenLabel.frame)+10, jifenLabel.frame.origin.y, DEVICE_WIDTH - 15 - 30 - 10 - 65, jifenLabel.frame.size.height)];
    jifenMiaoshuLabel.font = [UIFont systemFontOfSize:12];
    jifenMiaoshuLabel.text = @"共1008积分,可用600积分，抵6元";
    jifenMiaoshuLabel.textColor = [UIColor blackColor];
    jifenMiaoshuLabel.backgroundColor = [UIColor orangeColor];
    [jifenView addSubview:jifenMiaoshuLabel];
    
    UISwitch *switchView = [[UISwitch alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 60, jifenMiaoshuLabel.frame.origin.y+5, 50, 44)];
    switchView.onTintColor = RGBCOLOR(237, 108, 22);
    [switchView setOn:state];
    [jifenView addSubview:switchView];
    
    [switchView addTarget:self action:@selector(getValue:) forControlEvents:UIControlEventValueChanged];
    
    
    //最后一条分割线
    UIView *lastLine;
    if (state) {//使用积分
        //第6条分割线
        UIView *line6 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(jifenView.frame), DEVICE_WIDTH, 1)];
        line6.backgroundColor = RGBCOLOR(244, 245, 246);
        [_tabFooterView addSubview:line6];
        
        //使用积分
        UIView *useJifenView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(line6.frame), DEVICE_WIDTH, 44)];
        useJifenView.backgroundColor = [UIColor whiteColor];
        [_tabFooterView addSubview:useJifenView];
        
        UILabel *lb1 = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 40, 44)];
        lb1.textColor = [UIColor blackColor];
        lb1.font = [UIFont systemFontOfSize:15];
        lb1.text = @"使用";
        [useJifenView addSubview:lb1];
        
        
        UITextField *useScoreTf = [[UITextField alloc]initWithFrame:CGRectMake(CGRectGetMaxX(lb1.frame)+10, 10, 100, 24)];
        useScoreTf.font = [UIFont systemFontOfSize:15];
        useScoreTf.textAlignment = NSTextAlignmentCenter;
        useScoreTf.delegate = self;
        useScoreTf.layer.borderWidth = 0.5;
        useScoreTf.layer.cornerRadius = 4;
        useScoreTf.layer.borderColor = [[UIColor grayColor]CGColor];
        [useJifenView addSubview:useScoreTf];
        
        UILabel *lb2 = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(useScoreTf.frame)+10, 0, 40, 44)];
        lb2.text = @"积分,";
        lb2.textColor = [UIColor blackColor];
        lb2.font = [UIFont systemFontOfSize:15];
        [useJifenView addSubview:lb2];
        
        UILabel *lb3 = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(lb2.frame), 0, 100, 44)];
        lb3.textColor = RGBCOLOR(240, 109, 23);
        lb3.font = [UIFont systemFontOfSize:15];
        lb3.text = @"抵6元";
        [useJifenView addSubview:lb3];
        
        
        
        //第7条分割线
        UIView *line7 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(useJifenView.frame), DEVICE_WIDTH, 5)];
        line7.backgroundColor = RGBCOLOR(244, 245, 246);
        [_tabFooterView addSubview:line7];
        lastLine = line7;
        
    }else{//不使用积分
        lastLine = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(jifenView.frame), DEVICE_WIDTH, 5)];
        lastLine.backgroundColor = RGBCOLOR(244, 245, 246);
        [_tabFooterView addSubview:lastLine];
    }

    //商品金额 运费 优惠券 代金券 积分 统计view
    UIView *theNewbilityView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(lastLine.frame), DEVICE_WIDTH, 140)];
    theNewbilityView.backgroundColor = [UIColor orangeColor];
    [_tabFooterView addSubview:theNewbilityView];
    
    NSArray *titleArray = @[@"商品金额",@"运费",@"优惠券",@"代金券",@"积分"];
    for (int i = 0; i<titleArray.count; i++) {
        UILabel *tLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 10+i*25, 70, 20)];
        tLabel.font = [UIFont systemFontOfSize:15];
        tLabel.backgroundColor = RGBCOLOR_ONE;
        tLabel.text = titleArray[i];
        [theNewbilityView addSubview:tLabel];
        
    }
    
    
    for (int i = 0; i<titleArray.count; i++) {
        UILabel *cLabel = [[UILabel alloc]initWithFrame:CGRectMake(90, 10+i*25, DEVICE_WIDTH-100, 20)];
        cLabel.textAlignment = NSTextAlignmentRight;
        cLabel.textColor = RGBCOLOR(237, 108, 22);
        cLabel.font = [UIFont systemFontOfSize:15];
        cLabel.backgroundColor = RGBCOLOR_ONE;
        [theNewbilityView addSubview:cLabel];
    }
    
    _tab.tableFooterView = _tabFooterView;

}








-(void)creatAddressViewWithModel:(AddressModel*)theModel{
    if (!_addressView) {
        _addressView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 115)];
        _addressView.backgroundColor = RGBCOLOR(244, 245, 246);
    }else{
        for (UIView *view in _addressView.subviews) {
            [view removeFromSuperview];
        }
    }
    
    
    
    if (!theModel) {//没有地址
        
        
        
        //上分割线
        UIImageView *imv = [[UIImageView alloc]initWithFrame:CGRectMake(0, 5, DEVICE_WIDTH, 2.5)];
        [imv setImage:[UIImage imageNamed:@"shoppingcart_dd_top_line.png"]];
        [_addressView addSubview:imv];
        
        //内容
        UIView *contentView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(imv.frame), DEVICE_WIDTH, 60)];
        contentView.backgroundColor = [UIColor whiteColor];
        [_addressView addSubview:contentView];
        [contentView addTaget:self action:@selector(goToAddressVC) tag:0];
        
        UILabel *aLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 20, 150, 20)];
        aLabel.text = @"请填写收货地址";
        aLabel.textColor = RGBCOLOR(80, 81, 82);
        aLabel.font = [UIFont systemFontOfSize:15];
        [contentView addSubview:aLabel];
        
        UIImageView *jiantouImv = [[UIImageView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 20, 22, 8, 16)];
        [jiantouImv setImage:[UIImage imageNamed:@"personal_jiantou_r.png"]];
        [contentView addSubview:jiantouImv];
        
        //下分割线
        UIImageView *imv1 = [[UIImageView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(contentView.frame), DEVICE_WIDTH, 2.5)];
        [imv1 setImage:[UIImage imageNamed:@"shoppingcart_dd_top_line.png"]];
        [_addressView addSubview:imv1];
        
        //调整addressview高度
        [_addressView setHeight:CGRectGetMaxY(imv1.frame)+5];
        
        _tab.tableHeaderView = _addressView;
        
        
    }else{
        //上分割线
        UIImageView *imv = [[UIImageView alloc]initWithFrame:CGRectMake(0, 5, DEVICE_WIDTH, 2.5)];
        [imv setImage:[UIImage imageNamed:@"shoppingcart_dd_top_line.png"]];
        [_addressView addSubview:imv];
        
        //内容
        UIView *contentView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(imv.frame), DEVICE_WIDTH, 100)];
        contentView.backgroundColor = [UIColor whiteColor];
        [_addressView addSubview:contentView];
        [contentView addTaget:self action:@selector(goToAddressVC) tag:0];
        
        //姓名
        UIImageView *nameLogoImv = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 12, 17.5)];
        [nameLogoImv setImage:[UIImage imageNamed:@"shoppingcart_dd_top_name.png"]];
        [contentView addSubview:nameLogoImv];
        UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(nameLogoImv.frame)+8, 10, 80, nameLogoImv.frame.size.height)];
        nameLabel.font = [UIFont systemFontOfSize:14];
        nameLabel.textColor = [UIColor blackColor];
        nameLabel.text = theModel.receiver_username;
        [contentView addSubview:nameLabel];
        
        //电话
        UIImageView *phoneLogoImv = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(nameLabel.frame)+10, nameLabel.frame.origin.y, 12, 17.5)];
        [phoneLogoImv setImage:[UIImage imageNamed:@"shoppingcart_dd_top_phone.png"]];
        [contentView addSubview:phoneLogoImv];
        UILabel *phoneLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(phoneLogoImv.frame)+8, 10, 110, phoneLogoImv.frame.size.height)];
        phoneLabel.font = [UIFont systemFontOfSize:14];
        phoneLabel.text = theModel.mobile;
        [contentView addSubview:phoneLabel];
        
        //详细地址
        UILabel *addressLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(phoneLabel.frame)+10, DEVICE_WIDTH - 20, contentView.frame.size.height - nameLogoImv.frame.size.height -30)];
        addressLabel.font = [UIFont systemFontOfSize:14];
        addressLabel.textColor = [UIColor blackColor];
        addressLabel.text = theModel.address;
        [contentView addSubview:addressLabel];
        
        
        //自适应地址label高度
        [addressLabel setMatchedFrame4LabelWithOrigin:CGPointMake(10, CGRectGetMaxY(phoneLabel.frame)+10) width:DEVICE_WIDTH - 20];
        
        //调整contentview高度
        [contentView setHeight:CGRectGetMaxY(addressLabel.frame)+10];
        
        //下分割线
        UIImageView *imv1 = [[UIImageView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(contentView.frame), DEVICE_WIDTH, 2.5)];
        [imv1 setImage:[UIImage imageNamed:@"shoppingcart_dd_top_line.png"]];
        [_addressView addSubview:imv1];
        
        //调整addressview高度
        [_addressView setHeight:CGRectGetMaxY(imv1.frame)+5];
        
        _tab.tableHeaderView = _addressView;
    }
    
    
    
    
}


//创建下面view
-(void)creatDownView{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, DEVICE_HEIGHT - 64 - 50, DEVICE_WIDTH, 50)];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    
    UIButton *confirmOrderBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmOrderBtn setFrame:CGRectMake(DEVICE_WIDTH - 80, 0, 80, 50)];
    confirmOrderBtn.backgroundColor = [UIColor orangeColor];
    confirmOrderBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [confirmOrderBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmOrderBtn setTitle:@"提交订单" forState:UIControlStateNormal];
    [confirmOrderBtn addTarget:self action:@selector(confirmOrderBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:confirmOrderBtn];
    
}


#pragma mark - 点击事件

//选择使用优惠券
-(void)youhuiquanViewClicked{
    NSLog(@"%s",__FUNCTION__);
}

//选择使用代金券
-(void)daijinquanViewClicked{
    NSLog(@"%s",__FUNCTION__);
}


-(void)getValue:(UISwitch*)sender{
    
    
    [self creatTabFooterViewWithUseScore:sender.isOn];
    
    
}



//提交订单
-(void)confirmOrderBtnClicked{
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    
    if (!_request) {
        _request = [YJYRequstManager shareInstance];
    }
    
    
    
    NSMutableArray *product_ids_arr = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *product_nums_arr = [NSMutableArray arrayWithCapacity:1];
    NSString *total_price = @"0";
    CGFloat price = 0;
    for (NSArray *arr in _theData) {
        for (ProductModel *oneModel in arr) {
            [product_ids_arr addObject:oneModel.product_id];
            [product_nums_arr addObject:oneModel.product_num];
            price += [oneModel.current_price floatValue] * [oneModel.product_num intValue];
        }
    }
    
    _sumPrice_pay = price;
    
    total_price = [NSString stringWithFormat:@"%.2f",price];
    
    
    NSLog(@"%@",product_ids_arr);
    NSString *product_ids_str = [product_ids_arr componentsJoinedByString:@","];
    NSString *product_nums_str = [product_nums_arr componentsJoinedByString:@","];

    
    
    
    
    NSDictionary *dic = @{
                          @"authcode":[GMAPI testAuth],
                          @"product_ids":product_ids_str,
                          @"product_nums":product_nums_str,
                          @"address_id":@"1",
                          @"order_note":@"订单备注",
                          @"is_use_score":@"0",
                          @"total_price":total_price,
                          @"real_price":total_price
                          };
    
    
//    NSDictionary *dic1 = @{
//                           @"authcode":[GMAPI testAuth],
//                           @"product_ids":@"1,2",
//                           @"product_nums":@"1,1",
//                           @"address_id":@"订单id",
//                           @"order_note":@"订单备注",
//                           @"is_use_score":@"是否使用积分",
//                           @"score":@"使用的积分",
//                           @"coupon_id":@"优惠券id",
//                           @"vouchers_id":@"代金券",
//                           @"is_appoint":@"是否是预约页面跳转过来的 1：是； 由购物车跳转过来的不用传递这个参数",
//                           @"total_price":@"总价格"
//                           };
    
    __weak typeof(self)weakSelf = self;
    
    _request_confirmOrder = [_request requestWithMethod:YJYRequstMethodPost api:ORDER_SUBMIT parameters:dic constructingBodyBlock:nil completion:^(NSDictionary *result) {
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        NSLog(@"%@",result);
        NSString *orderId = [result stringValueForKey:@"order_id"];
        NSString *orderNum = [result stringValueForKey:@"order_no"];
        [weakSelf pushToPayPageWithOrderId:orderId orderNum:orderNum];
        
    } failBlock:^(NSDictionary *result) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        NSLog(@"%@",result);
    }];
    
    
}


/**
 *  跳转至支付页面
 */
- (void)pushToPayPageWithOrderId:(NSString *)orderId
                        orderNum:(NSString *)orderNum
{
    
    
    [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_UPDATE_TO_CART object:nil];
    
    
    PayActionViewController *pay = [[PayActionViewController alloc]init];
    pay.orderId = orderId;
    pay.orderNum = orderNum;
    pay.sumPrice = _sumPrice_pay;
    pay.lastVc = self;
    if (self.lastViewController) {
        
        [self.lastViewController.navigationController popToViewController:self.lastViewController animated:NO];
        [self.lastViewController.navigationController pushViewController:pay animated:YES];
        return;
    }
    [self.navigationController pushViewController:pay animated:YES];
}



//跳转编辑地址vc
-(void)goToAddressVC{
    
    if (_addressArray.count == 0) {//没有收货地址
        
    }else{//有收货地址
        
    }
//    
//    GuserAddressViewController *cc = [[GuserAddressViewController alloc]init];
//    [self.navigationController pushViewController:cc animated:YES];
    
    
    __weak typeof(self)wealSelf = self;
    ShoppingAddressController *address = [[ShoppingAddressController alloc]init];
    address.isSelectAddress = YES;
    address.selectAddressId = _selectAddressId;
    address.selectAddressBlock = ^(AddressModel *aModel){
        _selectAddressId = aModel.address_id;
        [wealSelf updateAddressInfoWithModel:aModel];//更新收货地址显示
//        [wealSelf updateExpressFeeWithAddressId:aModel.address_id];//更新邮费
    };
    
    [self.navigationController pushViewController:address animated:YES];
}
/**
 *  更新收货地址信息
 *
 *  @param aModel
 
 */
- (void)updateAddressInfoWithModel:(AddressModel *)aModel
{
    NSLog(@"---address %@",aModel.address);
    
    [_tab.tableHeaderView removeFromSuperview];
    _tab.tableHeaderView = nil;
    
    [self creatAddressViewWithModel:aModel];
}







/**
 *  切换购物地址时 更新邮费
 */
- (void)updateExpressFeeWithProviceId:(NSString *)privinceId
                               cityId:(NSString *)cityId
{
//    NSString *authkey = [GMAPI getAuthkey];
//    NSString *province_id = privinceId;
//    NSString *city_id = cityId;
//    NSString *total_price = NSStringFromFloat(_sumPrice_pay);
//    NSDictionary *params = @{@"authcode":authkey,
//                             @"province_id":province_id,
//                             @"city_id":city_id,
//                             @"total_price":total_price};
//    
//    __weak typeof(_table)weakTable = _table;
//    __weak typeof(self)weakSelf = self;
//    
//    NSString *url = [LTools url:ORDER_GET_EXPRESS_FEE withParams:params];
//    LTools *tool = [[LTools alloc]initWithUrl:url isPost:NO postData:nil];
//    [tool requestCompletion:^(NSDictionary *result, NSError *erro) {
//        
//        NSLog(@"更新邮费%@ %@",result[RESULT_INFO],result);
//        float fee = [result[@"fee"]floatValue];
//        _expressFee = fee;
//        [weakSelf updateSumPrice];
//        [weakTable reloadData];
//        
//    } failBlock:^(NSDictionary *result, NSError *erro) {
//        
//        NSLog(@"更新邮费 失败 %@",result[RESULT_INFO]);
//        
//    }];
}



#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    CGSize ss = _tab.contentSize;
    [_tab setContentSize:CGSizeMake(ss.width, ss.height+200)];
    
    CGPoint pp = _tab.contentOffset;
    [_tab setContentOffset:CGPointMake(0, pp.y +200) animated:YES];
    return YES;
}



#pragma mark - UITableViewDelegate && UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    NSInteger num = 0;
    num = _theData.count;
    return num;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger num = 0;
    NSArray *arr = _theData[section];
    num = arr.count;
    return num;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    CGFloat height = [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/80];
    return height;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    CGFloat height = 0.01;
    return height;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [GconfirmOrderCell heightForCell];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc]initWithFrame:CGRectZero];
    
    NSArray *arr = _theData[section];
    
    ProductModel *amodel = arr[0];
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH - 30 theWHscale:750.0/80])];
    titleLabel.font = [UIFont systemFontOfSize:14];
    titleLabel.text = amodel.brand_name;
    [view addSubview:titleLabel];
    
    [view setFrame:CGRectMake(0, 0, DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/80])];
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *view = [[UIView alloc]initWithFrame:CGRectZero];
//    [view setFrame:CGRectMake(0, 0, DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/100])];
//    view.backgroundColor = [UIColor purpleColor];
//    
//    UIView *upLine = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/10])];
//    upLine.backgroundColor = RGBCOLOR(244, 245, 246);
//    [view addSubview:upLine];
//    
//    UIView *midView = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(upLine.frame), DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/80])];
//    midView.backgroundColor = [UIColor whiteColor];
//    
//    
//    
//    
//    UIView *downLine = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(midView.frame), DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/10])];
//    [view addSubview:downLine];
    
    return view;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"identifier";
    GconfirmOrderCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[GconfirmOrderCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    NSArray *arr = _theData[indexPath.section];
    ProductModel *model = arr[indexPath.row];
    
    [cell loadCustomViewWithModel:model];
    
    return cell;
}


@end
