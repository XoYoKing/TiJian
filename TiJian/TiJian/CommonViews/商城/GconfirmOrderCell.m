//
//  GconfirmOrderCell.m
//  TiJian
//
//  Created by gaomeng on 15/11/18.
//  Copyright © 2015年 lcw. All rights reserved.
//

#import "GconfirmOrderCell.h"
#import "ProductModel.h"
#import "HospitalModel.h"
#import "UserInfo.h"
#import "Gbtn.h"
#import "GLabel.h"


@interface GconfirmOrderCell ()
{
    ProductModel *_theModel;//数据源
}
@property(nonatomic,retain)UIImageView *iconImageView;
@property(nonatomic,retain)UILabel *contentLabel;
@property(nonatomic,retain)UILabel *priceLabel;
@property(nonatomic,retain)UILabel *numLabel;

@end

@implementation GconfirmOrderCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //图片
        CGFloat height = [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/195];
        self.iconImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 10, [GMAPI scaleWithHeight:height - 20 width:0 theWHscale:250.0/155], height - 20)];
        [self.contentView addSubview:self.iconImageView];
        
        //内容
        self.contentLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.iconImageView.frame)+5, self.iconImageView.frame.origin.y, DEVICE_WIDTH - 5 - 15 - 5 - self.iconImageView.frame.size.width - 5 - 5, self.iconImageView.frame.size.height/3)];
        self.contentLabel.font = [UIFont systemFontOfSize:14];
        self.contentLabel.numberOfLines = 2;
        self.contentLabel.textColor = [UIColor blackColor];
        [self.contentLabel setMatchedFrame4LabelWithOrigin:CGPointMake(CGRectGetMaxX(self.iconImageView.frame)+5, self.iconImageView.frame.origin.y) height:self.iconImageView.frame.size.height/3 limitMaxWidth:DEVICE_WIDTH - 5 - 15 - 5 - self.iconImageView.frame.size.width - 5 - 5 - 30];
        [self.contentView addSubview:self.contentLabel];
        
        //价钱
        self.priceLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.contentLabel.frame.origin.x, CGRectGetMaxY(self.iconImageView.frame)-self.iconImageView.frame.size.height/3, DEVICE_WIDTH - 5 - 15 - 5 - self.iconImageView.frame.size.width - 5 - 5 - 40, self.iconImageView.frame.size.height/3)];
        self.priceLabel.font = [UIFont systemFontOfSize:13];
        self.priceLabel.textColor = RGBCOLOR(237, 108, 22);
        [self.contentView addSubview:self.priceLabel];
        
        //商品数量
        self.numLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.priceLabel.frame), self.iconImageView.frame.size.height*0.5 - 10 + self.iconImageView.frame.origin.y, 40, 20)];
        self.numLabel.font = [UIFont systemFontOfSize:17];
        self.numLabel.textAlignment = NSTextAlignmentRight;
        self.numLabel.textColor = RGBCOLOR(237, 108, 22);
        [self.contentView addSubview:self.numLabel];
        
        //line
        UIImageView *line = [[UIImageView alloc]initWithFrame:CGRectMake(self.iconImageView.left, height - 0.5, DEVICE_WIDTH - self.iconImageView.left, 0.5)];
        line.backgroundColor = DEFAULT_LINECOLOR;
        [self.contentView addSubview:line];
        
        
        
    }
    return self;
}


-(void)loadCustomViewWithModel:(ProductModel *)model{
    
    _theModel = model;
    
    //图片
    [self.iconImageView l_setImageWithURL:[NSURL URLWithString:model.cover_pic] placeholderImage:nil];
    
    //内容
    self.contentLabel.text = model.product_name;
    [self.contentLabel setMatchedFrame4LabelWithOrigin:CGPointMake(CGRectGetMaxX(self.iconImageView.frame)+5, self.iconImageView.frame.origin.y) height:self.iconImageView.frame.size.height/3 limitMaxWidth:DEVICE_WIDTH - 5 - 15 - 5 - self.iconImageView.frame.size.width - 5 - 5 - 30];
    
    //价钱
    self.priceLabel.text = [NSString stringWithFormat:@"￥%@",model.current_price];
    
    //商品数量
    self.numLabel.text = [NSString stringWithFormat:@"X %@",model.product_num];
    
    [self setYuyueViewWithModel:model];
    


}

+ (CGFloat)heightForCellWithModel:(ProductModel*)theModel{
    
    CGFloat height = [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/195];
    
    height += [self heightWithYuyueViewWithModel:theModel];
    
    return height;
}


//根据productmodel设置预约相关view
-(void)setYuyueViewWithModel:(ProductModel*)theModel{
    //预约相关view
    self.yuyueView = [[UIView alloc]initWithFrame:CGRectMake(0, [GMAPI scaleWithHeight:0 width:DEVICE_WIDTH theWHscale:750.0/195], DEVICE_WIDTH, 0)];
    [self.contentView addSubview:self.yuyueView];
    
    //productModel.hospitalArray ==> hospitalModel.userArray.count
    int num = 0;
    
    for (HospitalModel*model in theModel.hospitalArray) {
         num += model.usersArray.count;
    }
    
    if (num == [theModel.product_num intValue]) {//全部预约
        CGFloat height_hospital = 0;
        //几个分院
        for (int i = 0; i<theModel.hospitalArray.count; i++) {
            //此分院包含几个体检人
            HospitalModel *model_h = theModel.hospitalArray[i];
            NSInteger totlePerson_num = model_h.usersArray.count;
            //创建时间分院view
            [self creatYuyueInfoViewWithFrame:CGRectMake(0, height_hospital, DEVICE_WIDTH, 44 * totlePerson_num + 44) userNum:totlePerson_num hospitalModel:model_h];
            height_hospital += (44 * totlePerson_num + 44);
        }
        //设置高度
        [self.yuyueView setHeight:height_hospital];
        
    }else if (num < [theModel.product_num intValue]){//没有预约 & 部分预约
        if (num == 0){//没有预约
            
            [self creatAddYuyueViewWithY:0];
            //设置高度
            [self.yuyueView setHeight:44];
            
        }else{//部分预约
            //几个分院
            CGFloat height_hospital = 0;
            for (int i = 0; i<theModel.hospitalArray.count; i++) {
                //此分院包含几个体检人
                HospitalModel *model_h = theModel.hospitalArray[i];
                NSInteger totlePerson_num = model_h.usersArray.count;
                [self creatYuyueInfoViewWithFrame:CGRectMake(0, height_hospital, DEVICE_WIDTH, 44*totlePerson_num + 44) userNum:totlePerson_num hospitalModel:model_h];
                height_hospital += (44*totlePerson_num)+44;//加上44时间分院栏
            }
            
            
            //添加预约view
            [self creatAddYuyueViewWithY:height_hospital];
            
            //设置高度
            [self.yuyueView setHeight:(height_hospital+44)];
            
            
        }
    }
    
}


//创建添加预约view
-(void)creatAddYuyueViewWithY:(CGFloat)theY{
    //添加预约view
    UIView *addHospitalView = [[UIView alloc]initWithFrame:CGRectMake(0, theY, DEVICE_WIDTH, 44)];
    [self.yuyueView addSubview:addHospitalView];
    //按钮
    UIImageView *addImv = [[UIImageView alloc]initWithFrame:CGRectMake(15, 44*0.5-7, 14, 14)];
    [addImv setImage:[UIImage imageNamed:@"confirmorderadd.png"]];
    [addHospitalView addSubview:addImv];
    //描述label
    UILabel *timeAndHospitalLabel = [[UILabel alloc]initWithFrame:CGRectMake(addImv.right+5, addImv.frame.origin.y, 70, addImv.frame.size.height)];
    timeAndHospitalLabel.font = [UIFont systemFontOfSize:13];
    timeAndHospitalLabel.textColor = [UIColor blackColor];
    timeAndHospitalLabel.text = @"时间、分院";
    [addHospitalView addSubview:timeAndHospitalLabel];
    //箭头
    UIImageView *jiantouImv = [[UIImageView alloc]initWithFrame:CGRectMake(DEVICE_WIDTH - 16, 44*0.5-6, 6, 12)];
    [jiantouImv setImage:[UIImage imageNamed:@"jiantou.png"]];
    [addHospitalView addSubview:jiantouImv];
    
    [addHospitalView addTapGestureTaget:self action:@selector(yuyueViewClicked) imageViewTag:0];
    
}

//创建预约时间分院infoView
-(void)creatYuyueInfoViewWithFrame:(CGRect)theFrame userNum:(NSInteger)theUserNum hospitalModel:(HospitalModel *)theModel{
    
    UIView *infoView =[[UIView alloc]initWithFrame:theFrame];
    [self.yuyueView addSubview:infoView];
    
    //时间分院view
    UIView *dateAndhospitalView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_WIDTH, 44)];
    [infoView addSubview:dateAndhospitalView];
    UILabel *tLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 44*0.5-7, 65, 14)];
    tLabel.font = [UIFont systemFontOfSize:13];
    tLabel.text = @"时间、分院";
    [dateAndhospitalView addSubview:tLabel];
    GLabel *cLabel = [[GLabel alloc]initWithFrame:CGRectMake(tLabel.right + 5, 44*0.5-7, DEVICE_WIDTH - 15 - 65 - 5 - 20, 14)];
    cLabel.font = [UIFont systemFontOfSize:13];
    cLabel.textColor = RGBCOLOR(95, 154, 205);
    cLabel.textAlignment = NSTextAlignmentRight;
    cLabel.hospitalModel = theModel;
    [cLabel addTapGestureTaget:self action:@selector(cLabelClickedToChangeHospital:) imageViewTag:0];
    cLabel.text = [NSString stringWithFormat:@"%@  %@",theModel.date,theModel.center_name];
    [dateAndhospitalView addSubview:cLabel];
    
    //分割线
    UIView *fenLine = [[UIView alloc]initWithFrame:CGRectMake(80, 43.5, DEVICE_WIDTH - 15, 0.5)];
    fenLine.backgroundColor = RGBCOLOR(223, 224, 225);
    [dateAndhospitalView addSubview:fenLine];
    
    //体检人view
    for (int i = 0; i<theUserNum; i++) {
        
        UserInfo *user = theModel.usersArray[i];
        
        if (i == 0) {
            
            UILabel *tLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, CGRectGetMaxY(dateAndhospitalView.frame)+i*44 + 44*0.5-7, 50, 14)];
            tLabel.font = [UIFont systemFontOfSize:13];
            tLabel.text = @"体检人";
            [infoView addSubview:tLabel];
            
            GLabel *cLabel = [[GLabel alloc]initWithFrame:CGRectMake(tLabel.right + 5, tLabel.frame.origin.y, DEVICE_WIDTH - 15 - 50 - 5 - 25, 14)];
            cLabel.font = [UIFont systemFontOfSize:13];
            cLabel.textAlignment = NSTextAlignmentRight;
            cLabel.text = [NSString stringWithFormat:@"%d. %@ %@ %@",i+1,user.appellation,user.family_user_name,user.id_card];
            cLabel.textColor = RGBCOLOR(95, 154, 205);
            cLabel.hospitalModel = theModel;
            cLabel.userInfo = user;
            [cLabel addTapGestureTaget:self action:@selector(cLabelClickedToChooseUser:) imageViewTag:0];
            [infoView addSubview:cLabel];
            
            //删除
            Gbtn *deleteBtn = [[Gbtn alloc]initWithFrame:CGRectMake(cLabel.right, cLabel.frame.origin.y-7, 25, 25)];
            deleteBtn.hospitalModel = theModel;
            deleteBtn.userInfo = user;
            deleteBtn.backgroundColor = [UIColor redColor];
            [infoView addSubview:deleteBtn];
            [deleteBtn addTarget:self action:@selector(deleteUserInfo:) forControlEvents:UIControlEventTouchUpInside];
            
        }else{
            
            GLabel *cLabel = [[GLabel alloc]initWithFrame:CGRectMake(15, CGRectGetMaxY(dateAndhospitalView.frame)+i*44 + 44*0.5-7, DEVICE_WIDTH - 15 - 25, 14)];
            cLabel.font = [UIFont systemFontOfSize:13];
            cLabel.textAlignment = NSTextAlignmentRight;
            cLabel.text = [NSString stringWithFormat:@"%d. %@ %@ %@",i+1,user.appellation,user.family_user_name,user.id_card];
            cLabel.textColor = RGBCOLOR(95, 154, 205);
            cLabel.hospitalModel = theModel;
            cLabel.userInfo = user;
            [cLabel addTapGestureTaget:self action:@selector(cLabelClickedToChooseUser:) imageViewTag:0];
            [infoView addSubview:cLabel];
            
            //删除
            Gbtn *deleteBtn = [[Gbtn alloc]initWithFrame:CGRectMake(cLabel.right, cLabel.frame.origin.y-7, 25, 25)];
            deleteBtn.hospitalModel = theModel;
            deleteBtn.userInfo = user;
            deleteBtn.backgroundColor = [UIColor redColor];
            [infoView addSubview:deleteBtn];
            [deleteBtn addTarget:self action:@selector(deleteUserInfo:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        
        if (i == theUserNum - 1) {
            //分割线
            UIView *fenLine = [[UIView alloc]initWithFrame:CGRectMake(15, infoView.frame.size.height - 0.5, DEVICE_WIDTH - 15, 0.5)];
            fenLine.backgroundColor = RGBCOLOR(223, 224, 225);
            [infoView addSubview:fenLine];
        }
        
        
    }
    
}

//更改体检分院
-(void)cLabelClickedToChangeHospital:(UITapGestureRecognizer *)sender{
    GLabel *label = (GLabel*)sender.view;
    HospitalModel *hospital = label.hospitalModel;
    if (self.cellClickedBlock) {
        self.cellClickedBlock(CellClickedBlockType_changeHostpital,_theModel,hospital,nil);
    }
    
}

//更改体检人
-(void)cLabelClickedToChooseUser:(UITapGestureRecognizer*)sender{
    GLabel *label = (GLabel*)sender.view;
    HospitalModel *hospital = label.hospitalModel;
    UserInfo *user = label.userInfo;
    if (self.cellClickedBlock) {
        self.cellClickedBlock(CellClickedBlockType_changePerson,_theModel,hospital,user);
    }
    
}



//删除体检人
-(void)deleteUserInfo:(Gbtn*)sender{
    NSLog(@"%s",__FUNCTION__);
    
    int tag1 = 0;
    int tag2 = 0;
    
    for (int i = 0; i<_theModel.hospitalArray.count; i++) {
        HospitalModel *model = _theModel.hospitalArray[i];
        if (model == sender.hospitalModel) {
            tag1 = i;
            for (int j = 0; j<model.usersArray.count; j++) {
                UserInfo *user = model.usersArray[j];
                if (user == sender.userInfo) {
                    tag2 = j;
                }
            }
        }
    }
    
    
    HospitalModel *model_h = _theModel.hospitalArray[tag1];
    [model_h.usersArray removeObjectAtIndex:tag2];
    if (model_h.usersArray.count == 0) {
        [_theModel.hospitalArray removeObjectAtIndex:tag1];
    }
    
    if (self.cellClickedBlock) {
        self.cellClickedBlock(CellClickedBlockType_delete,nil,nil,nil);
    }
    
    
}



//添加预约view点击
-(void)yuyueViewClicked{
    if (self.cellClickedBlock) {
        self.cellClickedBlock(CellClickedBlockType_yuyue,_theModel,nil,nil);
    }
}



//返回单元格高度
+(CGFloat)heightWithYuyueViewWithModel:(ProductModel *)theModel{
    
    CGFloat height = 0;
    
    int num = 0;
    for (HospitalModel*model in theModel.hospitalArray) {
        num += model.usersArray.count;
    }
    
    if (num == [theModel.product_num intValue]) {//全部预约
        //几个分院
        for (int i = 0; i<theModel.hospitalArray.count; i++) {
            //此分院包含几个体检人
            HospitalModel *model_h = theModel.hospitalArray[i];
            NSInteger totlePerson_num = model_h.usersArray.count;
            height += (44*totlePerson_num+44);
        }
    }else if (num < [theModel.product_num intValue]){//没有预约 & 部分预约
        if (num == 0){//没有预约
            height = 44;
        }else{//部分预约
            //几个分院
            for (int i = 0; i<theModel.hospitalArray.count; i++) {
                //此分院包含几个体检人
                HospitalModel *model_h = theModel.hospitalArray[i];
                NSInteger totlePerson_num = model_h.usersArray.count;
                height += (44*totlePerson_num+44);
            }
            
            height += 44;
        }
    }
    
    return height;
    
}










@end
