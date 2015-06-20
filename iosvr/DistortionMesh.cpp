//
//  DistortionMesh.cpp
//  iosvr
//
//  Created by Andrea Melle on 02/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#include "DistortionMesh.h"
#include "Distortion.h"
#include <math.h>
#include <hfgl/hfglMathUtils.h>
#include <hfgl/hfglDebugUtils.h>

namespace iosvr
{

    DistortionMesh::DistortionMesh(Distortion *distortionRed,
                                                       Distortion *distortionGreen,
                                                       Distortion *distortionBlue,
                                                       GLfloat screenWidth, GLfloat screenHeight,
                                                       GLfloat xEyeOffsetScreen, GLfloat yEyeOffsetScreen,
                                                       GLfloat textureWidth, GLfloat textureHeight,
                                                       GLfloat xEyeOffsetTexture, GLfloat yEyeOffsetTexture,
                                                       GLfloat viewportXTexture, GLfloat viewportYTexture,
                                                       GLfloat viewportWidthTexture, GLfloat viewportHeightTexture,
                                                       bool vignetteEnabled) : indices(-1), arrayBufferID(-1), elementBufferID(-1)
    {
        GLfloat vertexData[14400];
        
        int vertexOffset = 0;
        
        const int rows = 40;
        const int cols = 40;
        
        const GLfloat vignetteSizeTanAngle = 0.05f;
        
        for (int row = 0; row < rows; ++row)
        {
            for (int col = 0; col < cols; ++col)
            {
                const GLfloat uTextureBlue = col / 39.0f * (viewportWidthTexture / textureWidth) + viewportXTexture / textureWidth;
                const GLfloat vTextureBlue = row / 39.0f * (viewportHeightTexture / textureHeight) + viewportYTexture / textureHeight;
                
                const GLfloat xTexture = uTextureBlue * textureWidth - xEyeOffsetTexture;
                const GLfloat yTexture = vTextureBlue * textureHeight - yEyeOffsetTexture;
                const GLfloat rTexture = sqrtf(xTexture * xTexture + yTexture * yTexture);
                
                const GLfloat textureToScreenBlue = (rTexture > 0.0f) ? distortionBlue->distortInverse(rTexture) / rTexture : 1.0f;
                
                const GLfloat xScreen = xTexture * textureToScreenBlue;
                const GLfloat yScreen = yTexture * textureToScreenBlue;
                
                const GLfloat uScreen = (xScreen + xEyeOffsetScreen) / screenWidth;
                const GLfloat vScreen = (yScreen + yEyeOffsetScreen) / screenHeight;
                const GLfloat rScreen = rTexture * textureToScreenBlue;
                
                const GLfloat screenToTextureGreen = (rScreen > 0.0f) ? distortionGreen->getDistortionFactor(rScreen) : 1.0f;
                const GLfloat uTextureGreen = (xScreen * screenToTextureGreen + xEyeOffsetTexture) / textureWidth;
                const GLfloat vTextureGreen = (yScreen * screenToTextureGreen + yEyeOffsetTexture) / textureHeight;
                
                const GLfloat screenToTextureRed = (rScreen > 0.0f) ? distortionRed->getDistortionFactor(rScreen) : 1.0f;
                const GLfloat uTextureRed = (xScreen * screenToTextureRed + xEyeOffsetTexture) / textureWidth;
                const GLfloat vTextureRed = (yScreen * screenToTextureRed + yEyeOffsetTexture) / textureHeight;
                
                const GLfloat vignetteSizeTexture = vignetteSizeTanAngle / textureToScreenBlue;
                
                const GLfloat dxTexture = xTexture + xEyeOffsetTexture - hfgl::clampf(xTexture + xEyeOffsetTexture,
                                                                             viewportXTexture + vignetteSizeTexture,
                                                                             viewportXTexture + viewportWidthTexture - vignetteSizeTexture);
                const GLfloat dyTexture = yTexture + yEyeOffsetTexture - hfgl::clampf(yTexture + yEyeOffsetTexture,
                                                                             viewportYTexture + vignetteSizeTexture,
                                                                             viewportYTexture + viewportHeightTexture - vignetteSizeTexture);
                const GLfloat drTexture = sqrtf(dxTexture * dxTexture + dyTexture * dyTexture);
                
                GLfloat vignette = 1.0f;
                if (vignetteEnabled)
                {
                    vignette = 1.0f - hfgl::clampf(drTexture / vignetteSizeTexture, 0.0f, 1.0f);
                }
                
                vertexData[(vertexOffset + 0)] = 2.0f * uScreen - 1.0f;
                vertexData[(vertexOffset + 1)] = 2.0f * vScreen - 1.0f;
                vertexData[(vertexOffset + 2)] = vignette;
                vertexData[(vertexOffset + 3)] = uTextureRed;
                vertexData[(vertexOffset + 4)] = vTextureRed;
                vertexData[(vertexOffset + 5)] = uTextureGreen;
                vertexData[(vertexOffset + 6)] = vTextureGreen;
                vertexData[(vertexOffset + 7)] = uTextureBlue;
                vertexData[(vertexOffset + 8)] = vTextureBlue;
                
                vertexOffset += 9;
            }
        }
        
        indices = 3158;
        GLshort indexData[indices];
        
        int indexOffset = 0;
        vertexOffset = 0;
        
        for (int row = 0; row < rows-1; ++row)
        {
            if (row > 0)
            {
                indexData[indexOffset] = indexData[(indexOffset - 1)];
                indexOffset++;
            }
            for (int col = 0; col < cols; ++col)
            {
                if (col > 0)
                {
                    if (row % 2 == 0)
                    {
                        vertexOffset++;
                    }
                    else
                    {
                        vertexOffset--;
                    }
                }
                indexData[(indexOffset++)] = vertexOffset;
                indexData[(indexOffset++)] = (vertexOffset + 40);
            }
            vertexOffset += 40;
        }
        
        GLuint bufferIDs[2] = { 0, 0 };
        glGenBuffers(2, bufferIDs);
        arrayBufferID = bufferIDs[0];
        elementBufferID = bufferIDs[1];
        
        glBindBuffer(GL_ARRAY_BUFFER, arrayBufferID);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferID);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexData), indexData, GL_STATIC_DRAW);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
    }

}