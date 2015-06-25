//
//  TreasureViewController.m
//  CardboardSDK-iOS
//
//

#import "PanoPlayerViewController.h"
#import "PanoPlayerRender.h"

# define ONE_FRAME_DURATION 0.03

static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface PanoPlayerViewController() <CardboardStereoRendererDelegate>
{
    AVPlayer *_player;
    dispatch_queue_t _myVideoOutputQueue;
    id _notificationToken;
    id _timeObserver;
}

@property (nonatomic) PanoPlayerRender *renderer;

@property AVPlayerItemVideoOutput *videoOutput;
@property CADisplayLink *displayLink;

- (void)displayLinkCallback:(CADisplayLink *)sender;

@end


@implementation PanoPlayerViewController

- (instancetype)init
{
    self = [super init];
    if (!self) {return nil; }
    
    self.stereoRendererDelegate = self;
    
    return self;
}

- (void)setupRendererWithView:(GLKView *)glView
{
    self.renderer = [PanoPlayerRender new];
    [self.renderer setupRendererWithView:glView];
    CGRect eyeFrame = self.view.bounds;
    eyeFrame.size.height = self.view.bounds.size.height;
    eyeFrame.size.width = self.view.bounds.size.width / 2;
    eyeFrame.origin.y = eyeFrame.size.height;
    
    _player = [[AVPlayer alloc] init];
    [self addTimeObserverToPlayer];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
    [[self displayLink] addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[self displayLink] setPaused:YES];
    
    NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    _myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    [[self videoOutput] setDelegate:self queue:_myVideoOutputQueue];
    
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:AVPlayerItemStatusContext];
    [self addTimeObserverToPlayer];
    
    [[_player currentItem] removeOutput:self.videoOutput];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"balloons2" withExtension:@"mp4"];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    AVAsset *asset = [item asset];
    
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        
        if ([asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded) {
            NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if ([tracks count] > 0) {
                // Choose the first video track.
                AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
                [videoTrack loadValuesAsynchronouslyForKeys:@[@"preferredTransform"] completionHandler:^{
                    
                    if ([videoTrack statusOfValueForKey:@"preferredTransform" error:nil] == AVKeyValueStatusLoaded) {
                        //CGAffineTransform preferredTransform = [videoTrack preferredTransform];
                        
                        /*
                         The orientation of the camera while recording affects the orientation of the images received from an AVPlayerItemVideoOutput. Here we compute a rotation that is used to correctly orientate the video.
                         */
                        //self.playerView.preferredRotation = -1 * atan2(preferredTransform.b, preferredTransform.a);
                        
                        [self addDidPlayToEndTimeNotificationForPlayerItem:item];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [item addOutput:self.videoOutput];
                            [_player replaceCurrentItemWithPlayerItem:item];
                            [self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
                            [_player play];
                        });
                        
                    }
                    
                }];
            }
        }
        
    }];
    
    [self setVrModeEnabled:YES];
    
}

- (void)stopLoadingAnimationAndHandleError:(NSError *)error
{
    if (error) {
        NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Cancel button title for animation load error");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVPlayerItemStatusContext) {
        AVPlayerStatus status = (AVPlayerStatus)[change[NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerItemStatusUnknown:
                break;
            case AVPlayerItemStatusReadyToPlay:
                //self.playerView.presentationRect = [[_player currentItem] presentationSize];
                break;
            case AVPlayerItemStatusFailed:
                [self stopLoadingAnimationAndHandleError:[[_player currentItem] error]];
                break;
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)addDidPlayToEndTimeNotificationForPlayerItem:(AVPlayerItem *)item
{
    if (_notificationToken)
        _notificationToken = nil;
    
    /*
     Setting actionAtItemEnd to None prevents the movie from getting paused at item end. A very simplistic, and not gapless, looped playback.
     */
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    _notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:item queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        // Simple item playback rewind.
        [[_player currentItem] seekToTime:kCMTimeZero];
    }];
}

- (void)syncTimeLabel
{
    double seconds = CMTimeGetSeconds([_player currentTime]);
    if (!isfinite(seconds)) {
        seconds = 0;
    }
    
    int secondsInt = round(seconds);
    int minutes = secondsInt/60;
    secondsInt -= minutes*60;
}

- (void)addTimeObserverToPlayer
{
    if (_timeObserver)
        return;

    __weak PanoPlayerViewController* weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 10) queue:dispatch_get_main_queue() usingBlock:
                     ^(CMTime time) {
                         [weakSelf syncTimeLabel];
                     }];
}

- (void)removeTimeObserverFromPlayer
{
    if (_timeObserver)
    {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

#pragma mark - CADisplayLink Callback

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    /*
     The callback gets called once every Vsync.
     Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
     This pixel buffer can then be processed and later rendered on screen.
     */
//    CMTime outputItemTime = kCMTimeInvalid;
//    
//    // Calculate the nextVsync time which is when the screen will be refreshed next.
//    CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
//    
//    outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
//    
//    _player.currentTime
//    
//    if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
//        CVPixelBufferRef pixelBuffer = NULL;
//        pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
//        
//        [[self renderer] displayPixelBuffer:pixelBuffer];
//    }
}

#pragma mark - AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    // Restart display link.
    [[self displayLink] setPaused:NO];
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:AVPlayerItemStatusContext];
    [self removeTimeObserverFromPlayer];
    
    if (_notificationToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:_notificationToken name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
        _notificationToken = nil;
    }
    
    [self.renderer shutdownRendererWithView:glView];
}

- (void)renderViewDidChangeSize:(CGSize)size
{
    [self.renderer renderViewDidChangeSize:size];
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
    
    //self.timeSinceLastDraw
    
    CMTime outputItemTime = _player.currentTime;
    
    if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
        CVPixelBufferRef pixelBuffer = NULL;
        pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        
        [[self renderer] displayPixelBuffer:pixelBuffer];
    }
    
    [self.renderer prepareNewFrameWithHeadViewMatrix:headViewMatrix];
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
    [self.renderer drawEyeWithEye:eye];
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
    [self.renderer finishFrameWithViewportRect:viewPort];
}

- (void)magneticTriggerPressed
{

}


@end
