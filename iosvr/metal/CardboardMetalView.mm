//
//  CardboardMetalView.m
//  iosvr
//
//  Created by Andrea Melle on 24/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "CardboardMetalView.h"
#import "CardboardMetalRenderer.h"
#import "DistortionRenderer.h"
#import "Eye.h"
#import "Viewport.h"
#import "CMTransforms.h"

@implementation CardboardMetalView
{
@private
    __weak CAMetalLayer *_metalLayer;
    
    BOOL _layerSizeDidUpdate;
    
    id <MTLTexture>  _depthTex;
    id <MTLTexture>  _stencilTex;
    id <MTLTexture>  _msaaTex;
    
    CBMetalEye *leftEyeWrapper;
    CBMetalEye *rightEyeWrapper;
}
@synthesize currentDrawable = _currentDrawable;
@synthesize renderPassDescriptor = _renderPassDescriptor;

+ (Class)layerClass
{
    return [CAMetalLayer class];
}

- (void)initCommon
{
    self.opaque          = YES;
    self.backgroundColor = nil;
    
    _metalLayer = (CAMetalLayer *)self.layer;
    
    _device = MTLCreateSystemDefaultDevice();
    
    _metalLayer.device          = _device;
    _metalLayer.pixelFormat     = MTLPixelFormatBGRA8Unorm;
    
    // this is the default but if we wanted to perform compute on the final rendering layer we could set this to no
    _metalLayer.framebufferOnly = YES;
    
    leftEyeWrapper = [CBMetalEye new];
    rightEyeWrapper = [CBMetalEye new];
    
    _commandQueue = [_device newCommandQueue];
    
}

- (void)setupRenderPassDescriptorForTexture:(id<MTLTexture>)texture
{
    // create lazily
    if (_renderPassDescriptor == nil)
        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    // create a color attachment every frame since we have to recreate the texture every frame
    MTLRenderPassColorAttachmentDescriptor *colorAttachment = _renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture = texture;
    
    // make sure to clear every frame for best performance
    colorAttachment.loadAction = MTLLoadActionClear;
    colorAttachment.clearColor = MTLClearColorMake(0.65f, 0.65f, 0.65f, 1.0f);
    
    // if sample count is greater than 1, render into using MSAA, then resolve into our color texture
    if(_sampleCount > 1)
    {
        BOOL doUpdate =     (_msaaTex.width != texture.width)
                            || (_msaaTex.height != texture.height)
                            || (_msaaTex.sampleCount != _sampleCount);
        
        if (!_msaaTex || (_msaaTex && doUpdate))
        {
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:texture.width height:texture.height mipmapped:NO];
            
            desc.textureType = MTLTextureType2DMultisample;
            desc.sampleCount = _sampleCount;
        }
        
        // When multisampling, perform rendering to _msaaTex, then resolve
        // to 'texture' at the end of the scene
        colorAttachment.texture = _msaaTex;
        colorAttachment.resolveTexture = texture;
        colorAttachment.storeAction = MTLStoreActionMultisampleResolve;
    }
    else
    {
        // store only attachments that will be presented to the screen, as in this case
        colorAttachment.storeAction = MTLStoreActionStore;
    }
    
    // Now create the depth and stencil attachments
    if(_depthPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate =     ( _depthTex.width       != texture.width  )
        ||  ( _depthTex.height      != texture.height )
        ||  ( _depthTex.sampleCount != _sampleCount   );
        
        if(!_depthTex || doUpdate)
        {
            //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
            //  Then allocate one of the proper size
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _depthPixelFormat
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            
            _depthTex = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassDepthAttachmentDescriptor *depthAttachment = _renderPassDescriptor.depthAttachment;
            depthAttachment.texture = _depthTex;
            depthAttachment.loadAction = MTLLoadActionClear;
            depthAttachment.storeAction = MTLStoreActionDontCare;
            depthAttachment.clearDepth = 1.0;
        }
    }
    
    if(_stencilPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate  =    ( _stencilTex.width       != texture.width  )
        ||  ( _stencilTex.height      != texture.height )
        ||  ( _stencilTex.sampleCount != _sampleCount   );
        
        if(!_stencilTex || doUpdate)
        {
            //  If we need a stencil texture and don't have one, or if the depth texture we have is the wrong size
            //  Then allocate one of the proper size
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _stencilPixelFormat
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            
            _stencilTex = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassStencilAttachmentDescriptor* stencilAttachment = _renderPassDescriptor.stencilAttachment;
            stencilAttachment.texture = _stencilTex;
            stencilAttachment.loadAction = MTLLoadActionClear;
            stencilAttachment.storeAction = MTLStoreActionDontCare;
            stencilAttachment.clearStencil = 0;
        }
    }
    
}

- (MTLRenderPassDescriptor*)renderPassDescriptor
{
    id <CAMetalDrawable> drawable = self.currentDrawable;
    if(!drawable)
    {
        NSLog(@">> ERROR: Failed to get a drawable!");
        _renderPassDescriptor = nil;
    }
    else
    {
        [self setupRenderPassDescriptorForTexture:drawable.texture];
    }
    
    return _renderPassDescriptor;
}

- (id<CAMetalDrawable>)currentDrawable
{
    if (_currentDrawable == nil)
        _currentDrawable = [_metalLayer nextDrawable];
    
    return _currentDrawable;
}

- (void)display
{
    if (!self.cardboard->areFrameParamentersReady())
    {
        return;
    }
    
    //BOOL lockAcquired = [_glLock tryLock];
    //if (!lockAcquired) { return; }
    
    // Create autorelease pool per frame to avoid possible deadlock situations
    // because there are 3 CAMetalDrawables sitting in an autorelease pool.
    @autoreleasepool
    {
        if (_layerSizeDidUpdate)
        {
            // set the metal layer to the drawable size in case orientation or size changes
            CGSize drawableSize = self.bounds.size;
            drawableSize.width  *= self.contentScaleFactor;
            drawableSize.height *= self.contentScaleFactor;
            
            _metalLayer.drawableSize = drawableSize;
            
            // renderer delegate method so renderer can resize anything if needed
            [_delegate reshape:self];
            
            _layerSizeDidUpdate = NO;
        }
        
        id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
        
        if (self.renderPassDescriptor)
        {
            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:self.renderPassDescriptor];
            [renderEncoder pushDebugGroup:@"CardboardVR"];
            
            if (_cardboard->getVrModeEnabled())
            {
                [self drawFrameWithHeadTransform:_cardboard->getHeadTransform()
                                         leftEye:_cardboard->getLeftEye()
                                        rightEye:_cardboard->getRightEye()
                                   renderEncoder:renderEncoder];
            }
            else
            {
                [self drawFrameWithHeadTransform:_cardboard->getHeadTransform()
                                         leftEye:_cardboard->getMonocularEye()
                                        rightEye:0
                                   renderEncoder:renderEncoder];
            }
            
            
            
            [self finishFrameWithViewPort:_cardboard->getMonocularEye()->getViewport() renderEncoder:renderEncoder];
            
            [renderEncoder endEncoding];
            [renderEncoder popDebugGroup];
            
            // schedule a present once rendering to the framebuffer is complete
            [commandBuffer presentDrawable:self.currentDrawable];
        }
        
        [commandBuffer commit];
        
        
//        if (_cardboard->getVrModeEnabled())
//        {
//            if (_cardboard->getDistortionCorrectionEnabled())
//            {
//                _cardboard->getDistortionRenderer()->beforeDrawFrame();
//    
//                [self drawFrameWithHeadTransform:_cardboard->getHeadTransform()
//                                         leftEye:_cardboard->getLeftEye()
//                                        rightEye:_cardboard->getRightEye()];
//    
//
//    
//                //[self.view bindDrawable];
//                _cardboard->getDistortionRenderer()->afterDrawFrame();
//    
//
//            }
//            else
//            {
//                [self drawFrameWithHeadTransform:_cardboard->getHeadTransform()
//                                         leftEye:_cardboard->getLeftEye()
//                                        rightEye:_cardboard->getRightEye()];
//            }
//        }
//        else
//        {
//            [self drawFrameWithHeadTransform:_cardboard->getHeadTransform()
//                                     leftEye:_cardboard->getMonocularEye()
//                                    rightEye:0];
//        }
        
        //[self finishFrameWithViewPort:_cardboard->getMonocularEye()->getViewport()];
        
        //[self.delegate render:self];
        
        // There should be no strong references to this object outside of this view class
        _currentDrawable = nil;
    }
    
    //[_glLock unlock];
}

- (void)drawFrameWithHeadTransform:(iosvr::HeadTransform *)headTransform
                           leftEye:(iosvr::Eye *)leftEye
                          rightEye:(iosvr::Eye *)rightEye
                     renderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
    //[self.delegate prepareNewFrameWithHeadViewMatrix:headTransform->getHeadView()];
    [self.delegate prepareNewFrameWithHeadViewMatrix:CM::identity()];

    [renderEncoder setViewport:[self ViewportToMTL:leftEye->getViewport()]];
    [renderEncoder setScissorRect:[self ScissorToMTL:leftEye->getViewport()]];
    
    leftEyeWrapper.eye = leftEye;
    [self.delegate drawEyeWithEye:leftEyeWrapper renderEncoder:renderEncoder];
    
    if (rightEye != 0)
    {
        [renderEncoder setViewport:[self ViewportToMTL:rightEye->getViewport()]];
        [renderEncoder setScissorRect:[self ScissorToMTL:rightEye->getViewport()]];
        
        rightEyeWrapper.eye = rightEye;
        [self.delegate drawEyeWithEye:rightEyeWrapper renderEncoder:renderEncoder];
    }
    
}

- (void)finishFrameWithViewPort:(iosvr::Viewport *)viewport
                  renderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder setViewport:[self ViewportToMTL:viewport]];
    [renderEncoder setScissorRect:[self ScissorToMTL:viewport]];
    
    [self.delegate finishFrameWithViewportRect:[self ViewportToCGRect:viewport] renderEncoder:renderEncoder];
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:contentScaleFactor];
    
    _layerSizeDidUpdate = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _layerSizeDidUpdate = YES;
}

- (void)releaseTextures
{
    _depthTex   = nil;
    _stencilTex = nil;
    _msaaTex    = nil;
}

- (void)didMoveToWindow
{
    self.contentScaleFactor = self.window.screen.nativeScale;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        [self initCommon];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if(self)
    {
        [self initCommon];
    }
    return self;
}

- (CGRect) ViewportToCGRect:(iosvr::Viewport*)v
{
    return CGRectMake(v->x, v->y, v->width, v->height);
}

- (MTLViewport)ViewportToMTL:(iosvr::Viewport*)v
{
    MTLViewport viewport;
    viewport.originX = v->x;
    viewport.originY = v->y;
    viewport.width = v->width;
    viewport.height = v->height;
    viewport.znear = 0.0f;
    viewport.zfar = 1.0f;
    
    return viewport;
}

- (MTLScissorRect)ScissorToMTL:(iosvr::Viewport*)v
{
    MTLScissorRect rect;
    rect.x = v->x;
    rect.y = v->y;
    rect.width = v->width;
    rect.height = v->height;
    
    return rect;
}

@end
