//
//  GLAssetCollectionViewCell.m
//  GLAssetGridViewController
//
//  Created by Yanci on 17/5/18.
//  Copyright © 2017年 Yanci. All rights reserved.
//

#import "GLAssetCollectionViewCell.h"
#import "GLAssetPlaybackViewController.h"

@interface GLAssetCollectionViewCell()
@property (nonatomic,strong)GLAssetPlaybackViewController *playbackViewController;
@end

@implementation GLAssetCollectionViewCell {
    NSURL *_videoUrl;
    AVPlayerItem *_playerItem;
}
- (void)layoutSubviews {
    self.imageView.frame = self.contentView.bounds;
    self.playbackViewController.view.frame = self.contentView.bounds;
    [super layoutSubviews];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc]init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

- (GLAssetPlaybackViewController *)playbackViewController {
    if (!_playbackViewController) {
        _playbackViewController = [[GLAssetPlaybackViewController alloc]init];
        [self.contentView addSubview:_playbackViewController.view];
    }
    return _playbackViewController;
}

//- (void)setVideoUrl:(NSURL *)videoUrl {
//    _videoUrl = videoUrl;
//    [self.playbackViewController setURL:_videoUrl];
//}


- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    _playerItem = playerItem;
    [self.playbackViewController setPlayerItem:_playerItem];
}

- (void)setCellType:(AssetCollectionViewCellType)cellType {
    _cellType = cellType;
    if (_cellType == AssetCollectionViewCellType_Vid) {
        self.imageView.hidden = YES;
        self.playbackViewController.view.hidden = NO;
    }
    else if(_cellType == AssetCollectionViewCellType_Pic) {
        self.imageView.hidden = NO;
        self.playbackViewController.view.hidden = YES;
    }
 }

@end
