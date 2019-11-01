//
//  HGCategoryView.m
//  HGPersonalCenterExtend
//
//  Created by Arch on 2018/8/20.
//  Copyright © 2018年 mint_bin. All rights reserved.
//

#import "HGCategoryView.h"
#import "masonry.h"

#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define ONE_PIXEL (1 / [UIScreen mainScreen].scale)

const CGFloat HGCategoryViewDefaultHeight = 41;

@interface HGCategoryViewCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@end;

@implementation HGCategoryViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        [self.contentView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
    }
    return self;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

@end

@interface HGCategoryView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *vernier;
@property (nonatomic, strong) UIView *topBorder;
@property (nonatomic, strong) UIView *bottomBorder;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) BOOL selectedCellExist;
@property (nonatomic) CGFloat fontPointSizeScale;
@property (nonatomic) BOOL isFixedVernierWidth;
@property (nonatomic, strong) MASConstraint *vernierLeftConstraint;
@property (nonatomic, strong) MASConstraint *vernierWidthConstraint;
@end

@implementation HGCategoryView

#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        _selectedIndex = 0;
        _height = HGCategoryViewDefaultHeight;
        _vernierHeight = 1.8;
        _itemSpacing = 15;
        _leftAndRightMargin = 10;
        _titleNomalFont = [UIFont systemFontOfSize:16];
        _titleSelectedFont = [UIFont systemFontOfSize:17];
        _titleNormalColor = [UIColor grayColor];
        _titleSelectedColor = [UIColor redColor];
        _vernier.backgroundColor = self.titleSelectedColor;
        _animateDuration = 0.1;
        [self setupSubViews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.originalIndex > 0) {
        self.selectedIndex = self.originalIndex;
    } else {
        _selectedIndex = 0;
        [self updateVernierLocation];
    }
}

#pragma mark - Public Method
- (void)scrollToTargetIndex:(NSUInteger)targetIndex sourceIndex:(NSUInteger)sourceIndex percent:(CGFloat)percent {
    CGRect sourceVernierFrame = [self vernierFrameWithIndex:sourceIndex];
    CGRect targetVernierFrame = [self vernierFrameWithIndex:targetIndex];
    
    CGFloat tempVernierX = sourceVernierFrame.origin.x + (targetVernierFrame.origin.x - sourceVernierFrame.origin.x) * percent;
    CGFloat tempVernierWidth = sourceVernierFrame.size.width + (targetVernierFrame.size.width - sourceVernierFrame.size.width) * percent;
    
    [self.vernierLeftConstraint uninstall];
    [self.vernierWidthConstraint uninstall];
    [self.vernierWidthConstraint uninstall];
    [self.vernier mas_updateConstraints:^(MASConstraintMaker *make) {
        self.vernierLeftConstraint = make.left.mas_equalTo(tempVernierX);
        self.vernierWidthConstraint = make.width.mas_equalTo(tempVernierWidth);
        if (!self.isFixedVernierWidth) {
            self->_vernierWidth = tempVernierWidth;
        }
    }];
    
    if (percent > 0.5) {
        HGCategoryViewCell *sourceCell = [self getCell:sourceIndex];
        HGCategoryViewCell *targetCell = [self getCell:targetIndex];
        
        if (sourceCell) sourceCell.titleLabel.textColor = self.titleNormalColor;
        if (targetCell) targetCell.titleLabel.textColor = self.titleSelectedColor;
        
        CGFloat scale = self.titleSelectedFont.pointSize / self.titleNomalFont.pointSize;
        [UIView animateWithDuration:self.animateDuration animations:^{
            if (sourceCell) sourceCell.titleLabel.transform = CGAffineTransformIdentity;
            if (targetCell) targetCell.titleLabel.transform = CGAffineTransformMakeScale(scale, scale);
        } completion:nil];
        
        _selectedIndex = targetIndex;
    }
}

#pragma mark - Private Method
- (void)setupSubViews {
    [self addSubview:self.topBorder];
    [self addSubview:self.collectionView];
    [self.collectionView addSubview:self.vernier];
    [self addSubview:self.bottomBorder];
    
    [self.topBorder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self);
        make.height.mas_equalTo(ONE_PIXEL);
    }];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBorder.mas_bottom);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(self.height - ONE_PIXEL);
    }];
    [self.vernier mas_makeConstraints:^(MASConstraintMaker *make) {
        CGFloat collectionViewHeight = self.height - ONE_PIXEL * 2;
        make.top.mas_equalTo(collectionViewHeight - self.vernierHeight);
        make.height.mas_equalTo(self.vernierHeight);
    }];
    [self.bottomBorder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(ONE_PIXEL);
    }];
}

- (HGCategoryViewCell *)getCell:(NSUInteger)index {
    return (HGCategoryViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (void)layoutAndScrollToSelectedItem {    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
    if (self.selectedItemHelper) {
        self.selectedItemHelper(self.selectedIndex);
    }
    
    HGCategoryViewCell *selectedCell = [self getCell:self.selectedIndex];
    if (selectedCell) {
        self.selectedCellExist = YES;
        [self updateVernierLocation];
    } else {
        self.selectedCellExist = NO;
        //这种情况下updateUnderlineLocation将在self.collectionView滚动结束后执行（代理方法scrollViewDidEndScrollingAnimation）
    }
}

- (void)updateVernierLocation {
    [self.collectionView layoutIfNeeded];
    HGCategoryViewCell *cell = [self getCell:self.selectedIndex];
    
    [self.vernierLeftConstraint uninstall];
    [self.vernierWidthConstraint uninstall];
    [self.vernier mas_updateConstraints:^(MASConstraintMaker *make) {
        if (self.isFixedVernierWidth) {
            self.vernierLeftConstraint = make.left.equalTo(cell.titleLabel.mas_centerX).offset(-self.vernierWidth / 2);
            self.vernierWidthConstraint = make.width.mas_equalTo(self.vernierWidth);
        } else {
            self.vernierLeftConstraint = make.left.equalTo(cell.titleLabel);
            self.vernierWidthConstraint = make.width.equalTo(cell.titleLabel);
            self->_vernierWidth = cell.titleLabel.frame.size.width;
        }
    }];
    
    [UIView animateWithDuration:self.animateDuration animations:^{
        [self.collectionView layoutIfNeeded];
    }];
}

- (void)updateCollectionViewContentInset {
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView layoutIfNeeded];
    CGFloat width = self.collectionView.contentSize.width;
    CGFloat margin;
    if (width > SCREEN_WIDTH) {
        width = SCREEN_WIDTH;
        margin = 0;
    } else {
        margin = (SCREEN_WIDTH - width) / 2.0;
    }
    
    switch (self.alignment) {
        case HGCategoryViewAlignmentLeft:
            self.collectionView.contentInset = UIEdgeInsetsZero;
            break;
        case HGCategoryViewAlignmentCenter:
            self.collectionView.contentInset = UIEdgeInsetsMake(0, margin, 0, margin);
            break;
        case HGCategoryViewAlignmentRight:
            self.collectionView.contentInset = UIEdgeInsetsMake(0, margin * 2, 0, 0);
            break;
    }
}

- (CGFloat)getWidthWithContent:(NSString *)content {
    CGRect rect = [content boundingRectWithSize:CGSizeMake(MAXFLOAT, self.height - ONE_PIXEL)
                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     attributes:@{NSFontAttributeName:self.titleSelectedFont}
                                        context:nil
                   ];
    return ceilf(rect.size.width);
}

- (CGRect)vernierFrameWithIndex:(NSUInteger)index {
    HGCategoryViewCell *cell = [self getCell:index];
    CGRect titleLabelFrame = [cell convertRect:cell.titleLabel.frame toView:self.collectionView];
    if (self.isFixedVernierWidth) {
        return CGRectMake(titleLabelFrame.origin.x + (titleLabelFrame.size.width - self.vernierWidth) / 2,
                          self.collectionView.frame.size.height - self.vernierHeight,
                          self.vernierWidth,
                          self.vernierHeight);
    } else {
        return CGRectMake(titleLabelFrame.origin.x,
                          self.collectionView.frame.size.height - self.vernierHeight,
                          cell.titleLabel.frame.size.width,
                          self.vernierHeight);
    }
}

/// 仅点击item的时候调用
- (void)changeItemToTargetIndex:(NSUInteger)targetIndex {
    if (self.selectedIndex == targetIndex) {
        return;
    }
    
    HGCategoryViewCell *selectedCell = [self getCell:self.selectedIndex];
    HGCategoryViewCell *targetCell = [self getCell:targetIndex];
    
    if (selectedCell) selectedCell.titleLabel.textColor = self.titleNormalColor;
    if (targetCell) targetCell.titleLabel.textColor = self.titleSelectedColor;
    
    CGFloat scale = self.titleSelectedFont.pointSize / self.titleNomalFont.pointSize;
    [UIView animateWithDuration:self.animateDuration animations:^{
        if (selectedCell) selectedCell.titleLabel.transform = CGAffineTransformIdentity;
        if (targetCell) targetCell.titleLabel.transform = CGAffineTransformMakeScale(scale, scale);
    } completion:nil];
    
    self.selectedIndex = targetIndex;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = [self getWidthWithContent:self.titles[indexPath.row]];
    CGFloat height = self.height - ONE_PIXEL * 2;
    return CGSizeMake(self.itemWidth > 0 ? self.itemWidth : width, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.itemSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.itemSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, self.leftAndRightMargin, 0, self.leftAndRightMargin);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.titles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HGCategoryViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([HGCategoryViewCell class]) forIndexPath:indexPath];
    cell.titleLabel.text = self.titles[indexPath.row];
    cell.titleLabel.textColor = self.selectedIndex == indexPath.row ? self.titleSelectedColor : self.titleNormalColor;
    if (self.selectedIndex == indexPath.row) {
        cell.titleLabel.transform = CGAffineTransformMakeScale(self.fontPointSizeScale, self.fontPointSizeScale);
        cell.titleLabel.font = self.titleSelectedFont;
    } else {
        cell.titleLabel.transform = CGAffineTransformIdentity;
        cell.titleLabel.font = self.titleNomalFont;
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self changeItemToTargetIndex:indexPath.row];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (!self.selectedCellExist) {
        [self updateVernierLocation];
    }
}

#pragma mark - Setter
- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (self.titles.count == 0) {
        return;
    }
    if (selectedIndex >= self.titles.count) {
        _selectedIndex = self.titles.count - 1;
    } else {
        _selectedIndex = selectedIndex;
    }
    [self layoutAndScrollToSelectedItem];
}

- (void)setTitles:(NSArray<NSString *> *)titles {
    _titles = titles.copy;
    [self.collectionView reloadData];
    [self updateCollectionViewContentInset];
}

- (void)setAlignment:(HGCategoryViewAlignment)alignment {
    _alignment = alignment;
    [self updateCollectionViewContentInset];
}

- (void)setHeight:(CGFloat)categoryViewHeight {
    _height = categoryViewHeight;
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(self.height - ONE_PIXEL);
    }];
    [self.vernier mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.height - self.vernierHeight - ONE_PIXEL);
    }];
}

- (void)setUnderlineHeight:(CGFloat)underlineHeight {
    _vernierHeight = underlineHeight;
    [self.vernier mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.height - self.vernierHeight - ONE_PIXEL);
    }];
}

- (void)setItemWidth:(CGFloat)itemWidth {
    _itemWidth = itemWidth;
    [self updateCollectionViewContentInset];
}

- (void)setItemSpacing:(CGFloat)cellSpacing {
    _itemSpacing = cellSpacing;
    [self updateCollectionViewContentInset];
}

- (void)setLeftAndRightMargin:(CGFloat)leftAndRightMargin {
    _leftAndRightMargin = leftAndRightMargin;
    [self updateCollectionViewContentInset];
}

- (void)setIsEqualParts:(CGFloat)isEqualParts {
    _isEqualParts = isEqualParts;
    if (self.isEqualParts && self.titles.count > 0) {
        self.itemWidth = (SCREEN_WIDTH - self.leftAndRightMargin * 2 - self.itemSpacing * (self.titles.count - 1)) / self.titles.count;
    }
}

- (void)setVernierWidth:(CGFloat)vernierWidth {
    _vernierWidth = vernierWidth;
    self.isFixedVernierWidth = YES;
}

- (void)setTitleNomalFont:(UIFont *)titleNomalFont {
    _titleNomalFont = titleNomalFont;
    [self updateCollectionViewContentInset];
}

- (void)setTitleSelectedFont:(UIFont *)titleSelectedFont {
    _titleSelectedFont = titleSelectedFont;
    [self updateCollectionViewContentInset];
}

- (void)setTitleNormalColor:(UIColor *)titleNormalColor {
    _titleNormalColor = titleNormalColor;
    [self.collectionView reloadData];
}

- (void)setTitleSelectedColor:(UIColor *)titleSelectedColor {
    _titleSelectedColor = titleSelectedColor;
    [self.collectionView reloadData];
}

#pragma mark - Getter
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.bounces = NO;
        [_collectionView registerClass:[HGCategoryViewCell class] forCellWithReuseIdentifier:NSStringFromClass([HGCategoryViewCell class])];
    }
    return _collectionView;
}

- (UIView *)vernier {
    if (!_vernier) {
        _vernier = [[UIView alloc] init];
    }
    return _vernier;
}

- (UIView *)topBorder {
    if (!_topBorder) {
        _topBorder = [[UIView alloc] init];
        _topBorder.backgroundColor = [UIColor lightGrayColor];
    }
    return _topBorder;
}

- (UIView *)bottomBorder {
    if (!_bottomBorder) {
        _bottomBorder = [[UIView alloc] init];
        _bottomBorder.backgroundColor = [UIColor lightGrayColor];
    }
    return _bottomBorder;
}

- (CGFloat)fontPointSizeScale {
    return self.titleSelectedFont.pointSize / self.titleNomalFont.pointSize;
}

@end
