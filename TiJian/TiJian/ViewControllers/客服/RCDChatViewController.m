//
//  RCDChatViewController.m
//  RCloudMessage
//
//  Created by Liv on 15/3/13.
//  Copyright (c) 2015年 胡利武. All rights reserved.
//

#import "RCDChatViewController.h"
#import <RongIMKit/RongIMKit.h>
#import "RCDChatViewController.h"

#import "GproductDetailViewController.h"
#import "SimpleMessageCell.h"
#import "SimpleMessage.h"
#import "OrderInfoViewController.h"

#import "ProductModel.h"
#import "GoHealthProductDetailController.h"
#import "OrderModel.h"
#import "CustomProductMsgCell.h"//自定义套餐cell
#import "CustomOrderMsgCell.h"//自定义订单cell
#import "LPhotoBrowser.h"

typedef NS_ENUM(NSInteger,CustomMsgType) {
    CustomMsgTypeProduct = 0,//单品
    CustomMsgTypeOrder, //订单
    CustomMsgTypeProduct_goHealth,//go健康单品详情
    CustomMsgTypeOrder_goHealth //go健康
};

@interface RCDChatViewController ()
{
    NSString *_orderId;
    NSString *_orderNum;
    ProductModel *_p_model;
    RCMessageModel *_temp_msg;//临时model
    CustomMsgType _msgType;//自定义消息类型
    NSString *_phoneNumber;//电话号码
}

@property(nonatomic,retain)UIButton *leftButton;
@property(nonatomic,retain)UILabel *navigationTitle;

@end

@implementation RCDChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];

//    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    UIBarButtonItem * spaceButton1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceButton1.width = -7;
    UIButton *button_back=[[UIButton alloc]initWithFrame:CGRectMake(10,8,40,44)];
    [button_back addTarget:self action:@selector(leftBarButtonItemPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button_back setImage:BACK_DEFAULT_IMAGE forState:UIControlStateNormal];
    [button_back setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    UIBarButtonItem *back_item=[[UIBarButtonItem alloc]initWithCustomView:button_back];
    self.navigationItem.leftBarButtonItems=@[spaceButton1,back_item];
    _leftButton = button_back;

    UILabel *_myTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,100,44)];
    _myTitleLabel.textAlignment = NSTextAlignmentCenter;
    _myTitleLabel.text = self.chatTitle;
    _myTitleLabel.textColor = DEFAULT_TEXTCOLOR;
    _myTitleLabel.font = [UIFont systemFontOfSize:17];
    self.navigationItem.titleView = _myTitleLabel;
    _navigationTitle = _myTitleLabel;

    
    [self.pluginBoardView removeItemAtIndex:2];
    
    if (_msgType == CustomMsgTypeProduct ||
        _msgType == CustomMsgTypeProduct_goHealth) {
        //会话页面注册 UI
        [self registerClass:CustomProductMsgCell.class forCellWithReuseIdentifier:@"CustomProductMsgCell"];
    }else if (_msgType == CustomMsgTypeOrder ||
              _msgType == CustomMsgTypeOrder_goHealth){
        
        [self registerClass:CustomOrderMsgCell.class forCellWithReuseIdentifier:@"CustomOrderMsgCell"];
    }
}

#pragma mark - 单品、订单链接消息处理

-(void)setMsg_model:(id)msg_model
{
    _msg_model = msg_model;
    
    //发送消息model
    if (self.msg_model) {
        
        if ([self.msg_model isKindOfClass:[ProductModel class]])
        {
            _msgType = self.platType == PlatformType_goHealth ? CustomMsgTypeProduct_goHealth : CustomMsgTypeProduct;
            
        }else if ([self.msg_model isKindOfClass:[OrderModel class]])
        {
            _msgType = self.platType == PlatformType_goHealth ? CustomMsgTypeOrder_goHealth : CustomMsgTypeOrder;
        }
        
        //插入自定义cell
        [self addCustomMessage];
    }
}

/**
 *  添加自定义消息
 */
- (void)addCustomMessage
{
    RCMessageModel *aModel = [[RCMessageModel alloc]init];
    _temp_msg = aModel;
    [self.conversationDataRepository addObject:aModel];
    [self.conversationMessageCollectionView reloadData];
}

/**
 *  移除自定义cell
 */
- (void)removeCustomMessage
{
    [self.conversationDataRepository removeObject:_temp_msg];
    [self.conversationMessageCollectionView reloadData];
}

/**
 *  点击发送详情链接
 */
- (void)clickToSendMessage
{
    NSLog(@"发送消息");
    
    //发送单品图文消息
    if (_msgType == CustomMsgTypeProduct ||
        _msgType == CustomMsgTypeProduct_goHealth) {
        
        ProductModel *aModel = (ProductModel *)_msg_model;
        NSString *extra = @"";
        
        //发送消息extra
        CustomMsgType type = self.platType == PlatformType_goHealth ? CustomMsgTypeProduct_goHealth : CustomMsgTypeProduct;
        extra = [self extraWithType:type infoId:aModel.product_id];
        
        NSString *content = aModel.info_url;//单品链接
        RCTextMessage *msg = [RCTextMessage messageWithContent:content];
        msg.extra = extra;
        [self sendMessage:msg pushContent:@"套餐详情"];

        
    }else if (_msgType == CustomMsgTypeOrder ||
              _msgType == CustomMsgTypeOrder_goHealth){
        
        OrderModel *aModel = (OrderModel *)_msg_model;
        NSString *extra = @"";
        
        //发送消息extra
        CustomMsgType type = self.platType == PlatformType_goHealth ? CustomMsgTypeOrder_goHealth : CustomMsgTypeOrder;
        extra = [self extraWithType:type infoId:aModel.order_id];
        
        NSString *content = aModel.info_url;//订单详情链接
        RCTextMessage *msg = [RCTextMessage messageWithContent:content];
        msg.extra = extra;
        [self sendMessage:msg pushContent:@"订单详情"];
    }
    
    //移除自定义cell
    [self removeCustomMessage];
}

/**
 *  获取发送消息extra拓展信息
 *
 *  @param type   消息类型
 *  @param infoId 对应id
 *
 *  @return
 */
- (NSString *)extraWithType:(CustomMsgType)type
                     infoId:(NSString *)infoId
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic safeSetInt:type forKey:@"msgType"];
    [dic safeSetValue:infoId forKey:@"infoId"];
    NSString *jsonString = [LTools JSONStringWithObject:dic];
    return jsonString;
}

#pragma mark -

/**
 *  发送订单信息
 *
 *  @param orderId  订单id
 *  @param orderNum 订单num
 */
//-(void)setOrderMessageWithOrderId:(NSString *)orderId
//                                orderNum:(NSString *)orderNum
//{
//    _orderId = orderId;
//    _orderNum = orderNum;
//    //发送订单图文消息
//    if (_orderId) {
//        
//        [self sendOrderDetailMessageWithOrderId:_orderId orderNum:_orderNum];
//    }
//}
//
//- (void)sendOrderDetailMessageWithOrderId:(NSString *)orderId orderNum:(NSString *)orderNum
//{
//    NSString *imageUrl = @"http://123.57.51.27:86/order.jpg";
//    NSString *digest = @"";
//    
//    NSString *orderInfo = [NSString stringWithFormat:@"orderId=%@",orderId];
//    NSString *title = [NSString stringWithFormat:@"订单编号:%@",orderNum];
//    
//    [self sendMessageTitle:title digest:digest imageUrl:imageUrl extra:orderInfo];
//}

/**
 *  复制单品详情图文消息
 *
 *  @param aModel 单品model
 */
//- (void)setProductMessageWithProductModel:(ProductModel *)aModel
//{
//    _p_model = aModel;
//    
//    //发送单品图文消息
//    if (_p_model) {
//        
//        [self sendProductDetailMessageWithId:_p_model.product_id productName:_p_model.setmeal_name coverImageUrl:_p_model.cover_pic currentPrice:[_p_model.setmeal_original_price floatValue] originalPrice:[_p_model.setmeal_price floatValue]];
//        
//    }
//}

//发送产品图文链接

//-(void)sendProductDetailMessageWithId:(NSString *)productId
//                          productName:(NSString *)productName
//                        coverImageUrl:(NSString *)coverImageUrl
//                         currentPrice:(CGFloat)currentPrice
//                        originalPrice:(CGFloat)originalPrice
//{
//    NSString *imageUrl = coverImageUrl;
//    NSString *digest = [NSString stringWithFormat:@"\n现价:%.2f元\n原价:%.2f元",currentPrice,originalPrice];
//    
//    NSString *extra = [NSString stringWithFormat:@"productId=%@",productId];
//    
//    NSString *title = [NSString stringWithFormat:@"我在看:[%@]",productName];
//    
//    [self sendMessageTitle:title digest:digest imageUrl:imageUrl extra:extra];
//}

//- (void)sendMessageTitle:(NSString *)title
//                    digest:(NSString *)digest
//                  imageUrl:(NSString *)imageUrl
//                     extra:(NSString *)extra
//{
//    //2.0
//    
//    RCRichContentMessage *msg = [RCRichContentMessage messageWithTitle:title digest:digest imageURL:imageUrl extra:extra];
//    
//    [[RCIM sharedRCIM]sendMessage:ConversationType_CUSTOMERSERVICE targetId:SERVICE_ID_2 content:msg pushContent:@"客服消息" pushData:nil success:^(long messageId) {
//        DDLOG(@"messageid %ld",messageId);
//        
//    } error:^(RCErrorCode nErrorCode, long messageId) {
//        DDLOG(@"nErrorCode %ld",(long)nErrorCode);
//
//    }];
//}

#pragma - mark 自定义消息重写方法

-(RCMessageBaseCell *)rcConversationCollectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_msgType == CustomMsgTypeProduct ||
        _msgType == CustomMsgTypeProduct_goHealth) {
        
        NSString * cellIndentifier=@"CustomProductMsgCell";
        CustomProductMsgCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIndentifier           forIndexPath:indexPath];
        cell.backgroundColor = [UIColor whiteColor];
        [cell.senderButton addTarget:self action:@selector(clickToSendMessage) forControlEvents:UIControlEventTouchUpInside];
        [cell loadData:self.msg_model];
        return (RCMessageBaseCell *)cell;
    }else if (_msgType == CustomMsgTypeOrder ||
              _msgType == CustomMsgTypeOrder_goHealth){
        
        NSString * cellIndentifier=@"CustomOrderMsgCell";
        CustomOrderMsgCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIndentifier           forIndexPath:indexPath];
        cell.backgroundColor = [UIColor whiteColor];
        [cell.senderButton addTarget:self action:@selector(clickToSendMessage) forControlEvents:UIControlEventTouchUpInside];
        [cell setCellWithModel:self.msg_model];
        return (RCMessageBaseCell *)cell;
    }

    RCMessageModel *msg = self.conversationDataRepository[indexPath.row];
    NSString * cellIndentifier=@"SimpleMessageCell";
    SimpleMessageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIndentifier           forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    [cell setDataModel:msg];

    return cell;
}
-(CGSize)rcConversationCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //返回自定义cell的实际高度
    if (_msgType == CustomMsgTypeOrder) {
        return CGSizeMake(DEVICE_WIDTH, 60 + 10);
    }
    return CGSizeMake(DEVICE_WIDTH, 60 + 50);
}

-(void) leftBarButtonItemPressed:(id)sender
{
    //需要调用super的实现
    [super leftBarButtonItemPressed:sender];
    
    [self.navigationController popViewControllerAnimated:YES];
}


/**
 *  此处使用自定义设置，开发者可以根据需求自己实现
 *  不添加rightBarButtonItemClicked事件，则使用默认实现。
 */
-(void) rightBarButtonItemClicked:(id) sender
{
    //客服设置
    if(self.conversationType == ConversationType_CUSTOMERSERVICE){
        RCSettingViewController *settingVC = [[RCSettingViewController alloc] init];
        settingVC.conversationType = self.conversationType;
        settingVC.targetId = self.targetId;
        //清除聊天记录之后reload data
        __weak RCDChatViewController *weakSelf = self;
        settingVC.clearHistoryCompletion = ^(BOOL isSuccess)
        {
            if (isSuccess) {
                [weakSelf.conversationDataRepository removeAllObjects];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.conversationMessageCollectionView reloadData];
                });
            }
        };
        [self.navigationController pushViewController:settingVC animated:YES];
    }
    
}


/**
 *  更新左上角未读消息数
 */
-(void)notifyUpdateUnReadMessageCount
{
    __weak typeof(&*self) __weakself = self;
    int count = [[RCIMClient sharedRCIMClient]getUnreadCount: @[@(ConversationType_PRIVATE),@(ConversationType_DISCUSSION), @(ConversationType_APPSERVICE), @(ConversationType_PUBLICSERVICE),@(ConversationType_GROUP)]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (count > 0) {
            [__weakself.navigationItem.leftBarButtonItem setTitle:[NSString stringWithFormat:@"返回(%d)",count]];
        }else
        {
            [__weakself.navigationItem.leftBarButtonItem setTitle:@"返回"];
        }
    });
}

/**
 *  点击消息内容中的链接，此事件不会再触发didTapMessageCell
 *
 *  @param url   Url String
 *  @param model 数据
 */

- (void)didTapUrlInMessageCell:(NSString *)url model:(RCMessageModel *)model
{
    RCRichContentMessage *msg = (RCRichContentMessage *)model.content;
    
    NSLog(@"model %@",msg.extra);
    
    NSString *extra = msg.extra;
    
    NSDictionary *result = [LTools parseJSONStringToNSDictionary:extra];
    //    [dic safeSetInt:type forKey:@"msgType"];
//    [dic safeSetValue:infoId forKey:@"infoId"];
    
    if (result && [LTools isDictinary:result])
    {
        NSString *infoId = result[@"infoId"];
        CustomMsgType msgType = [result[@"msgType"]intValue];
        
        if (msgType == CustomMsgTypeProduct)
        {
            GproductDetailViewController *cc = [[GproductDetailViewController alloc]init];
            cc.productId = infoId;
            [self.navigationController pushViewController:cc animated:YES];
        }
        else if (msgType == CustomMsgTypeProduct_goHealth)
        {
            GoHealthProductDetailController *detail = [[GoHealthProductDetailController alloc]init];
            detail.productId = infoId;
            [self.navigationController pushViewController:detail animated:YES];
        }
        else if (msgType == CustomMsgTypeOrder)
        {
            OrderInfoViewController *cc = [[OrderInfoViewController alloc]init];
            cc.order_id = infoId;
            [self.navigationController pushViewController:cc animated:YES];
        }
        else if (msgType == CustomMsgTypeOrder_goHealth)
        {
            OrderInfoViewController *orderInfo = [[OrderInfoViewController alloc]init];
            orderInfo.platformType = PlatformType_goHealth;
            orderInfo.order_id = infoId;
            orderInfo.lastViewController = self;
            [self.navigationController pushViewController:orderInfo animated:YES];

        }
        
    }else
    {
        //单品
        if ([extra containsString:@"productId="]) {
            
            NSString *productId = @"";
            NSArray *arr = [msg.extra componentsSeparatedByString:@"productId="];
            if (arr.count > 1) {
                
                productId = arr.lastObject;
            }else
            {
                return;
            }
            
            if (productId.length) {
                
                GproductDetailViewController *cc = [[GproductDetailViewController alloc]init];
                cc.productId = productId;
                cc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:cc animated:YES];
            }else
            {
                NSLog(@"单品id有误");
            }
        }
        //订单
        else if ([extra containsString:@"orderId="]){
            
            NSString *orderId = @"";
            NSArray *arr = [msg.extra componentsSeparatedByString:@"orderId="];
            if (arr.count > 1) {
                
                orderId = arr.lastObject;
            }else
            {
                return;
            }
            
            if (orderId.length) {
                
                OrderInfoViewController *cc = [[OrderInfoViewController alloc]init];
                cc.order_id = orderId;
                cc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:cc animated:YES];
            }else
            {
                NSLog(@"订单id有误");
            }
        }

    }
    
}

//- (void)didTapUrlInMessageCell:(NSString *)url model:(RCMessageModel *)model
//{
//    RCRichContentMessage *msg = (RCRichContentMessage *)model.content;
//    
//    NSLog(@"model %@",msg.extra);
//    
//    NSString *extra = msg.extra;
//    
//    //单品
//    if ([extra containsString:@"productId="]) {
//        
//        NSString *productId = @"";
//        NSArray *arr = [msg.extra componentsSeparatedByString:@"productId="];
//        if (arr.count > 1) {
//            
//            productId = arr.lastObject;
//        }else
//        {
//            return;
//        }
//        
//        if (productId.length) {
//            
//            GproductDetailViewController *cc = [[GproductDetailViewController alloc]init];
//            cc.productId = productId;
//            cc.hidesBottomBarWhenPushed = YES;
//            [self.navigationController pushViewController:cc animated:YES];
//        }else
//        {
//            NSLog(@"单品id有误");
//        }
//    }
//    //订单
//    else if ([extra containsString:@"orderId="]){
//        
//        NSString *orderId = @"";
//        NSArray *arr = [msg.extra componentsSeparatedByString:@"orderId="];
//        if (arr.count > 1) {
//            
//            orderId = arr.lastObject;
//        }else
//        {
//            return;
//        }
//        
//        if (orderId.length) {
//            
//            OrderInfoViewController *cc = [[OrderInfoViewController alloc]init];
//            cc.order_id = orderId;
//            cc.hidesBottomBarWhenPushed = YES;
//            [self.navigationController pushViewController:cc animated:YES];
//        }else
//        {
//            NSLog(@"订单id有误");
//        }
//    }
//}

/**
 *  点击消息内容中的电话号码，此事件不会再触发didTapMessageCell
 *
 *  @param phoneNumber Phone number
 *  @param model       数据
 */
- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber model:(RCMessageModel *)model
{
    NSLog(@"phoneNumber %@",phoneNumber);
    
    _phoneNumber = phoneNumber;
    
    NSMutableString *phone = [NSMutableString stringWithString:phoneNumber];
    if ([phone hasPrefix:@"tel://"]) {
        [phone replaceOccurrencesOfString:@"tel://" withString:@"" options:0 range:NSMakeRange(0, phone.length)];
        NSString *msg = [NSString stringWithFormat:@"拨打:%@",phone];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];

    }
}

/*!
 查看图片消息中的图片
 
 @param model   消息Cell的数据模型
 
 @discussion SDK在此方法中会默认调用RCImagePreviewController下载并展示图片。
 */
- (void)presentImagePreviewController:(RCMessageModel *)model
{
    int index = 0;
    
    RCImageMessage *msg = (RCImageMessage *)model.content;
    
    NSInteger initPage = index;
    
    [LPhotoBrowser showWithViewController:self initIndex:initPage photoModelBlock:^NSArray *{
        
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:0];
        
        LPhotoModel *photo = [[LPhotoModel alloc]init];
        
        NSString *imageUrl = msg.imageUrl;
        
        if ([imageUrl hasPrefix:@"http://"] ||
            [imageUrl hasPrefix:@"https://"]) {
            
            photo.thumbImage = msg.thumbnailImage;
            photo.imageUrl = msg.imageUrl;
        }else
        {
            UIImage *originalImage = [UIImage imageWithContentsOfFile:msg.imageUrl];
            photo.image = originalImage;
        }
        
        [temp addObject:photo];
        
        return temp;
    }];
}

#pragma - mark UIAlertViewDelegate <NSObject>

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        
        NSString *phone = _phoneNumber;
        
        if (phone) {
            
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:phone]];
        }
    }
}

/**
 *  消息发送状态通知
 *
 *  @param notification 通知对象
 */
- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification
{
    NSLog(@"messageCellUpdateSendingStatusEvent %@",notification);
}

@end
