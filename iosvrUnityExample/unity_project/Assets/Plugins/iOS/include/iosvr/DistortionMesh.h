//
//  DistortionMesh.h
//  iosvr
//
//  Created by Andrea Melle on 02/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#ifndef __IOSVR__DISTORTION_MESH_H__
#define __IOSVR__DISTORTION_MESH_H__

#include <hfgl/hfglVersion.h>

namespace iosvr
{
    class Distortion;
    
    class DistortionMesh
    {
    public:
        GLsizei indices;
        GLint arrayBufferID;
        GLint elementBufferID;
        
        DistortionMesh(Distortion *distortionRed,
                       Distortion *distortionGreen,
                       Distortion *distortionBlue,
                       GLfloat screenWidth, GLfloat screenHeight,
                       GLfloat xEyeOffsetScreen, GLfloat yEyeOffsetScreen,
                       GLfloat textureWidth, GLfloat textureHeight,
                       GLfloat xEyeOffsetTexture, GLfloat yEyeOffsetTexture,
                       GLfloat viewportXTexture, GLfloat viewportYTexture,
                       GLfloat viewportWidthTexture,
                       GLfloat viewportHeightTexture,
                       bool vignetteEnabled);
    };
};

#include <stdio.h>

#endif //__IOSVR__DISTORTION_MESH_H__
