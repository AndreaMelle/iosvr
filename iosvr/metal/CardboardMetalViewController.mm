//
//  CardboardMetalViewController.m
//  iosvr
//
//  Created by Andrea Melle on 24/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "CardboardMetalViewController.h"
#import "CardboardMetalView.h"
#import "CardboardMetalRenderer.h"
#import "Cardboard.h"
#include "HeadTransform.h"
#include "DistortionRenderer.h"
#include "HeadTracker.h"
#include "HeadMountedDisplay.h"
#include "Viewport.h"
#include "Eye.h"
#import <QuartzCore/CAMetalLayer.h>

@implementation CardboardMetalViewController
{
@private
    CADisplayLink *_displayLink;
    BOOL _firstDrawOccurrence;
    
    CFTimeInterval _timeSinceLastDrawPreviousTime;
    
    BOOL _loopPaused;
    iosvr::Cardboard* cardboard;
}

@synthesize vrModeEnabled = _vrModeEnabled;
@synthesize distortionCorrectionEnabled = _distortionCorrectionEnabled;
@synthesize vignetteEnabled = _vignetteEnabled;
@synthesize chromaticAberrationCorrectionEnabled = _chromaticAberrationCorrectionEnabled;
@synthesize neckModelEnabled = _neckModelEnabled;
@synthesize restoreGLStateEnabled = _restoreGLStateEnabled;

- (void)initCommon
{    
    //  Register notifications to start/stop drawing as this app moves into the background
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didEnterBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willEnterForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    
    _interval = 1;
    
    // Do not allow the display to go into sleep
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    //self.delegate = self;
    
    cardboard = new iosvr::Cardboard();
    
    _vrModeEnabled = cardboard->getVrModeEnabled();
    _distortionCorrectionEnabled = cardboard->getDistortionCorrectionEnabled();
    _vignetteEnabled = cardboard->getDistortionRenderer()->getVignetteEnabled();
    _chromaticAberrationCorrectionEnabled = cardboard->getDistortionRenderer()->getChromaticAberrationEnabled();
    _restoreGLStateEnabled = cardboard->getDistortionRenderer()->getRestoreGLStateEnabled();
    _neckModelEnabled = cardboard->getNeckModelEnabled();
    
    //self.glLock = [NSRecursiveLock new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(magneticTriggerPressed:)
                                                 name:@"CBDTriggerPressedNotification"
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationDidEnterBackgroundNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationWillEnterForegroundNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"CBDTriggerPressedNotification"
                                                  object: nil];
    
    if(_displayLink)
    {
        [self stopMainLoop];
    }
    
    if (cardboard != 0) { delete cardboard; }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CardboardMetalView *renderView = (CardboardMetalView*)self.view;
    renderView.cardboard = cardboard;
    renderView.delegate = [self.delegate viewDelegate];
    
    // the render will setup assets now
    [renderView.delegate setup:renderView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startMainLoop];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopMainLoop];
}

// TODO: should be in the view - to notify the VR renderer that we switch to / from VR
// do not confuse with CardboardMetalView scale factor, which is related to the actual device screen size
// not the texture we are rendering to for VR!!

//- (void)viewDidLayoutSubviews
//{
//    [super viewDidLayoutSubviews];
//    [self updateRenderViewSize:self.view.bounds.size];
//}

//- (void)updateRenderViewSize:(CGSize)size
//{
//    if (self.vrModeEnabled)
//    {
//        [self.stereoRendererDelegate renderViewDidChangeSize:CGSizeMake(size.width / 2, size.height)];
//    }
//    else
//    {
//        [self.stereoRendererDelegate renderViewDidChangeSize:CGSizeMake(size.width, size.height)];
//    }
//}

- (void)startMainLoop
{
    _displayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(loop)];
    _displayLink.frameInterval = _interval;
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopMainLoop
{
    if(_displayLink)
    {
        [_displayLink invalidate];
    }
}

- (void)loop
{
    //update
    cardboard->update();
    [_delegate update:self];
    
    //update time keepers
    if(!_firstDrawOccurrence)
    {
        _timeSinceLastDraw             = 0.0;
        _timeSinceLastDrawPreviousTime = CACurrentMediaTime();
        _firstDrawOccurrence              = YES;
    }
    else
    {
        CFTimeInterval currentTime = CACurrentMediaTime();
        _timeSinceLastDraw = currentTime - _timeSinceLastDrawPreviousTime;
        _timeSinceLastDrawPreviousTime = currentTime;
    }
    
    // display (render)
    assert([self.view isKindOfClass:[CardboardMetalView class]]);
    
    // call the display method directly on the render view (setNeedsDisplay: has been disabled in the renderview by default)
    [(CardboardMetalView*)self.view display];
}

- (void)setPaused:(BOOL)pause
{
    if (_loopPaused == pause)
    {
        return;
    }
    
    if(_displayLink)
    {
        [_delegate viewController:self willPause:pause];
        
        _loopPaused = pause;
        _displayLink.paused = pause;
        cardboard->pause(pause);
        
        if(pause)
        {
            [(CardboardMetalView*)self.view releaseTextures];
        }
    }
}

- (BOOL)isPaused
{
    return _loopPaused;
}

#pragma mark -
#pragma VR specific setters / getters

- (BOOL) vrModeEnabled
{
    _vrModeEnabled = cardboard->getVrModeEnabled();
    return _vrModeEnabled;
}

- (void) setVrModeEnabled:(BOOL)enabled
{
    cardboard->setVrModeEnabled(enabled);
    _vrModeEnabled = cardboard->getVrModeEnabled();
}

- (BOOL) distortionCorrectionEnabled
{
    _distortionCorrectionEnabled = cardboard->getDistortionCorrectionEnabled();
    return _distortionCorrectionEnabled;
}

- (void) setDistortionCorrectionEnabled:(BOOL)enabled
{
    cardboard->setDistortionCorrectionEnabled(enabled);
    _distortionCorrectionEnabled = cardboard->getDistortionCorrectionEnabled();
}

- (BOOL)vignetteEnabled
{
    _vignetteEnabled = cardboard->getDistortionRenderer()->getVignetteEnabled();
    return _vignetteEnabled;
}

- (void)setVignetteEnabled:(BOOL)vignetteEnabled
{
    cardboard->getDistortionRenderer()->setVignetteEnabled(vignetteEnabled);
    _vignetteEnabled = cardboard->getDistortionRenderer()->getVignetteEnabled();
}

- (BOOL)chromaticAberrationCorrectionEnabled
{
    _chromaticAberrationCorrectionEnabled = cardboard->getDistortionRenderer()->getChromaticAberrationEnabled();
    return _chromaticAberrationCorrectionEnabled;
}

- (void)setChromaticAberrationCorrectionEnabled:(BOOL)chromaticAberrationCorrectionEnabled
{
    cardboard->getDistortionRenderer()->setChromaticAberrationEnabled(chromaticAberrationCorrectionEnabled);
    _chromaticAberrationCorrectionEnabled = cardboard->getDistortionRenderer()->getChromaticAberrationEnabled();
}

- (BOOL)restoreGLStateEnabled
{
    _restoreGLStateEnabled = cardboard->getDistortionRenderer()->getRestoreGLStateEnabled();
    return _restoreGLStateEnabled;
}

- (void)setRestoreGLStateEnabled:(BOOL)restoreGLStateEnabled
{
    cardboard->getDistortionRenderer()->setRestoreGLStateEnabled(restoreGLStateEnabled);
    _restoreGLStateEnabled = cardboard->getDistortionRenderer()->getRestoreGLStateEnabled();
}

- (BOOL)neckModelEnabled
{
    _neckModelEnabled = cardboard->getNeckModelEnabled();
    return _neckModelEnabled;
}

- (void)setNeckModelEnabled:(BOOL)neckModelEnabled
{
    cardboard->setNeckModelEnabled(neckModelEnabled);
    _neckModelEnabled = cardboard->getNeckModelEnabled();
}

- (void)magneticTriggerPressed:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(magneticTriggerPressed)])
        {
            [self.delegate magneticTriggerPressed];
        }
    });
}

#pragma mark -
#pragma boilerplate


- (void)didEnterBackground:(NSNotification*)notification
{
    [self setPaused:YES];
}

- (void)willEnterForeground:(NSNotification*)notification
{
    [self setPaused:NO];
}

- (id)init
{
    self = [super init];
    
    if(self)
    {
        [self initCommon];
    }
    return self;
}

// called when loaded from nib
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    
    if(self)
    {
        [self initCommon];
    }
    
    return self;
}

// called when loaded from storyboard
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if(self)
    {
        [self initCommon];
    }
    
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
