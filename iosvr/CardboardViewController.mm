//
//  CardboardViewController.mm
//  iosvr
//

#import "CardboardViewController.h"

#include "Cardboard.h"
#include "Eye.h"
#include <hfgl/hfglDebugUtils.h>
#include "HeadTransform.h"
#include "DistortionRenderer.h"
#include "HeadTracker.h"
#include "HeadMountedDisplay.h"
#include "Viewport.h"

@interface CBDEye ()

@property (nonatomic) iosvr::Eye *eye;

- (instancetype)initWithEye:(iosvr::Eye *)eye;

@end


@implementation CBDEye

- (instancetype)init
{
    return [self initWithEye:0];
}

- (instancetype)initWithEye:(iosvr::Eye *)eye
{
    self = [super init];
    if (!self) { return nil; }
    
    _eye = eye;
    
    return self;
}

- (CBDEyeType)type
{
    CBDEyeType type = CBDEyeTypeMonocular;
    if (_eye->getType() == iosvr::Eye::EYE_LEFT)
    {
        type = CBDEyeTypeLeft;
    }
    else if (_eye->getType() == iosvr::Eye::EYE_RIGHT)
    {
        type = CBDEyeTypeRight;
    }
    return type;
}

- (GLKMatrix4)eyeViewMatrix
{
    if (_eye != 0)
    {
        return _eye->getEyeView();
    }
    return GLKMatrix4Identity;
}

- (GLKMatrix4)perspectiveMatrixWithZNear:(float)zNear zFar:(float)zFar
{
    if (_eye != 0)
    {
        return _eye->getPerspective(zNear, zFar);
    }
    return GLKMatrix4Identity;
}

@end


@interface CardboardViewController () <GLKViewControllerDelegate>
{
    iosvr::Cardboard* cardboard;
}

@property (nonatomic) NSRecursiveLock *glLock;

@property (nonatomic) CBDEye *leftEyeWrapper;
@property (nonatomic) CBDEye *rightEyeWrapper;

@end


@implementation CardboardViewController
@synthesize vrModeEnabled = _vrModeEnabled;
@synthesize distortionCorrectionEnabled = _distortionCorrectionEnabled;
@synthesize vignetteEnabled = _vignetteEnabled;
@synthesize chromaticAberrationCorrectionEnabled = _chromaticAberrationCorrectionEnabled;
@synthesize neckModelEnabled = _neckModelEnabled;
@synthesize restoreGLStateEnabled = _restoreGLStateEnabled;

@dynamic view;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self doInit];
        return self;
    }
    
    return nil;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self doInit];
        return self;
    }
    
    return nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self doInit];
        return self;
    }
    
    return nil;
}

- (void)doInit
{
    // Do not allow the display to go into sleep
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.delegate = self;
    
    cardboard = new iosvr::Cardboard();
    
    _vrModeEnabled = cardboard->getVrModeEnabled();
    _distortionCorrectionEnabled = cardboard->getDistortionCorrectionEnabled();
    _vignetteEnabled = cardboard->getDistortionRenderer()->getVignetteEnabled();
    _chromaticAberrationCorrectionEnabled = cardboard->getDistortionRenderer()->getChromaticAberrationEnabled();
    _restoreGLStateEnabled = cardboard->getDistortionRenderer()->getRestoreGLStateEnabled();
    _neckModelEnabled = cardboard->getNeckModelEnabled();
    
    self.leftEyeWrapper = [CBDEye new];
    self.rightEyeWrapper = [CBDEye new];
    
    self.glLock = [NSRecursiveLock new];
    
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(magneticTriggerPressed:)
                                                     name:@"CBDTriggerPressedNotification"
                                                   object:nil];
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 60;
    
    self.view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!self.view.context)
    {
        NSLog(@"Failed to create OpenGL ES 3.0 context. Trying 2.0");
        self.view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
    if (!self.view.context)
    {
        NSLog(@"Failed to create OpenGL ES 2.0 context");
    }
    self.view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    [self.stereoRendererDelegate setupRendererWithView:self.view];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.stereoRendererDelegate shutdownRendererWithView:self.view];

    if (cardboard != 0) { delete cardboard; }
}

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
        if ([self.stereoRendererDelegate respondsToSelector:@selector(magneticTriggerPressed)])
        {
            [self.stereoRendererDelegate magneticTriggerPressed];
        }
    });
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause
{
    cardboard->pause(pause);
}

- (void)glkViewControllerUpdate:(GLKViewController *)controller
{
    
    if (self.paused)
    {
        return;
    }
    
    cardboard->update();
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if (self.paused || !cardboard->areFrameParamentersReady())
    {
        return;
    }

#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif

    BOOL lockAcquired = [_glLock tryLock];
    if (!lockAcquired) { return; }
    
    if (_vrModeEnabled)
    {
        if (_distortionCorrectionEnabled)
        {
            cardboard->getDistortionRenderer()->beforeDrawFrame();

            [self drawFrameWithHeadTransform:cardboard->getHeadTransform()
                                     leftEye:cardboard->getLeftEye()
                                    rightEye:cardboard->getRightEye()];
            
#if defined(DEBUG)
            hfgl::CheckGlErrors();
#endif

            [self.view bindDrawable];
            cardboard->getDistortionRenderer()->afterDrawFrame();
            
#if defined(DEBUG)
            hfgl::CheckGlErrors();
#endif
        }
        else
        {
            [self drawFrameWithHeadTransform:cardboard->getHeadTransform()
                                     leftEye:cardboard->getLeftEye()
                                    rightEye:cardboard->getRightEye()];
        }
    }
    else
    {
        [self drawFrameWithHeadTransform:cardboard->getHeadTransform()
                                 leftEye:cardboard->getMonocularEye()
                                rightEye:0];
    }
    
    [self finishFrameWithViewPort:cardboard->getMonocularEye()->getViewport()];

#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif

    [_glLock unlock];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateRenderViewSize:self.view.bounds.size];
}

#pragma mark Stereo renderer methods

- (void)updateRenderViewSize:(CGSize)size
{
    if (self.vrModeEnabled)
    {
        [self.stereoRendererDelegate renderViewDidChangeSize:CGSizeMake(size.width / 2, size.height)];
    }
    else
    {
        [self.stereoRendererDelegate renderViewDidChangeSize:CGSizeMake(size.width, size.height)];
    }
}

- (void)drawFrameWithHeadTransform:(iosvr::HeadTransform *)headTransform
                           leftEye:(iosvr::Eye *)leftEye
                          rightEye:(iosvr::Eye *)rightEye
{
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
    
    [self.stereoRendererDelegate prepareNewFrameWithHeadViewMatrix:headTransform->getHeadView()];
    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
    
    glEnable(GL_SCISSOR_TEST);
    leftEye->getViewport()->setGLViewport();
    leftEye->getViewport()->setGLScissor();
    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
    
    _leftEyeWrapper.eye = leftEye;
    [self.stereoRendererDelegate drawEyeWithEye:_leftEyeWrapper];
    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
    
    if (rightEye == 0) { return; }
    
    rightEye->getViewport()->setGLViewport();
    rightEye->getViewport()->setGLScissor();
    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
    
    _rightEyeWrapper.eye = rightEye;
    [self.stereoRendererDelegate drawEyeWithEye:_rightEyeWrapper];
    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
}

- (void)finishFrameWithViewPort:(iosvr::Viewport *)viewport
{
    viewport->setGLViewport();
    viewport->setGLScissor();
    [self.stereoRendererDelegate finishFrameWithViewportRect:[self ViewportToCGRect:viewport]];
}


- (CGRect) ViewportToCGRect:(iosvr::Viewport*)v
{
    return CGRectMake(v->x, v->y, v->width, v->height);
}

@end
