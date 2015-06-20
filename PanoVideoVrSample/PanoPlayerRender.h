//
//  PanoPlayerRender.h
//  iosvr
//
//  Created by Andrea Melle on 16/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <iosvr/CardboardViewController.h>

@interface PanoPlayerRender : NSObject
{
    
}

- (void)setupRendererWithView:(GLKView *)glView;
- (void)shutdownRendererWithView:(GLKView *)glView;
- (void)renderViewDidChangeSize:(CGSize)size;
- (void)drawEyeWithEye:(CBDEye *)eye;
- (void)finishFrameWithViewportRect:(CGRect)viewPort;
- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix;

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

