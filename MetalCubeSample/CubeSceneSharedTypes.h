/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Shared data types between CPU code and metal shader code
 */

#ifndef _CUBE_SCENE_SHARED_TYPES_H_
#define _CUBE_SCENE_SHARED_TYPES_H_

#import <simd/simd.h>

#ifdef __cplusplus


typedef struct
{
    simd::float4x4 modelview_projection_matrix;
    simd::float4x4 normal_matrix;
    simd::float4   ambient_color;
    simd::float4   diffuse_color;
    int            multiplier;
} constants_t;

#endif

#endif