//
//  GLAssetPlaybackViewController.m
//  GLAssetGridViewController
//
//  Created by Yanci on 17/5/16.
//  Copyright © 2017年 Yanci. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>
#import "GLAssetPlaybackViewController.h"
#import "GLAssetPlayBackView.h"

@interface GLAssetPlaybackContainer : UIView
@end

@implementation GLAssetPlaybackContainer

@end

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;


@interface GLAssetPlaybackViewController ()

@end



@implementation GLAssetPlaybackViewController {
    BOOL _needsReload;
    BOOL _isFullScreen;
    BOOL _setupConstraints;
    BOOL _isStartPlay;
    struct {
    }_datasourceHas;
    
    struct{
    }_delegateHas;
}
@synthesize mPlayer, mPlayAsset, mPlaybackView,mPlayerItem;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
 
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


#pragma mark - life cycle
- (void)loadView {
    self.view = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.container];
    
    mPlaybackView = _container;
    [_container addSubview:self.toolbar];
    [_container addSubview:self.defaultImageView];
    [_container addSubview:self.startPlayBtn];
    [self.toolbar addSubview:self.playBtn];
    [self.toolbar addSubview:self.leftTimeLabel];
    [self.toolbar addSubview:self.currentTimeLabel];
    [self.toolbar addSubview:self.timeSlider];
    [self.toolbar addSubview:self.fullScreenBtn];
    
}

- (void)viewWillLayoutSubviews {
    [self _reloadDataIfNeed];
    [self _layoutSubviews];
}

- (void)dealloc {
    [self removePlayerTimeObserver];
    [self.mPlayer removeObserver:self forKeyPath:@"currentItem"];
    [self.mPlayer removeObserver:self forKeyPath:@"rate"];
    [mPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.mPlayer pause];
}



#pragma mark - datasource
#pragma mark - delegate
#pragma mark - user events
- (void)tapInView {
    if (_isStartPlay) {
        self.toolbar.hidden = !self.toolbar.hidden;
    }
}

- (void)play {
   
    if (!self.playBtn.selected) {
        NSLog(@"play");
        
        if (YES == seekToZeroBeforePlay)
        {
            seekToZeroBeforePlay = NO;
            [self.mPlayer seekToTime:kCMTimeZero];
        }
        [self.mPlayer play];
        [self.playBtn setSelected:YES];
    }
    else {
        NSLog(@"pause");
        
        [self.mPlayer pause];
        [self.playBtn setSelected:NO];
    }
    
   
}

- (void)fullScreen {
    // TODO: Add fullscreen
}

- (void)startPlay {
    NSLog(@"startPlay");
    NSArray *requestedKeys = @[@"playable"];
    [self prepareToPlayAsset:(AVURLAsset *)mPlayAsset withKeys:requestedKeys];
    _isStartPlay = YES;
    [self.view setNeedsLayout];
}

#pragma mark - movie controller methods 
- (void)initScrubberTimer {
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        CGFloat width = CGRectGetWidth([self.timeSlider bounds]);
        interval = 0.5f * duration / width;
    }
    
    /* Update the scrubber during normal playback. */
    __weak GLAssetPlaybackViewController *weakSelf = self;
    mTimeObserver = [self.mPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                               queue:NULL /* If you pass NULL, the main queue is used. */
                                                          usingBlock:^(CMTime time)
                     {
                         [weakSelf syncScrubber];
                     }];

}
- (void)syncScrubber {
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        self.timeSlider.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        float minValue = [self.timeSlider minimumValue];
        float maxValue = [self.timeSlider maximumValue];
        double time = CMTimeGetSeconds([self.mPlayer currentTime]);
        
        [self.timeSlider setValue:(maxValue - minValue) * time / duration + minValue];
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d",((int)time)/60, (int)((int)time%60)];
        self.leftTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d",((int)(duration - time))/60,((int)(duration - time)%60)];
    }
    
}
- (void)disableScrubber {
   self.timeSlider.enabled = NO;
}
- (void)disablePlayerButtons {
    self.playBtn.enabled = NO;
}
- (void)syncPlayPauseButtons{
    if ([self isPlaying])
    {
        self.playBtn.selected = YES;
    }
    else
    {
        self.playBtn.selected = NO;
    }
}

- (void)enableScrubber{
    self.timeSlider.enabled = YES;
}
- (void)enablePlayerButtons{
    self.playBtn.enabled = YES;
}
- (void)setViewDisplayName{}

#pragma mark - functions
- (void)commonInit {}

- (void)setDataSource:(id<GLAssetPlaybackViewControllerDataSource>)dataSource {
    
}

- (void)setDelegate:(id<GLAssetPlaybackViewControllerDelegate>)delegate {
    
}

- (void)reloadData {
  
}

- (void)_setNeedsReload {
    _needsReload = YES;
    [self.view setNeedsLayout];
}

- (void)_reloadDataIfNeed {
    if (_needsReload) {
        [self reloadData];
    }
}

- (void)_layoutSubviews {
    if (!_setupConstraints) {
        [self.container mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.view.mas_left).offset(10);
            make.right.mas_equalTo(self.view.mas_right).offset(-10);
            make.top.mas_equalTo(self.view.mas_top).offset(10);
            make.bottom.mas_equalTo(self.view.mas_bottom).offset(-10);
        }];
        
        [self.toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(_container.mas_bottom).offset(0);
            make.left.mas_equalTo(_container.mas_left).offset(0);
            make.right.mas_equalTo(_container.mas_right).offset(0);
            make.height.offset(44.0);
        }];
        
        [self.playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(_toolbar.mas_left).offset(10);
            make.width.offset(30);
            make.height.offset(30);
            make.centerY.mas_equalTo(_toolbar.mas_centerY).offset(0);
        }];

        [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.playBtn.mas_right).offset(10);
            make.centerY.mas_equalTo(_toolbar.mas_centerY).offset(0);
        }];

        [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(_toolbar.mas_right).offset(-10);
            make.width.offset(30);
            make.height.offset(30);
            make.centerY.mas_equalTo(_toolbar.mas_centerY).offset(0);
        }];
        
        [self.leftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.fullScreenBtn.mas_left).offset(-10);
            make.centerY.mas_equalTo(_toolbar.mas_centerY).offset(0);
        }];

        [self.timeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.currentTimeLabel.mas_right).offset(10);
            make.centerY.mas_equalTo(_toolbar.mas_centerY).offset(0);
            make.right.mas_equalTo(self.leftTimeLabel.mas_left).offset(-10);
            make.height.offset(30);
        }];
        
        [self.startPlayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(self.container).offset(0);
        }];
        
        [self.defaultImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self.container).offset(0);
        }];
        
        _setupConstraints = YES;
    }
    
    if (!_isStartPlay) {
        self.toolbar.hidden = YES;
        self.startPlayBtn.hidden = NO;
        self.defaultImageView.hidden = NO;
    }
    else {
        self.toolbar.hidden = NO;
        self.startPlayBtn.hidden = YES;
        self.defaultImageView.hidden = YES;
    }

}

- (void)setURL:(NSURL *)URL {
    if (mURL != URL) {
        mURL = [URL copy];
    }
}

- (void)setMPlayAsset:(AVAsset *)__mPlayAsset {
    /** If is equal url , just simple do nothing */
    if ([((AVURLAsset *)__mPlayAsset).URL.absoluteString isEqualToString:((AVURLAsset *)mPlayAsset).URL.absoluteString]) {
        return;
    }
    
    _isStartPlay = NO;
    mPlayAsset = __mPlayAsset;
    /** Resize video frame */
    CGSize videoSize = [self getPlayerItemVideoSize];
    
    [self.container mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
        make.width.offset(videoSize.width);
        make.height.offset(videoSize.height);
    }];
    
    /* TODO : Need to optimize */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *captureImage = [self getPlayerItemFirstImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.defaultImageView.image = captureImage;
        });
    });
    
    [self.view updateConstraints];
    [self.view setNeedsLayout];
}


- (CGSize)getPlayerItemVideoSize {
    AVAssetTrack *track = [[mPlayAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    CGSize size = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
    CGSize videoSize = CGSizeMake(fabs(size.width), fabs(size.height));
    CGSize actualSize = CGSizeMake([UIScreen mainScreen].bounds.size.width,
                                   [UIScreen mainScreen].bounds.size.width  / (videoSize.width / videoSize.height ) );

    return actualSize;
}

- (UIImage *)getPlayerItemFirstImage {
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:mPlayAsset];
    generator.appliesPreferredTrackTransform = YES;
    NSError *error = nil;
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0, 10000) actualTime:NULL error:&error];
    UIImage *image = [UIImage imageWithCGImage: img];
    return image;
}

- (void)stop {
    [self.mPlayer pause];
    [self.playBtn setSelected:NO];
}

#pragma mark - notification
#pragma mark - getter and setter
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [[UIButton alloc]init];
        [_playBtn setImage:[UIImage imageNamed:@"play_icon"]
                  forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage imageNamed:@"pause_icon"]
                  forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)startPlayBtn {
    if (!_startPlayBtn) {
        _startPlayBtn = [[UIButton alloc]init];
        [_startPlayBtn setImage:[UIImage imageNamed:@"play_icon"] forState:UIControlStateNormal];
        [_startPlayBtn addTarget:self action:@selector(startPlay) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startPlayBtn;
}

- (UIButton *)fullScreenBtn {
    if (!_fullScreenBtn) {
        _fullScreenBtn = [[UIButton alloc]init];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"movieFullscreen"]
                        forState:UIControlStateNormal];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"ft_video_icon_full"]
                        forState:UIControlStateSelected];
        [_fullScreenBtn addTarget:self action:@selector(fullScreen) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenBtn;
}

- (UISlider *)timeSlider {
    if (!_timeSlider) {
        _timeSlider = [[UISlider alloc]init];
        [_timeSlider setThumbImage:[UIImage imageNamed:@"xx_video_btn"] forState:UIControlStateNormal];
    }
    return _timeSlider;
}

- (UILabel *)currentTimeLabel {
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc]init];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.text = @"00:00";
        _currentTimeLabel.font = [UIFont systemFontOfSize:12.0];
    }
    return _currentTimeLabel;
}

- (UILabel *)leftTimeLabel {
    if (!_leftTimeLabel) {
        _leftTimeLabel = [[UILabel alloc]init];
        _leftTimeLabel.textColor = [UIColor whiteColor];
        _leftTimeLabel.text = @"00:00";
        _leftTimeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _leftTimeLabel;
}

- (GLAssetPlayBackView *)container {
    if (!_container) {
        _container = [[GLAssetPlayBackView alloc]init];
        _container.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapInView)];
        [_container addGestureRecognizer:tapGestureRecognizer];
    }
    return _container;
}

- (GLAssetPlaybackContainer*)toolbar {
    if (!_toolbar) {
        _toolbar = [[GLAssetPlaybackContainer alloc]init];
        _toolbar.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    }
    return _toolbar;
}

- (UIImageView *)defaultImageView {
    if (!_defaultImageView) {
        _defaultImageView = [[UIImageView alloc]init];
    }
    return _defaultImageView;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end


@implementation GLAssetPlaybackViewController (Player)


#pragma mark Player Item

- (BOOL)isPlaying
{
    return mRestoreAfterScrubbingRate != 0.f || [self.mPlayer rate] != 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    /* After the movie has played to its end time, seek back to time zero
     to play it again. */
    seekToZeroBeforePlay = YES;
}

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem.
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [self.mPlayer currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}


/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
    if (mTimeObserver)
    {
        [self.mPlayer removeTimeObserver:mTimeObserver];
        mTimeObserver = nil;
    }
}

#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 **
 **  1) values of asset keys did not load successfully,
 **  2) the asset keys did load successfully, but the asset is not
 **     playable
 **  3) the item did not become ready to play.
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}


#pragma mark Prepare to play asset, URL

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.mPlayerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.mPlayerItem removeObserver:self forKeyPath:@"status"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.mPlayerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.mPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.mPlayerItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.mPlayerItem];
    
    seekToZeroBeforePlay = NO;
    
    /* Create new player, if we don't already have one. */
    if (!self.mPlayer)
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.mPlayerItem]];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:@"currentItem"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
        

    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.mPlayerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur
         
         If needed, configure player item here (example: adding outputs, setting text style rules,
         selecting media options) before associating it with a player
         */
        [self.mPlayer replaceCurrentItemWithPlayerItem:self.mPlayerItem];
        
        [self syncPlayPauseButtons];
    }
    
    [self.timeSlider setValue:0.0];
    [self.mPlayer play];
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == AVPlayerDemoPlaybackViewControllerStatusObservationContext)
    {
        [self syncPlayPauseButtons];
        
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerItemStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                
                [self disableScrubber];
                [self disablePlayerButtons];
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [self initScrubberTimer];
                
                [self enableScrubber];
                [self enablePlayerButtons];
            }
                break;
                
            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == AVPlayerDemoPlaybackViewControllerRateObservationContext)
    {
        [self syncPlayPauseButtons];
    }
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
            [self disableScrubber];
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            [self.mPlaybackView setPlayer:mPlayer];
            
            [self setViewDisplayName];
            
            /* Specifies that the player should preserve the video’s aspect ratio and 
             fit the video within the layer’s bounds. */
            [self.mPlaybackView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            [self syncPlayPauseButtons];
        }
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}



@end

