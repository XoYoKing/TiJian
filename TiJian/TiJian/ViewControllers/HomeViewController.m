//
//  HomeViewController.m
//  TiJian
//jjklk
//  Created by lichaowei on 15/10/21.
//  Copyright © 2015年 lcw. All rights reserved.
//

#import "HomeViewController.h"
#import "PersonalCustomViewController.h"
#import "GStoreHomeViewController.h"
#import "RecommendMedicalCheckController.h"
#import "PhysicalTestResultController.h"
#import "MedicalOrderController.h"//预约体检

#define kTagOrder 100 //体检预约
#define kTagMarket 101 //体检商城
#define kTagHealth 102 //健康资讯

@interface HomeViewController ()

@end

@implementation HomeViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setNavigationStyle:NAVIGATIONSTYLE_WHITE title:@"健康体检"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithHexString:@"f7f7f7"];
    
    UIScrollView *bgScroll = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, DEVICE_HEIGHT - 48 - 64)];
    [self.view addSubview:bgScroll];
    
    UIImage *image = [UIImage imageNamed:@"homepage_1"];
    CGFloat radio = image.size.height / image.size.width;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:image forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(pushToPersonalCustom) forControlEvents:UIControlEventTouchUpInside];
    [bgScroll addSubview:btn];
    CGFloat width = DEVICE_WIDTH - 10 * 2;
    CGFloat height = width *radio;
    btn.frame = CGRectMake(10, 15, width, height);
    
    NSArray *images = @[[UIImage imageNamed:@"homepage_2"],
                        [UIImage imageNamed:@"homepage_3"],
                        [UIImage imageNamed:@"homepage_4"]];
    
    radio = 200.f / 120.f;//高/宽
    CGFloat width_small = (DEVICE_WIDTH - 10 * 4) / 3.f;
    CGFloat height_small = radio * width_small;
    CGFloat bottom = btn.bottom;
    for (int i = 0; i < 3; i ++) {
        
        UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn1 setImage:images[i] forState:UIControlStateNormal];
        [btn1 addTarget:self action:@selector(clickToPush:) forControlEvents:UIControlEventTouchUpInside];
        btn1.frame = CGRectMake(10 + (width_small + 10) * i, btn.bottom, width_small, height_small);
        [bgScroll addSubview:btn1];
        btn1.tag = 100 + i;
        bottom = btn1.bottom;
    }
    
    //健康信息
    UIView *view_health = [[UIView alloc]initWithFrame:CGRectMake(0, bottom + 15, DEVICE_WIDTH, 77.5)];
    view_health.backgroundColor = [UIColor whiteColor];
    [bgScroll addSubview:view_health];
    [view_health addTaget:self action:@selector(clickToPush:) tag:kTagHealth];
    //图标
    UIImageView *icon = [[UIImageView alloc]initWithFrame:CGRectMake(20, 13.5, 50, 50)];
    [icon addRoundCorner];
    icon.backgroundColor = DEFAULT_TEXTCOLOR;
    [view_health addSubview:icon];
    //标题
    CGFloat left = icon.right + 10;
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(left, 25, DEVICE_WIDTH - left - 20, 14) title:@"经常流鼻血是怎么回事?" font:13 align:NSTextAlignmentLeft textColor:[UIColor colorWithHexString:@"323232"]];
    [view_health addSubview:titleLabel];
    
    UILabel *subLabel = [[UILabel alloc]initWithFrame:CGRectMake(left, titleLabel.bottom + 8, DEVICE_WIDTH - left - 20, 12) title:@"到底是怎么回事呢？专家给你解答" font:11 align:NSTextAlignmentLeft textColor:[UIColor colorWithHexString:@"323232"]];
    [view_health addSubview:subLabel];
    
    bgScroll.contentSize = CGSizeMake(DEVICE_WIDTH, view_health.bottom + 15);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma - mark 事件处理

- (void)clickToPush:(UIButton *)sender
{
    int tag = (int)sender.tag;
    if (tag == kTagOrder) {
        //预约
        [self pushToOrder];
    }else if (tag == kTagMarket){
        //商城
        [self pushToShangCheng];
    }else if (tag == kTagHealth){
        //健康资讯
        [self pushToHealthNews];
    }
}

/**
 *  个性化定制
 */
- (void)pushToPersonalCustom
{
    __weak typeof(self)weakSelf = self;
    BOOL isLogin = [LoginViewController isLogin:self loginBlock:^(BOOL success) {
       
        if (success) {
            [weakSelf pushToPhysicaResult];
        }else
        {
            NSLog(@"没登陆成功");
        }
    }];
    //登录成功
    if (isLogin) {
        
        [weakSelf pushToPhysicaResult];
    }
}

/**
 *  跳转至个性化定制页 或者 结果页
 */
- (void)pushToPhysicaResult
{
    //先判断是否个性化定制过
    BOOL isOver = [LTools cacheBoolForKey:USER_CUSTOMIZATON_RESULT];
    if (isOver) {
        //已经个性化定制过
        PhysicalTestResultController *physical = [[PhysicalTestResultController alloc]init];
        physical.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:physical animated:YES];
    }else
    {
        PersonalCustomViewController *custom = [[PersonalCustomViewController alloc]init];
        custom.lastViewController = self;
        custom.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:custom animated:YES];
    }
}

/**
 *  商城
 */
-(void)pushToShangCheng{
    GStoreHomeViewController *cc= [[GStoreHomeViewController alloc]init];
    cc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:cc animated:YES];
}

/**
 *  健康资讯
 */
- (void)pushToHealthNews
{
    
}

/**
 *  预约体检
 */
- (void)pushToOrder
{
    MedicalOrderController *m_order = [[MedicalOrderController alloc]init];
    m_order.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:m_order animated:YES];
}

@end
