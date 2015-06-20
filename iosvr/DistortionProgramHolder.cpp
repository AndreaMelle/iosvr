//
//  DistortionProgramHolder.cpp
//  iosvr
//
//  Created by Andrea Melle on 02/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#include "DistortionProgramHolder.h"

namespace iosvr
{
    DistortionProgramHolder::DistortionProgramHolder() : program(-1),
    positionLocation(-1),
    vignetteLocation(-1),
    redTextureCoordLocation(-1),
    greenTextureCoordLocation(-1),
    blueTextureCoordLocation(-1),
    uTextureCoordScaleLocation(-1),
    uTextureSamplerLocation(-1)
    {
        
    }
}