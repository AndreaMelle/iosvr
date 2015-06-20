//
//  CardboardUnityPluginInterface.h
//  iosvr
//
//  Created by Andrea Melle on 03/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#ifndef __iosvr__CardboardUnityPluginInterface__
#define __iosvr__CardboardUnityPluginInterface__

#include <stdio.h>

#define EXPORT_API

// Graphics device identifiers in Unity
enum GfxDeviceRenderer
{
    kGfxRendererOpenGL = 0,			// OpenGL
    kGfxRendererD3D9,				// Direct3D 9
    kGfxRendererD3D11,				// Direct3D 11
    kGfxRendererGCM,				// Sony PlayStation 3 GCM
    kGfxRendererNull,				// "null" device (used in batch mode)
    kGfxRendererHollywood,			// Nintendo Wii
    kGfxRendererXenon,				// Xbox 360
    kGfxRendererOpenGLES_Obsolete,
    kGfxRendererOpenGLES20Mobile,	// OpenGL ES 2.0
    kGfxRendererMolehill_Obsolete,
    kGfxRendererOpenGLES20Desktop_Obsolete,
    kGfxRendererOpenGLES30,			// OpenGL ES 3.0
    kGfxRendererCount
};


// Event types for UnitySetGraphicsDevice
enum GfxDeviceEventType
{
    kGfxDeviceEventInitialize = 0,
    kGfxDeviceEventShutdown,
    kGfxDeviceEventBeforeReset,
    kGfxDeviceEventAfterReset,
};

enum kIssuePluginEvent
{
    kPerformDistortionCorrection = 1,
    kDrawCardboardUILayer = 2,
};

extern "C"
{
    void EXPORT_API initFromUnity(const char* gameObjectName);
    void EXPORT_API setUnityTexturePointer(int textureID);
    void EXPORT_API getLensParameters(float* lensData);
    void EXPORT_API getScreenSizeMeters(float* screenSize);
    void EXPORT_API getDistortionCoefficients(float* distCoeff);
    void EXPORT_API getInverseDistortionCoefficients(float* invDistCoeff);
    void EXPORT_API getLeftEyeMaximumFOV(float* maxFov);
    void EXPORT_API getFrameParams(float* frameInfo, float zNear, float zFar);
        
    void EXPORT_API resetHeadTracker();
    
    void EXPORT_API pauseCardboard(int paused);
    
    void EXPORT_API setDistortionCorrectionEnabled(int enabled);
    void EXPORT_API setVignetteEnabled(int enabled);
    
    void EXPORT_API UnitySetGraphicsDevice(void* device, int deviceType, int eventType);
    void EXPORT_API UnityRenderEvent(int eventID);
    
}

#endif /* defined(__iosvr__CardboardUnityPluginInterface__) */
