//
//  ProductModel.h
//  TiJian
//
//  Created by lichaowei on 15/11/4.
//  Copyright © 2015年 lcw. All rights reserved.
//

/**
 *  产品model
 */
#import "BaseModel.h"

@interface ProductModel : BaseModel
@property(nonatomic,retain)NSString *add_time;
@property(nonatomic,retain)NSString *brand_id;
@property(nonatomic,retain)NSArray  *city_info;
@property(nonatomic,retain)NSString *comment_num;
@property(nonatomic,retain)NSString *cover_pic;
@property(nonatomic,retain)NSString *cover_pic_height;
@property(nonatomic,retain)NSString *cover_pic_width;
@property(nonatomic,retain)NSString *favor_num;
@property(nonatomic,retain)NSString *gender;
@property(nonatomic,retain)NSString *is_common;
@property(nonatomic,retain)NSString *product_id;
@property(nonatomic,retain)NSString *setmeal_id;
@property(nonatomic,retain)NSString *setmeal_inprice;
@property(nonatomic,retain)NSString *setmeal_name;
@property(nonatomic,retain)NSString *setmeal_original_price;
@property(nonatomic,retain)NSString *setmeal_price;
@property(nonatomic,retain)NSString *shelf_status;
@property(nonatomic,retain)NSString *status;
@property(nonatomic,retain)NSString *type_id;

//购物车相关
@property(nonatomic,strong)NSString *product_name;
@property(nonatomic,strong)NSString *current_price;
@property(nonatomic,strong)NSString *product_num;
@property(nonatomic,assign)BOOL userChoose;//用户是否选择
@property(nonatomic,strong)NSString *brand_name;
@property(nonatomic,strong)NSString *cart_pro_id;//购物车id
@property(nonatomic,strong)NSString *original_price;//原价

//预约相关
@property(nonatomic,strong)NSString *type;//1 公司购买套餐 2 公司代金券 3 普通套餐
@property(nonatomic,strong)NSDictionary *company_info;//"company_id": "1",company_name": "阿里集团"
@property(nonatomic,strong)NSString *coupon_id;
@property(nonatomic,strong)NSString *vouchers_price;//代金卷金额
//@property(nonatomic,strong)NSString *description;
@property(nonatomic,strong)NSString *deadline;
@property(nonatomic,strong)NSString *product_total_num;
@property(nonatomic,strong)NSString *product_price;
@property(nonatomic,strong)NSString *appointed_num;
@property(nonatomic,strong)NSString *no_appointed_num;

@property(nonatomic,strong)NSDictionary *checkuper_info;//{age;gender;id_card;mobile;order_checkuper_id;user_name;

@property(nonatomic,strong)NSString *order_id;//对应订单id


@end