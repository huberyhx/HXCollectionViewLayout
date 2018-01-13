//
//  ViewController.m
//  HXCollectionView
//
//  Created by hubery on 2018/1/12.
//  Copyright © 2018年 hubery. All rights reserved.
//

#import "ViewController.h"
#import "HXCollectionViewLayout.h"
#import "HXCollectionViewCell.h"
#import "HXShopItem.h"
#import "MJExtension.h"
#import "MJRefresh.h"


@interface ViewController ()<UICollectionViewDelegate , UICollectionViewDataSource,HXCollectionViewLayoutDelegate>
@property(nonatomic,strong) UICollectionView *collectionView;
@property(nonatomic,strong) NSMutableArray *shops;
@end

@implementation ViewController

- (void)viewDidLoad {
        [super viewDidLoad];
        [self setupView];
        self.collectionView.header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewShops)];
        [self.collectionView.header beginRefreshing];
        
        self.collectionView.footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreShops)];
        self.collectionView.footer.hidden = YES;
}

- (void)loadNewShops {
        //假装有网络延时
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSArray *shops = [HXShopItem objectArrayWithFilename:@"shop.plist"];
                [self.shops removeAllObjects];
                [self.shops addObjectsFromArray:shops];
                [self.collectionView reloadData];
                [self.collectionView.header endRefreshing];
        });
}

- (void)loadMoreShops {
        //假装有网络延时
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSArray *shops = [HXShopItem objectArrayWithFilename:@"shop.plist"];
                [self.shops addObjectsFromArray:shops];
                // 刷新数据
                [self.collectionView reloadData];
                [self.collectionView.footer endRefreshing];
        });
}

- (void)setupView {
        HXCollectionViewLayout *layout = [[HXCollectionViewLayout alloc]init];
        layout.delegate = self;
        UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:self.view.bounds collectionViewLayout:layout];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.backgroundColor = [UIColor whiteColor];
        [collectionView registerNib:[UINib nibWithNibName:@"HXCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"HXCollectionViewCell"];
        [self.view addSubview:collectionView];
        self.collectionView = collectionView;
}

#pragma UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
        self.collectionView.footer.hidden = self.shops.count == 0;
        return self.shops.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
        HXCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXCollectionViewCell" forIndexPath:indexPath];
        cell.shop = self.shops[indexPath.item];
        return cell;
}

#pragma HXCollectionViewLayoutDelegate
- (CGFloat)waterFlowLayout:(HXCollectionViewLayout *)waterFlowLayout heigthForItemAtIndex:(NSUInteger)index itemWidth:(CGFloat)itemWidth {
        HXShopItem *shop = self.shops[index];
        return itemWidth * shop.h / shop.w;
}

- (CGFloat)columnCountInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout {
        return 3;
}
- (CGFloat)columnMarginInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout {
        return 10;
}
- (CGFloat)rowMarginInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout {
        return 10;
}
- (UIEdgeInsets)edgeInsetsInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout {
        return UIEdgeInsetsMake(10, 10, 10, 10);
}

#pragma 懒加载
- (NSMutableArray *)shops {
        if (!_shops) {
                _shops = [[NSMutableArray alloc]init];
        }
        return _shops;
}
@end
