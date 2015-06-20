//
//  Cardboard.cpp
//  iosvr
//

#import "Cardboard.h"

#include "CardboardDeviceParams.h"
#include "Distortion.h"
#include "DistortionRenderer.h"
#include "Eye.h"
#include "FieldOfView.h"
#include "HeadTracker.h"
#include "HeadTransform.h"
#include "HeadMountedDisplay.h"

#include "ScreenParams.h"
#include "Viewport.h"
#include "UIScreenExt.h"

#include <hfgl/hfglDebugUtils.h>
#include <hfgl/hfglMathUtils.h>

#import <Foundation/Foundation.h>

namespace iosvr
{

    Cardboard::Cardboard() : distortionCorrectionScale(1.0f),
    vrModeEnabled(true),
    distortionCorrectionEnabled(true),
    projectionChanged(true),
    frameParamentersReady(false),
    zNear(0.1f),
    zFar(100.0f),
    paused(false)
    {
        magnetSensor = new MagnetSensor();
        headTracker = new HeadTracker();
        headTransform = new HeadTransform();
        headMountedDisplay = new HeadMountedDisplay(new UIScreenExt());
        
        monocularEye = new Eye(Eye::EYE_MONOCULAR);
        leftEye = new Eye(Eye::EYE_LEFT);
        rightEye = new Eye(Eye::EYE_RIGHT);
        
        undistortedLeftEye = new Eye(Eye::EYE_LEFT);
        undistortedRightEye = new Eye(Eye::EYE_RIGHT);
        
        distortionRenderer = new DistortionRenderer();
        
        headMountedDisplay->getScreen()->getScreenDevice()->addObserver(this);
        magnetSensor->addObserver(this);
        
        headTracker->startTracking();
        magnetSensor->start();
    }

    Cardboard::~Cardboard()
    {
        if(magnetSensor != 0)
        {
            magnetSensor->removeObserver(this);
            delete magnetSensor;
        }
        
        if(headTracker != 0) { delete headTracker; }
        if(headTransform != 0) { delete headTransform; }
        if(headMountedDisplay != 0)
        {
            headMountedDisplay->getScreen()->getScreenDevice()->removeObserver(this);
            delete headMountedDisplay;
        }
        
        if(monocularEye != 0) { delete monocularEye; }
        if(leftEye != 0) { delete leftEye; }
        if(rightEye != 0) { delete rightEye; }
        
        if(undistortedLeftEye != 0) { delete undistortedLeftEye; }
        if(undistortedRightEye != 0) { delete undistortedRightEye; }
        
        if(distortionRenderer != 0) { delete distortionRenderer; }
    }
    
    void Cardboard::OnOrientationChanged()
    {
        this->headTracker->updateDeviceOrientation();
    }
    
    void Cardboard::OnMagnetTrigger(MagnetSensor* sender)
    {
        std::cout<<"Magnet Pull\n";
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CBDTriggerPressedNotification" object:nil];
    }

    bool Cardboard::getVignetteEnabled()
    {
        return distortionRenderer->getVignetteEnabled();
    }

    void Cardboard::setVignetteEnabled(bool enabled)
    {
        distortionRenderer->setVignetteEnabled(enabled);
    }

    bool Cardboard::getChromaticAberrationCorrectionEnabled()
    {
        return distortionRenderer->getChromaticAberrationEnabled();
    }

    void Cardboard::setChromaticAberrationCorrectionEnabled(bool enabled)
    {
        distortionRenderer->setChromaticAberrationEnabled(enabled);
    }

    bool Cardboard::getRestoreGLStateEnabled()
    {
        return distortionRenderer->getRestoreGLStateEnabled();
    }

    void Cardboard::setRestoreGLStateEnabled(bool enabled)
    {
        distortionRenderer->setRestoreGLStateEnabled(enabled);
    }

    bool Cardboard::getNeckModelEnabled()
    {
        return headTracker->neckModelEnabled();
    }

    void Cardboard::setNeckModelEnabled(bool enabled)
    {
        headTracker->setNeckModelEnabled(enabled);
    }
    
    void Cardboard::setVrModeEnabled(bool enabled)
    {
        this->vrModeEnabled = enabled;
        this->projectionChanged = true;
    }
    
    void Cardboard::setDistortionCorrectionEnabled(bool enabled)
    {
        this->distortionCorrectionEnabled = enabled;
        this->projectionChanged = true;
    }

    void Cardboard::pause(bool doPause)
    {
        if (doPause)
        {
            headTracker->stopTracking();
            magnetSensor->stop();
        }
        else
        {
            headTracker->startTracking();
            magnetSensor->start();
        }
        
        this->paused = doPause;
    }

    void Cardboard::update()
    {
        if (this->paused || !headTracker->isReady())
        {
            return;
        }

        Cardboard::ComputeFrameParametersWithHeadTransform(this,
                                                           headTransform,
                                                           leftEye,
                                                           rightEye,
                                                           monocularEye,
                                                           undistortedLeftEye,
                                                           undistortedRightEye);
        frameParamentersReady = true;
    }

    void Cardboard::ComputeFrameParametersWithHeadTransform(Cardboard* cardboard,
                                                            HeadTransform* _headTransform,
                                                            Eye* _leftEye,
                                                            Eye* _rightEye,
                                                            Eye* _monocularEye,
                                                            Eye* _undistortedLeftEye,
                                                            Eye* _undistortedRightEye)
    {
        CardboardDeviceParams *cardboardDeviceParams = cardboard->headMountedDisplay->getCardboard();
        
        _headTransform->setHeadView(cardboard->headTracker->lastHeadView());
        GLfloat halfInterLensDistance = cardboardDeviceParams->getInterLensDistance() * 0.5f;
        
        if (cardboard->vrModeEnabled)
        {
            GLKMatrix4 leftEyeTranslate = GLKMatrix4MakeTranslation(halfInterLensDistance, 0, 0);
            GLKMatrix4 rightEyeTranslate = GLKMatrix4MakeTranslation(-halfInterLensDistance, 0, 0);
            
            _leftEye->setEyeView( GLKMatrix4Multiply(leftEyeTranslate, _headTransform->getHeadView()));
            _rightEye->setEyeView( GLKMatrix4Multiply(rightEyeTranslate, _headTransform->getHeadView()));
        }
        else
        {
            _monocularEye->setEyeView(_headTransform->getHeadView());
        }
        
        if (cardboard->projectionChanged)
        {
            ScreenParams *screenParams = cardboard->headMountedDisplay->getScreen();
            _monocularEye->getViewport()->setViewport(0, 0, screenParams->getWidth(), screenParams->getHeight());
            
            Cardboard::UpdateUndistortedFOVAndViewport(cardboard, _undistortedLeftEye, _undistortedRightEye);
            
            if (!cardboard->vrModeEnabled)
            {
                Cardboard::UpdateMonocularFov(cardboard, _monocularEye->getFov());
            }
            else if (cardboard->distortionCorrectionEnabled)
            {
                Cardboard::UpdateFovsWithLeftEyeFov(cardboard, _leftEye->getFov(), _rightEye->getFov());
                
                cardboard->distortionRenderer->onFovDidChange(cardboard->headMountedDisplay, _leftEye->getFov(), _rightEye->getFov(), cardboard->getVirtualEyeToScreenDistance());
            }
            else
            {
                Viewport* lvp = _undistortedLeftEye->getViewport();
                Viewport* rvp = _undistortedRightEye->getViewport();
                
                _leftEye->getFov()->setLeft(_undistortedLeftEye->getFov()->getLeft());
                _leftEye->getFov()->setRight(_undistortedLeftEye->getFov()->getRight());
                _leftEye->getFov()->setBottom(_undistortedLeftEye->getFov()->getBottom());
                _leftEye->getFov()->setTop(_undistortedLeftEye->getFov()->getTop());
                
                _rightEye->getFov()->setLeft(_undistortedRightEye->getFov()->getLeft());
                _rightEye->getFov()->setRight(_undistortedRightEye->getFov()->getRight());
                _rightEye->getFov()->setBottom(_undistortedRightEye->getFov()->getBottom());
                _rightEye->getFov()->setTop(_undistortedRightEye->getFov()->getTop());
                
                _leftEye->getViewport()->setViewport(lvp->x, lvp->y, lvp->width, lvp->height);
                _rightEye->getViewport()->setViewport(rvp->x, rvp->y, rvp->width, rvp->height);
            }
            
            _leftEye->setProjectionChanged();
            _rightEye->setProjectionChanged();
            _monocularEye->setProjectionChanged();
            cardboard->projectionChanged = false;
        }
        
        if (cardboard->distortionCorrectionEnabled && cardboard->distortionRenderer->getViewportsChanged())
        {
            cardboard->distortionRenderer->updateViewports(_leftEye->getViewport(), _rightEye->getViewport());
        }
    }

    void Cardboard::UpdateMonocularFov(Cardboard* cardboard, FieldOfView* _monocularFov)
    {
        ScreenParams *screenParams = cardboard->headMountedDisplay->getScreen();
        const GLfloat monocularBottomFov = 22.5f;
        const GLfloat monocularLeftFov = RAD_TO_DEG(atanf(tanf(DEG_TO_RAD(monocularBottomFov)) * screenParams->getWidthInMeters() / screenParams->getHeightInMeters()));
        
        _monocularFov->setLeft(monocularLeftFov);
        _monocularFov->setRight(monocularLeftFov);
        _monocularFov->setBottom(monocularBottomFov);
        _monocularFov->setTop(monocularBottomFov);
    }

    void Cardboard::UpdateFovsWithLeftEyeFov(Cardboard* cardboard, FieldOfView* _leftEyeFov, FieldOfView* _rightEyeFov)
    {
        CardboardDeviceParams *cardboardDeviceParams = cardboard->headMountedDisplay->getCardboard();
        ScreenParams *screenParams = cardboard->headMountedDisplay->getScreen();
        Distortion *distortion = cardboardDeviceParams->getDistortion();
        GLfloat eyeToScreenDistance = cardboard->getVirtualEyeToScreenDistance();
        
        GLfloat outerDistance = (screenParams->getWidthInMeters() - cardboardDeviceParams->getInterLensDistance() ) / 2.0f;
        GLfloat innerDistance = cardboardDeviceParams->getInterLensDistance() / 2.0f;
        GLfloat bottomDistance = cardboardDeviceParams->getVerticalDistanceToLensCenter() - screenParams->getBorderSizeInMeters();
        GLfloat topDistance = screenParams->getHeightInMeters() + screenParams->getBorderSizeInMeters() - cardboardDeviceParams->getVerticalDistanceToLensCenter();
        
        GLfloat outerAngle = RAD_TO_DEG(atanf(distortion->distort(outerDistance / eyeToScreenDistance)));
        GLfloat innerAngle = RAD_TO_DEG(atanf(distortion->distort(innerDistance / eyeToScreenDistance)));
        GLfloat bottomAngle = RAD_TO_DEG(atanf(distortion->distort(bottomDistance / eyeToScreenDistance)));
        GLfloat topAngle = RAD_TO_DEG(atanf(distortion->distort(topDistance / eyeToScreenDistance)));
        
        _leftEyeFov->setLeft(std::min<float>(outerAngle, cardboardDeviceParams->getMaximumLeftEyeFOV()->getLeft()));
        _leftEyeFov->setRight(std::min<float>(innerAngle, cardboardDeviceParams->getMaximumLeftEyeFOV()->getRight()));
        _leftEyeFov->setBottom(std::min<float>(bottomAngle, cardboardDeviceParams->getMaximumLeftEyeFOV()->getBottom()));
        _leftEyeFov->setTop(std::min<float>(topAngle, cardboardDeviceParams->getMaximumLeftEyeFOV()->getTop()));
        
        _rightEyeFov->setLeft(_leftEyeFov->getRight());
        _rightEyeFov->setRight(_leftEyeFov->getLeft());
        _rightEyeFov->setBottom(_leftEyeFov->getBottom());
        _rightEyeFov->setTop(_leftEyeFov->getTop());
    }

    void Cardboard::UpdateUndistortedFOVAndViewport(Cardboard* cardboard, Eye* _leftEye, Eye* _rightEye)
    {
        CardboardDeviceParams *cardboardDeviceParams = cardboard->headMountedDisplay->getCardboard();
        ScreenParams *screenParams = cardboard->headMountedDisplay->getScreen();

        GLfloat halfInterLensDistance = cardboardDeviceParams->getInterLensDistance() * 0.5f;
        GLfloat eyeToScreenDistance = cardboard->getVirtualEyeToScreenDistance();
        
        GLfloat left = screenParams->getWidthInMeters() / 2.0f - halfInterLensDistance;
        GLfloat right = halfInterLensDistance;
        GLfloat bottom = cardboardDeviceParams->getVerticalDistanceToLensCenter() - screenParams->getBorderSizeInMeters();
        GLfloat top = screenParams->getBorderSizeInMeters() + screenParams->getHeightInMeters() - cardboardDeviceParams->getVerticalDistanceToLensCenter();
        
        FieldOfView *leftEyeFov = _leftEye->getFov();
        leftEyeFov->setLeft(RAD_TO_DEG(atan2f(left, eyeToScreenDistance)));
        leftEyeFov->setRight(RAD_TO_DEG(atan2f(right, eyeToScreenDistance)));
        leftEyeFov->setBottom(RAD_TO_DEG(atan2f(bottom, eyeToScreenDistance)));
        leftEyeFov->setTop(RAD_TO_DEG(atan2f(top, eyeToScreenDistance)));
        
        FieldOfView *rightEyeFov = _rightEye->getFov();
        rightEyeFov->setLeft(leftEyeFov->getRight());
        rightEyeFov->setRight(leftEyeFov->getLeft());
        rightEyeFov->setBottom(leftEyeFov->getBottom());
        rightEyeFov->setTop(leftEyeFov->getTop());
        
        _leftEye->getViewport()->setViewport(0, 0, screenParams->getWidth() / 2, screenParams->getHeight());
        _rightEye->getViewport()->setViewport(screenParams->getWidth() / 2, 0, screenParams->getWidth() / 2, screenParams->getHeight());
    }

    GLfloat Cardboard::getVirtualEyeToScreenDistance()
    {
        return headMountedDisplay->getCardboard()->getScreenToLensDistance();
    }
    
    void Cardboard::getFrameParameters(GLfloat* frameParemeters, GLfloat zNear, GLfloat zFar)
    {
        this->update();
        
        if(!this->frameParamentersReady)
        {
            return;
        }
        

        GLKMatrix4 headView = headTransform->getHeadView();
        GLKMatrix4 leftEyeView = leftEye->getEyeView();
        GLKMatrix4 leftEyePerspective = leftEye->getPerspective(zNear, zFar);
        GLKMatrix4 rightEyeView = rightEye->getEyeView();
        GLKMatrix4 rightEyePerspective = rightEye->getPerspective(zNear, zFar);
        
        GLKMatrix4 uleftEyePerspective = undistortedLeftEye->getPerspective(zNear, zFar);
        GLKMatrix4 urightEyePerspective = undistortedRightEye->getPerspective(zNear, zFar);
        
        ScreenParams* screenParams = this->headMountedDisplay->getScreen();
        GLfloat screenWidth = screenParams->getWidth();
        GLfloat screenHeight = screenParams->getHeight();
        
        std::copy(headView.m, headView.m + 16, frameParemeters);
        std::copy(leftEyeView.m, leftEyeView.m + 16, frameParemeters + 16);
        std::copy(leftEyePerspective.m, leftEyePerspective.m + 16, frameParemeters + 32);
        std::copy(rightEyeView.m, rightEyeView.m + 16, frameParemeters + 48);
        std::copy(rightEyePerspective.m, rightEyePerspective.m + 16, frameParemeters + 64);
        
        std::copy(uleftEyePerspective.m, uleftEyePerspective.m + 16, frameParemeters + 80);
        std::copy(urightEyePerspective.m, uleftEyePerspective.m + 16, frameParemeters + 96);

        
        int vpoffset = 112;
        frameParemeters[vpoffset] = (this->undistortedLeftEye->getViewport()->x / screenWidth);
        frameParemeters[(vpoffset + 1)] = (this->undistortedLeftEye->getViewport()->y / screenHeight);
        frameParemeters[(vpoffset + 2)] = (this->undistortedLeftEye->getViewport()->width / screenWidth);
        frameParemeters[(vpoffset + 3)] = (this->undistortedLeftEye->getViewport()->height / screenHeight);
        
        vpoffset += 4;
        frameParemeters[vpoffset] = (this->undistortedRightEye->getViewport()->x / screenWidth);
        frameParemeters[(vpoffset + 1)] = (this->undistortedRightEye->getViewport()->y / screenHeight);
        frameParemeters[(vpoffset + 2)] = (this->undistortedRightEye->getViewport()->width / screenWidth);
        frameParemeters[(vpoffset + 3)] = (this->undistortedRightEye->getViewport()->height / screenHeight);
        
    }

}
