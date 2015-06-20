//
//  CardboardUnityPluginInterface.cpp
//  iosvr
//
//  Created by Andrea Melle on 03/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#include "CardboardUnityPluginInterface.h"
#include "CardboardUnity.h"

void initFromUnity(const char* gameObjectName)
{
    iosvr::CardboardUnity::Instance().initFromUnity(std::string(gameObjectName));
}

void setUnityTexturePointer(int textureID)
{
    iosvr::CardboardUnity::Instance().setUnityTexturePointer((GLint)textureID);
}

void getLensParameters(float* lensData)
{
    iosvr::CardboardUnity::Instance().getLensParameters((GLfloat*)lensData);
}

void getScreenSizeMeters(float* screenSize)
{
    iosvr::CardboardUnity::Instance().getScreenSizeMeters((GLfloat*)screenSize);
}

void getDistortionCoefficients(float* distCoeff)
{
    iosvr::CardboardUnity::Instance().getDistortionCoefficients((GLfloat*)distCoeff);
}

void getInverseDistortionCoefficients(float* invDistCoeff)
{
    iosvr::CardboardUnity::Instance().getInverseDistortionCoefficients((GLfloat*)invDistCoeff);
}

void getLeftEyeMaximumFOV(float* maxFov)
{
    iosvr::CardboardUnity::Instance().getLeftEyeMaximumFOV((GLfloat*)maxFov);
}

void getFrameParams(float* frameInfo, float zNear, float zFar)
{
    iosvr::CardboardUnity::Instance().getFrameParams((GLfloat*)frameInfo, (GLfloat)zNear, (GLfloat)zFar);
}

void resetHeadTracker()
{
    iosvr::CardboardUnity::Instance().resetHeadTracker();
}

void pauseCardboard(int paused)
{
    iosvr::CardboardUnity::Instance().pause(paused);
}

void setDistortionCorrectionEnabled(int enabled)
{
    iosvr::CardboardUnity::Instance().setDistortionCorrectionEnabled(enabled);
}

void setVignetteEnabled(int enabled)
{
    iosvr::CardboardUnity::Instance().setVignetteEnabled(enabled);
}

static int g_DeviceType = -1;
void UnitySetGraphicsDevice(void* device, int deviceType, int eventType)
{
    g_DeviceType = -1;
    
    if(deviceType == kGfxRendererOpenGLES20Mobile)
    {
        g_DeviceType = deviceType;
    }
    else if(deviceType == kGfxRendererOpenGLES30)
    {
        g_DeviceType = deviceType;
    }
}

void UnityRenderEvent(int eventID)
{
    if(g_DeviceType == -1)
        return;
    
    if(eventID == kPerformDistortionCorrection)
    {
        iosvr::CardboardUnity::Instance().renderUndistortedTexture();
    }
    
    
}
