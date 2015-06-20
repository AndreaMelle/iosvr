//
//  hfglMathUtils.h
//  hfgl
//
//  Created by Andrea Melle on 02/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#ifndef __HFGL_MATH_UTILS_H__
#define __HFGL_MATH_UTILS_H__

#include <stdio.h>
#include <math.h>

#define RAD_TO_DEG(radians) ((radians) * (180.0f / M_PI))
#define DEG_TO_RAD(angle) ((angle) / 180.0f * M_PI)
#define METERS_PER_INCH 0.0254f

namespace hfgl
{
    float clampf(float lhs, float lowerbound = 0.0f, float upperbound = 0.0f);
    double* simpleLeastSquaresSolver(double* vecX, double** matA, double* vecY, size_t dim, size_t numSamples);
    
};

#endif //__HFGL_MATH_UTILS_H__
