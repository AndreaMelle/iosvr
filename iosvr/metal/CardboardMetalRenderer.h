//
//  CardboardMetalRenderer.h
//  iosvr
//
//  Created by Andrea Melle on 24/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CardboardViewController.h"
#import <simd/simd.h>
#import <Metal/Metal.h>
#include "Eye.h"

#ifdef __cplusplus

@interface CBMetalEye : NSObject

@property (nonatomic) CBDEyeType type;

@property (nonatomic) iosvr::Eye *eye;

- (instancetype)initWithEye:(iosvr::Eye *)eye;

- (simd::float4x4)eyeViewMatrix;
- (simd::float4x4)perspectiveMatrixWithZNear:(float)zNear zFar:(float)zFar;

@end

#endif

@class CardboardMetalViewController;
@class CardboardMetalView;

// a renderer
@protocol CardboardMetalViewDelegate <NSObject>
@required

- (void)setup:(CardboardMetalView*)view;

// called if the view changes orientation or size, renderer can precompute its view and projection matricies here for example
- (void)reshape:(CardboardMetalView*)view;

//TODO: For when we switch back and forth from VR
//- (void)renderViewDidChangeSize:(CGSize)size;

- (void)prepareNewFrameWithHeadViewMatrix:(simd::float4x4)headViewMatrix;
- (void)drawEyeWithEye:(CBMetalEye *)eye renderEncoder:(id<MTLRenderCommandEncoder>)encoder;
- (void)finishFrameWithViewportRect:(CGRect)viewPort renderEncoder:(id<MTLRenderCommandEncoder>)encoder;

@end

// usually self on a derived class
@protocol CardboardMetalViewControllerDelegate <NSObject>
@required

@property (nonatomic, strong) id<CardboardMetalViewDelegate> viewDelegate;

// This method is called from the thread the main loop is run
- (void)update:(CardboardMetalViewController*)controller;

// Called when main loop is paused
- (void)viewController:(CardboardMetalViewController*)controller willPause:(BOOL)pause;

@optional

- (void)magneticTriggerPressed;

@end
