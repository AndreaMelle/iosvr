#include "CardboardUnity.h"
#include <iosvr/Cardboard.h>
#include <iosvr/DistortionRenderer.h>
#include <iosvr/HeadTracker.h>
#include <iosvr/Distortion.h>
#include <iosvr/HeadMountedDisplay.h>
#include <iosvr/ScreenParams.h>
#include <iosvr/CardboardDeviceParams.h>
#include <iosvr/FieldOfView.h>
#include <iosvr/ScreenParams.h>
#include <Foundation/Foundation.h>

extern "C"
{
    void UnitySendMessage(const char* obj, const char* method, const char* msg);
}

namespace iosvr
{
    CardboardUnity::CardboardUnity() : mTextureID(-1)
    {
        cardboard = new iosvr::Cardboard();
        //cardboard->getMagnetSensor()->addObserver(this);
        //cardboard->getDistortionRenderer()->setTextureFormat(GL_RGB, GL_UNSIGNED_SHORT_5_6_5);
    }
    
    CardboardUnity::~CardboardUnity()
    {
        //cardboard->getMagnetSensor()->removeObserver(this);
        if (cardboard != 0) { delete cardboard; }
    }
    
    void CardboardUnity::initFromUnity(std::string _unityObjectName)
    {
        this->unityObjectName = _unityObjectName;
    }
    
    void CardboardUnity::OnMagnetTrigger(MagnetSensor* sender)
    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UnitySendMessage(this->unityObjectName.c_str(), "OnCardboardTriggerInternal", "");
//        });
    }
    
    void CardboardUnity::setUnityTexturePointer(GLint textureID)
    {
        this->mTextureID = textureID;
    }
    
    void CardboardUnity::renderUndistortedTexture()
    {
        if(cardboard->isPaused() || !cardboard->areFrameParamentersReady() || mTextureID == -1)
        {
            return;
        }
        
        cardboard->getDistortionRenderer()->undistortTexture(mTextureID);
    }
    
    GLint CardboardUnity::getUnityTexturePointer()
    {
        return this->mTextureID;
    }
    
    void CardboardUnity::getFrameParams(GLfloat* frameInfo, GLfloat zNear, GLfloat zFar)
    {
        cardboard->getFrameParameters(frameInfo, zNear, zFar);
    }
    
    void CardboardUnity::getDistortionCoefficients(GLfloat* distCoeff)
    {
        Distortion* dist = cardboard->getHeadMountedDisplay()->getCardboard()->getDistortion();
        std::copy(dist->getCoefficients(), dist->getCoefficients() + 2, distCoeff);
    }
    
    void CardboardUnity::getInverseDistortionCoefficients(GLfloat* invDistCoeff)
    {
        GLfloat maxRadius = 2.0f;
        Distortion* dist = cardboard->getHeadMountedDisplay()->getCardboard()->getDistortion();
        Distortion* invDist = dist->getApproximateInverseDistortion(maxRadius);
        std::copy(invDist->getCoefficients(), invDist->getCoefficients() + 2, invDistCoeff);
        delete invDist;
    }
    
    void CardboardUnity::getLeftEyeMaximumFOV(GLfloat* maxFov)
    {
        FieldOfView *fov = cardboard->getHeadMountedDisplay()->getCardboard()->getMaximumLeftEyeFOV();
        
        maxFov[0] = fov->getLeft();
        maxFov[1] = fov->getTop();
        maxFov[2] = fov->getRight();
        maxFov[3] = fov->getBottom();
    }
    
    void CardboardUnity::getScreenSizeMeters(GLfloat* screenSize)
    {
        ScreenParams *screen = cardboard->getHeadMountedDisplay()->getScreen();
        screenSize[0] = screen->getWidthInMeters();
        screenSize[1] = screen->getHeightInMeters();
        screenSize[2] = screen->getBorderSizeInMeters();
    }

    void CardboardUnity::getLensParameters(GLfloat* lensData)
    {
        CardboardDeviceParams *cdp = cardboard->getHeadMountedDisplay()->getCardboard();
        
        GLfloat alignment = 1.0f;
        
        lensData[0] = cdp->getInterLensDistance();
        lensData[1] = cdp->getVerticalDistanceToLensCenter();
        lensData[2] = cdp->getScreenToLensDistance();
        lensData[3] = alignment;
    }
    
    void CardboardUnity::resetHeadTracker()
    {
        cardboard->getHeadTracker()->resetHeadTracker();
    }
    
    void CardboardUnity::pause(bool paused)
    {
        cardboard->pause(paused);
    }
    
    void CardboardUnity::setDistortionCorrectionEnabled(bool enabled)
    {
        cardboard->setDistortionCorrectionEnabled(enabled);
    }
    
    bool CardboardUnity::getDistortionCorrectionEnabled()
    {
        return cardboard->getDistortionCorrectionEnabled();
    }
    
    void CardboardUnity::setVignetteEnabled(bool enabled)
    {
        cardboard->setVignetteEnabled(enabled);
    }
    
    bool CardboardUnity::getVignetteEnabled()
    {
        return cardboard->getVignetteEnabled();
    }
    
}