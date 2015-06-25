//
//  CardboardMetalRenderer.m
//  iosvr
//
//  Created by Andrea Melle on 24/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CardboardMetalRenderer.h"
#import "CMTransforms.h"


@implementation CBMetalEye

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

- (simd::float4x4)eyeViewMatrix
{
    if (_eye != 0)
    {
        return _eye->getEyeViewMTL();
    }
    return CM::identity();
}

- (simd::float4x4)perspectiveMatrixWithZNear:(float)zNear zFar:(float)zFar
{
    if (_eye != 0)
    {
        return _eye->getPerspectiveMTL(zNear, zFar);
    }
    return CM::identity();
}

@end
