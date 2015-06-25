//
//  CardboardMetalView.h
//  iosvr
//
//  Created by Andrea Melle on 24/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>
#import "Cardboard.h"

@protocol CardboardMetalViewDelegate;

@interface CardboardMetalView : UIView

@property (nonatomic, weak) id<CardboardMetalViewDelegate> delegate;
@property (nonatomic) iosvr::Cardboard* cardboard;

@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) id <MTLCommandQueue> commandQueue;
@property (nonatomic, readonly) id<CAMetalDrawable> currentDrawable;

// The current framebuffer can be read by delegate during -[MetalViewDelegate render:]
// This call may block until the framebuffer is available.
@property (nonatomic, readonly) MTLRenderPassDescriptor* renderPassDescriptor;

// set these pixel formats to have the main drawable framebuffer get created with depth and/or stencil attachments
@property (nonatomic) MTLPixelFormat depthPixelFormat;
@property (nonatomic) MTLPixelFormat stencilPixelFormat;
@property (nonatomic) NSUInteger     sampleCount;

// view controller will be call off the main thread
- (void)display;

// release any color/depth/stencil resources. view controller will call when paused.
- (void)releaseTextures;

@end


