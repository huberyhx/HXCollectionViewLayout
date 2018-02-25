说来惭愧,使用collectionView这么久了,还从来没自己写过瀑布流,废话不多说,先上效果图:

![效果图](http://upload-images.jianshu.io/upload_images/2954364-b7689f69bfe1ba14.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


数据来源
数据源来自项目中的shop.plist
使用MJExtension转为模型HXShopItem
保存在shops数组里
列表刷新用的MJRefresh
图片加载使用SDWebImage
- 加载数据时使用了GCD延时一秒,假装有网络延时
```
- (void)loadNewShops {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSArray *shops = [HXShopItem objectArrayWithFilename:@"shop.plist"];
                [self.shops removeAllObjects];
                [self.shops addObjectsFromArray:shops];
                [self.collectionView reloadData];
                [self.collectionView.header endRefreshing];
        });
}
```


数据源方法
```
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
```

瀑布流布局的HXCollectionViewLayout:
cell的布局属性完全取决于Layout,不得不佩服苹果把它封装的这么完美

- Layout的代理 :
```
@protocol HXCollectionViewLayoutDelegate <NSObject>

@required
//获取每个cell的高度
- (CGFloat)waterFlowLayout:(HXCollectionViewLayout *)waterFlowLayout heigthForItemAtIndex:(NSUInteger)index itemWidth:(CGFloat)itemWidth;

@optional
- (CGFloat)columnCountInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout;
- (CGFloat)columnMarginInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout;
- (CGFloat)rowMarginInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout;
- (UIEdgeInsets)edgeInsetsInWaterflowLayout:(HXCollectionViewLayout *)waterflowLayout;
@end
```
代理中是一些获取布局属性的方法
我喜欢写成代理的方式去获取而不是设置成属性给外界赋值
因为设置成属性的话
就要等待外界的赋值,而且外界可以随时修改
这样的话就要监听属性的set方法来刷新数据,感觉略为被动
如果写成代理则是调用代理方法主动去获取属性,有主动权

- Layout中用到的属性
```
@interface HXCollectionViewLayout()
//存放每一列高度的数组
@property(nonatomic,strong) NSMutableArray *columnHeights;
//存放所有cell布局属性的数组
@property(nonatomic,strong) NSMutableArray *attributesArray;
//行间距
@property(nonatomic,assign) CGFloat rowMargin;
//列间距
@property(nonatomic,assign) CGFloat columnMargin;
//列数
@property(nonatomic,assign) NSInteger columnCount;
//边距
@property(nonatomic,assign) UIEdgeInsets edgeInsets;
@end

/** 默认的列数 */
static const NSInteger HXDefaultColumnCount = 3;
/** 每一列之间的间距 */
static const CGFloat HXDefaultColumnMargin = 10;
/** 每一行之间的间距 */
static const CGFloat HXDefaultRowMargin = 10;
/** 边缘间距 */
static const UIEdgeInsets HXDefaultEdgeInsets = {10, 10, 10, 10};

```

- Layout的初始化方法
在初始化方法中,做了这几件事:
清除列高数组中所有的数据
然后添加初始化高度 (就是上边距) 
清除所有cell的布局属性
调用layoutAttributesForItemAtIndexPath
重新计算每个cell的布局属性
(因为初始化方法调用一次,又因为cell位置大小是确定的,所以在初始化方法里计算一次就可)
```
- (void)prepareLayout {
        [super prepareLayout];
        //清除以前计算的所有高度
        [self.columnHeights removeAllObjects];
        for (NSInteger i = 0; i < self.columnCount; i++) {
                [self.columnHeights addObject:@(self.edgeInsets.top)];
        }
        //清除之前所有的布局属性
        [self.attributesArray removeAllObjects];
        //开始创建新的布局属性
        NSInteger count = [self.collectionView numberOfItemsInSection:0];
        for (NSInteger i = 0; i < count; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                //获取indexPath位置对应的cell布局属性
                UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
                [self.attributesArray addObject:attributes];
        }
}
```

- layoutAttributesForItemAtIndexPath方法
这个方法做了这几件事:
计算collectionView的宽度
根据collectionView宽度和列数计算cell宽度
调用代理方法获取cell的高度
查找所有列中最短的一列,根据这一列的高度算出cell的y坐标
根据列数计算x坐标
这样cell的frame就计算出来了
更新最短那列的高度
```
//返回每个indexPath对应的cell的布局属性
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        //collectionView的宽度
        CGFloat collectionViewWidth = self.collectionView.frame.size.width;
        //布局的宽度和高度
        CGFloat width = (collectionViewWidth - self.edgeInsets.left - self.edgeInsets.right - (self.columnCount - 1)*self.columnMargin) / self.columnCount;
        CGFloat height = [self.delegate waterFlowLayout:self heigthForItemAtIndex:indexPath.item itemWidth:width];
        
        //查找对短的一列
        NSInteger destColumn = 0;
        CGFloat minColumnHeight = [self.columnHeights[0] doubleValue];
        for (NSInteger i = 1; i < self.columnCount; i++) {
                //第i列高度
                CGFloat columnHeight = [self.columnHeights[i] doubleValue];
                if (columnHeight < minColumnHeight) {
                        minColumnHeight = columnHeight;
                        destColumn = i;
                }
        }
        CGFloat x = self.edgeInsets.left + destColumn*(width + self.columnMargin);
        CGFloat y = minColumnHeight;
        if (y != self.edgeInsets.top) {
                y += self.rowMargin;
        }
        attributes.frame = CGRectMake(x, y, width, height);
        
        //更新最短那列的高度
        self.columnHeights[destColumn] = @(CGRectGetMaxY(attributes.frame));
        return attributes;
}
```

- 返回布局数组方法
这个方法调用频繁
所以计算cell的布局属性不在这里
这里把初始化方法中计算好的属性返回即可
```
//返回布局数组
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
        return self.attributesArray;
}
```

- collectionViewContentSize方法
根据最高的那一列
算出collectionView的ContentSize即可
```
- (CGSize)collectionViewContentSize {
        CGFloat maxColumnHeight = [self.columnHeights[0] doubleValue];
        for (NSInteger i = 1; i < self.columnCount; i++) {
                // 取得第i列的高度
                CGFloat columnHeight = [self.columnHeights[i] doubleValue];
                if (maxColumnHeight < columnHeight) {
                        maxColumnHeight = columnHeight;
                }
        }
        return CGSizeMake(0, maxColumnHeight + self.edgeInsets.bottom);
}
```
这样就算完成了
使用HXCollectionViewLayout的时候,把他导入项目,实现其代理方法即可.

