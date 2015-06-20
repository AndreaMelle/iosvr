//
//  DistortionProgramHolder.h
//  iosvr
//
//  Created by Andrea Melle on 02/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#ifndef __iosvr__DistortionProgramHolder__
#define __iosvr__DistortionProgramHolder__

#include <stdio.h>
#include <hfgl/hfglVersion.h>

namespace iosvr
{
    class DistortionProgramHolder
    {
    public:
        DistortionProgramHolder();
        
        GLint program;
        GLint positionLocation;
        GLint vignetteLocation;
        GLint redTextureCoordLocation;
        GLint greenTextureCoordLocation;
        GLint blueTextureCoordLocation;
        GLint uTextureCoordScaleLocation;
        GLint uTextureSamplerLocation;
    };
};

#endif /* defined(__iosvr__DistortionProgramHolder__) */
