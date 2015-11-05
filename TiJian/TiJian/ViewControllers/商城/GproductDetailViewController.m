//
//  GproductDetailViewController.m
//  TiJian
//
//  Created by gaomeng on 15/11/2.
//  Copyright © 2015年 lcw. All rights reserved.
//

#import "GproductDetailViewController.h"
#import "GproductDetailTableViewCell.h"
#import "GproductDirectoryTableViewCell.h"

@interface GproductDetailViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    YJYRequstManager *_request;
    AFHTTPRequestOperation *_request_productDetail;
    int _count;
    
    UITableView *_tab;
    
    NSDictionary *_dataDic;
    
    GproductDetailTableViewCell *_tmpCell;
    GproductDirectoryTableViewCell *_tmpCell1;
    
    
    UIView *_downView;
    
    UITableView *_hiddenView;
    
}

@end

@implementation GproductDetailViewController


- (void)dealloc
{
    NSLog(@"%s",__FUNCTION__);
    _tab.delegate = nil;
    _tab.dataSource = nil;
    _tab = nil;
    
    [self removeObserver:self forKeyPath:@"_count"];
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setMyViewControllerLeftButtonType:MyViewControllerLeftbuttonTypeBack WithRightButtonType:MyViewControllerRightbuttonTypeNull];
    
    self.myTitle = @"产品详情";
    
    
    [self addObserver:self forKeyPath:@"_count" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    
    
    [self prepareNetData];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    
    NSNumber *num = [change objectForKey:@"new"];
    
    if ([num intValue] == 1) {
        
    }
    
}


#pragma mark - @protocol UIScrollViewDelegate<NSObject>

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
    
    if (scrollView.tag == 1000) {
        // 下拉到最底部时显示更多数据
        
        
        if(scrollView.contentOffset.y > ((scrollView.contentSize.height - scrollView.frame.size.height + 60 + 30)))
        {
            [self moveToUp:YES];
        }
    }else if (scrollView.tag == 1001){
        if (scrollView.contentOffset.y < -30) {
            [self moveToUp:NO];
        }
    }
    
    
}


- (void)moveToUp:(BOOL)up
{
    NSLog(@"%s",__FUNCTION__);
    if (up) {
        [UIView animateWithDuration:0.3 animations:^{
            _tab.top = -500;
            _hiddenView.top = 0;
            _downView.top = self.view.size.height;
            self.myTitle = @"体检项目";
        }];
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            _tab.top = 0;
            _hiddenView.top = CGRectGetMaxY(_tab.frame);
            _downView.top = DEVICE_HEIGHT - 50-64;
            self.myTitle = @"体检项目";
        }];
    }
    
    
    
    
}




#pragma mark - 网络请求
-(void)prepareNetData{
    
    _request = [YJYRequstManager shareInstance];
    _count = 0;
    
    NSDictionary *parameters = @{
                                 @"product_id":self.productId
                                 };
    
    
    [_request requestWithMethod:YJYRequstMethodGet api:StoreProductDetail parameters:parameters constructingBodyBlock:nil completion:^(NSDictionary *result) {
        
        _dataDic = [result dictionaryValueForKey:@"data"];
        
        [self creatTabAndDownView];
        
    } failBlock:^(NSDictionary *result) {
        
    }];
    
}

#pragma mark - 视图创建
-(void)creatTabAndDownView{
    _tab = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, DEVICE_HEIGHT - 64 - 50) style:UITableViewStylePlain];
    _tab.tag = 1000;
    _tab.delegate = self;
    _tab.dataSource = self;
    [self.view addSubview:_tab];
    
    
    [self creatHiddenView];
    
    [self creatDownView];
    
}

-(void)creatDownView{
    _downView = [[UIView alloc]initWithFrame:CGRectMake(0, DEVICE_HEIGHT - 50-64, DEVICE_WIDTH, 50)];
    _downView.backgroundColor = RGBCOLOR(38, 51, 62);
    
    UIButton *addShopCarBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat theW = [GMAPI scaleWithHeight:50 width:0 theWHscale:180.0/100];
    [addShopCarBtn setFrame:CGRectMake(_downView.frame.size.width-theW, 0, theW, 50)];
    addShopCarBtn.backgroundColor = RGBCOLOR(224, 103, 20);
    [addShopCarBtn setTitle:@"加入购物车" forState:UIControlStateNormal];
    [addShopCarBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    addShopCarBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [_downView addSubview:addShopCarBtn];
    
    CGFloat tw = (_downView.frame.size.width-theW)/4;
    NSArray *titleArray = @[@"客服",@"收藏",@"品牌店",@"购物车"];
    for (int i = 0; i<4; i++) {
        UIButton *oneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [oneBtn setFrame:CGRectMake(i*tw, 0, tw, 50)];
        [oneBtn setTitle:titleArray[i] forState:UIControlStateNormal];
        oneBtn.titleLabel.font = [UIFont systemFontOfSize:10];
        [_downView addSubview:oneBtn];
    }
    [self.view addSubview:_downView];
}

-(void)creatHiddenView{
    _hiddenView = [[UITableView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_tab.frame), DEVICE_WIDTH, DEVICE_HEIGHT - 64) style:UITableViewStyleGrouped];
    _hiddenView.delegate = self;
    _hiddenView.dataSource = self;
    _hiddenView.tag = 1001;
    [self.view addSubview:_hiddenView];
    
}


#pragma mark - UITableViewDelegate && UITableViewDataSource
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView.tag == 1000) {
        static NSString *identifier = @"identifier";
        GproductDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[GproductDetailTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        
        for (UIView *view in cell.contentView.subviews) {
            [view removeFromSuperview];
        }
        
        [cell loadCustomViewWithDic:_dataDic index:indexPath];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }else if (tableView.tag == 1001){
        static NSString *identi = @"identi";
        GproductDirectoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identi];
        if (!cell) {
            cell = [[GproductDirectoryTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identi];
        }
        
        for (UIView *view in cell.contentView.subviews) {
            [view removeFromSuperview];
        }
        
        [cell loadCustomViewWithData:nil indexPath:indexPath];
        
        return cell;
    }
    
    
    
    
    return [[UITableViewCell alloc]init];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    NSInteger num = 1;
    
    if (tableView.tag == 1000) {
        //6个section
        //0     logo图 套餐名 描述 价钱
        //1     优惠券
        //2     主要参数
        //3     评价
        //4     看了又看
        //5     上拉显示体检项目详情
        num = 6;
    }else if (tableView.tag == 1001){
        num = 1;
    }
    
    return num;
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger num = 0;
    
    if (tableView.tag == 1000) {
        if (section == 0) {
            num = 1;
        }else if (section == 1){
            num = 1;
        }else if (section == 2){
            num = 1;
        }else if (section == 3){
            num = 1;//1为暂无平路
        }else if (section == 4){
            num = 1;
        }else if (section == 5){
            num = 1;
        }
    }else if (tableView.tag == 1001){
        num = 20;
    }
    
    
    
    return num;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger height = 0;
    
    
    if (tableView.tag == 1000) {
        if (!_tmpCell) {
            _tmpCell = [[GproductDetailTableViewCell alloc]init];
        }
        for (UIView *view in _tmpCell.contentView.subviews) {
            [view removeFromSuperview];
        }
        height = [_tmpCell loadCustomViewWithDic:_dataDic index:indexPath];
    }else if (tableView.tag == 1001){
        if (!_tmpCell1) {
            _tmpCell1 = [[GproductDirectoryTableViewCell alloc]init];
        }
        for (UIView *view in _tmpCell1.contentView.subviews) {
            [view removeFromSuperview];
        }
        
        height = [_tmpCell1 loadCustomViewWithData:nil indexPath:indexPath];
    }
    
    
    
    
    
    return height;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    CGFloat height = 0.01;
    
    if (tableView.tag == 1000) {
        if (section == 3) {
            height = [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/80];
        }
    }else if (tableView.tag == 1001){
        
        if (section == 0) {
            height = [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/180];
        }
        
        
    }
    
    return height;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    CGFloat height = 0.01;
    
    if (tableView.tag == 1000) {
        if (section == 3) {
            height = 5;
        }
    }else if (tableView.tag == 1001){
        height = 0.01;
    }
    
    return height;
}


-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *view = [[UIView alloc]initWithFrame:CGRectZero];
    if (tableView.tag == 1000) {
        if (section == 3) {
            [view setFrame:CGRectMake(0, 0, DEVICE_WIDTH, 5)];
            view.backgroundColor = RGBCOLOR(244, 245, 246);
        }
    }else if (tableView.tag == 1001){
        
    }
    return view;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc]initWithFrame:CGRectZero];
    
    
    if (tableView.tag == 1000) {
        if (section == 3) {
            [view setFrame:CGRectMake(0, 0, DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/80])];
            UILabel *tLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, 50, view.frame.size.height)];
            tLabel.font = [UIFont systemFontOfSize:14];
            tLabel.text = @"评价";
            [view addSubview:tLabel];
            
            UIButton *moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [moreBtn setFrame:CGRectMake(view.frame.size.width - 100, 0, 100, view.frame.size.height)];
            moreBtn.titleLabel.font = [UIFont systemFontOfSize:14];
            [moreBtn setTitle:@"更多" forState:UIControlStateNormal];
            moreBtn.titleLabel.textColor = [UIColor blackColor];
            [view addSubview:moreBtn];
            
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(tLabel.frame), DEVICE_WIDTH, 0.5)];
            line.backgroundColor = RGBCOLOR(220, 221, 223);
            [view addSubview:line];
            
        }
    }else if (tableView.tag == 1001){
        if (section == 0) {
            [view setFrame:CGRectMake(0, 0, DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/180])];
            view.backgroundColor = [UIColor orangeColor];
            
            UILabel *tishiLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/80])];
            tishiLabel.backgroundColor = [UIColor whiteColor];
            tishiLabel.font = [UIFont systemFontOfSize:12];
            tishiLabel.textAlignment = NSTextAlignmentCenter;
            tishiLabel.textColor = [UIColor blackColor];
            tishiLabel.text = @"下拉显示产品详情";
            [view addSubview:tishiLabel];
            
            UIView *titleView =[[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(tishiLabel.frame),DEVICE_WIDTH, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/100])];
            titleView.backgroundColor = [UIColor whiteColor];
            [view addSubview:titleView];
            
            UIImageView *imv = [[UIImageView alloc]initWithFrame:CGRectMake(5, 0, [GMAPI scaleWithHeight:titleView.frame.size.height width:0 theWHscale:145.0/100], titleView.frame.size.height)];
            imv.backgroundColor = [UIColor orangeColor];
            [titleView addSubview:imv];
            
            UILabel *tLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(imv.frame)+10, 0, titleView.frame.size.width - 10-imv.frame.size.width-5, titleView.frame.size.height)];
            tLabel.font = [UIFont systemFontOfSize:15];
            tLabel.textColor = [UIColor blackColor];
            tLabel.text = @"健康优选套餐(男/女二选一)";
            [titleView addSubview:tLabel];
            
        }
    }
    
    
    
    return view;
}






@end
