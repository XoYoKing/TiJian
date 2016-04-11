//
//  GproductDetailViewController.h
//  TiJian
//
//  Created by gaomeng on 15/11/2.
//  Copyright © 2015年 lcw. All rights reserved.
//


//商品详情页

#import "MyViewController.h"
@class ProductModel;

@interface GproductDetailViewController : MyViewController

@property(nonatomic,strong)NSString *productId;

@property(nonatomic,assign)BOOL isShopCarPush;

@property(nonatomic,strong)ProductModel *theProductModel;//产品model
@property(nonatomic,strong)UIImage *gouwucheProductImage;//动画image

//代金券购买 (默认选择传过来的代金券)
@property(nonatomic,strong)NSString *VoucherId;//代金券id
//代金券预约
@property(nonatomic,strong)UserInfo *user_voucher;//代金券绑定的人

@property(nonatomic,strong)NSDictionary *userChooseLocationDic;//用户选择筛选的地址


-(void)goToCommentVc;

-(void)goToProductDetailVcWithId:(NSString *)productId;

-(void)goToBrandStoreHomeVc;

@end
