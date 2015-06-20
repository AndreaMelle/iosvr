//
//  Cardboard.h
//  iosvr
//

#include <stdio.h>
#include <hfgl/hfglVersion.h>
#include "UIScreenExt.h"
#include "MagnetSensor.h"

namespace iosvr
{
    class MagnetSensor;
    class HeadTracker;
    class HeadTransform;
    class HeadMountedDisplay;
    class Eye;
    class DistortionRenderer;
    class FieldOfView;
    
    class Cardboard : public UIScreenExt::OrientationObserver, public MagnetSensor::MagnetSensorObserver
    {
    public:
        Cardboard();
        virtual ~Cardboard();
        
        void getFrameParameters(GLfloat* frameParemeters, GLfloat zNear, GLfloat zFar);
        
        bool getVrModeEnabled() { return this->vrModeEnabled; }
        bool getDistortionCorrectionEnabled() { return this->distortionCorrectionEnabled; }
        
        void setVrModeEnabled(bool enabled);
        void setDistortionCorrectionEnabled(bool enabled);
        
        void setVignetteEnabled(bool enabled);
        bool getVignetteEnabled();
        
        void setChromaticAberrationCorrectionEnabled(bool enabled);
        bool getChromaticAberrationCorrectionEnabled();
        
        void setRestoreGLStateEnabled(bool enabled);
        bool getRestoreGLStateEnabled();
        
        void setNeckModelEnabled(bool enabled);
        bool getNeckModelEnabled();
        
        void pause(bool doPause);
        bool isPaused() { return this->paused; }
        void update();
        bool areFrameParamentersReady() { return this->frameParamentersReady; }
        
        void OnOrientationChanged();
        void OnMagnetTrigger(MagnetSensor* sender);
        
        MagnetSensor* getMagnetSensor() { return this->magnetSensor; }
        HeadTracker* getHeadTracker() { return this->headTracker; }
        HeadTransform* getHeadTransform() { return this->headTransform; }
        HeadMountedDisplay* getHeadMountedDisplay() { return this->headMountedDisplay; }
        DistortionRenderer* getDistortionRenderer() { return this->distortionRenderer; }
        
        Eye* getLeftEye() { return this->leftEye; }
        Eye* getRightEye() { return this->rightEye; }
        Eye* getMonocularEye() { return this->monocularEye; }
        
    private:
        
        MagnetSensor *magnetSensor;
        HeadTracker *headTracker;
        HeadTransform *headTransform;
        HeadMountedDisplay *headMountedDisplay;
        
        Eye *monocularEye;
        Eye *leftEye;
        Eye *rightEye;
        
        Eye *undistortedLeftEye;
        Eye *undistortedRightEye;
        
        DistortionRenderer *distortionRenderer;
        
        GLfloat distortionCorrectionScale;
        GLfloat zNear;
        GLfloat zFar;
        
        bool projectionChanged;
        bool frameParamentersReady;
        bool paused;
        
        bool vrModeEnabled;
        bool distortionCorrectionEnabled;
        
        void static ComputeFrameParametersWithHeadTransform(Cardboard* cardboard,
                                                             HeadTransform* headTransform,
                                                             Eye* leftEye,
                                                             Eye* rightEye,
                                                             Eye* monocularEye,
                                                             Eye* undistortedLeftEye,
                                                             Eye* undistortedRightEye);
        
        static void UpdateUndistortedFOVAndViewport(Cardboard* cardboard, Eye* _leftEye, Eye* _rightEye);
        
        static void UpdateMonocularFov(Cardboard* cardboard, FieldOfView* _monocularFov);
        
        static void UpdateFovsWithLeftEyeFov(Cardboard* cardboard, FieldOfView* leftEyeFov, FieldOfView* rightEyeFov);
        
        GLfloat getVirtualEyeToScreenDistance();
        
    };
};

//@property (nonatomic) BOOL vrModeEnabled;
//@property (nonatomic) BOOL distortionCorrectionEnabled;
//@property (nonatomic) BOOL vignetteEnabled;
//@property (nonatomic) BOOL chromaticAberrationCorrectionEnabled;
//@property (nonatomic) BOOL restoreGLStateEnabled;
//@property (nonatomic) BOOL neckModelEnabled;
