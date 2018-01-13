//
//  HXCollectionViewLayout.h
//  HXCollectionView
//
//  Created by hubery on 2018/1/12.
//  Copyright © 2018年 hubery. All rights reserved.
// https://github.com/huberyhx/HXCollectionViewLayout.git

#import <UIKit/UIKit.h>

@class HXCollectionViewLayout;

@protocol HXCollectionViewLayoutDelegate <NSObject>

@required
- (CGFloat)waterFlowLayout:(HXCollectionViewLayout *)waterFlowLayout heigthForItemAtIndex:(NSUInteger)index itemWidth:(CGFloat)itemWidth;

@optional
- (CGFloat)columnCountInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout;
- (CGFloat)columnMarginInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout;
- (CGFloat)rowMarginInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout;
- (UIEdgeInsets)edgeInsetsInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout;
@end

@interface HXCollectionViewLayout : UICollectionViewLayout
@property(nonatomic,weak) id<HXCollectionViewLayoutDelegate> delegate;
@end
