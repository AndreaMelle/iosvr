/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal Renderer for Metal Basic 3D. Acts as the update and render delegate for the view controller and performs rendering. In MetalBasic3D, the renderer draws N cubes, whos color values change every update.
 */

#import <Metal/Metal.h>
#import "CardboardMetalRenderer.h"

@interface CubeSceneRenderer : NSObject <CardboardMetalViewDelegate>


- (void)update:(CardboardMetalViewController *)controller;
- (void)viewController:(CardboardMetalViewController *)controller willPause:(BOOL)pause;

@end
