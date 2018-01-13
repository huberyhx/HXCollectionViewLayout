//
//  HXCollectionViewCell.m
//  HXCollectionView
//
//  Created by hubery on 2018/1/13.
//  Copyright © 2018年 hubery. All rights reserved.
//

#import "HXCollectionViewCell.h"
#import "HXShopItem.h"
#import "UIImageView+WebCache.h"

@interface HXCollectionViewCell()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation HXCollectionViewCell

- (void)setShop:(HXShopItem *)shop {
        _shop = shop;
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:_shop.img]];
        self.label.text = _shop.price;
}

@end
