//
//  CardboardUnity.h
//  iosvr
//
//  Created by Ricardo Sánchez-Sáez on 03/02/2015.
//
//

#ifndef __IOSVR__CARDBOARDUNITY_H__
#define __IOSVR__CARDBOARDUNITY_H__

#include <iostream>
#include <hfgl/hfglVersion.h>
#include <iosvr/magnetSensor.h>

//private static final int NUM_RETURNED_MATRICES = 7;
//private static final int MATRIX_SIZE = 16;
//private static final int NUM_RETURNED_VIEWPORTS = 2;
//private static final int VIEWPORT_SIZE = 4;
//private static final int NUM_FRAME_PARAMS = 120;

namespace iosvr
{
    class Cardboard;
    
    class CardboardUnity : public MagnetSensor::MagnetSensorObserver
    {
    public:
        static CardboardUnity& Instance()
        {
            static CardboardUnity instance;
            return instance;
        }
        
        virtual ~CardboardUnity();
        
        void initFromUnity(std::string unityObjectName);
        void setUnityTexturePointer(GLint textureID);
        GLint getUnityTexturePointer();
        void renderUndistortedTexture();
        
        void getFrameParams(GLfloat* frameInfo, GLfloat zNear, GLfloat zFar);
        void getDistortionCoefficients(GLfloat* distCoeff);
        void getInverseDistortionCoefficients(GLfloat* invDistCoeff);
        void getLeftEyeMaximumFOV(GLfloat* maxFov);
        void getScreenSizeMeters(GLfloat* screenSize);
        void getLensParameters(GLfloat* lensData);
        
        void resetHeadTracker();
        
        void pause(bool paused);
        
        void setDistortionCorrectionEnabled(bool enabled);
        bool getDistortionCorrectionEnabled();
        
        void setVignetteEnabled(bool enabled);
        bool getVignetteEnabled();
        
        void OnMagnetTrigger(MagnetSensor* sender);
        
    private:
        CardboardUnity();
        
        CardboardUnity(CardboardUnity const&);
        void operator=(CardboardUnity const&);
        
        Cardboard* cardboard;
        std::string unityObjectName;
        
        GLint mTextureID;
        
    };
}

#endif //__IOSVR__CARDBOARDUNITY_H__

