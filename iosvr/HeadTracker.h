//
//  HeadTracker.h
//  CardboardSDK-iOS
//

#ifndef __CardboardSDK_iOS__HeadTracker__
#define __CardboardSDK_iOS__HeadTracker__

#include "OrientationEKF.h"
#import <GLKit/GLKMatrix4.h>
#import <OpenGLES/ES2/gl.h>

namespace iosvr
{
    class OrientationEKF;
    
    class HeadTracker
    {
    public:
        
        HeadTracker();
        virtual ~HeadTracker();
        
        void startTracking(); //UIInterfaceOrientation
        void stopTracking();
        GLKMatrix4 lastHeadView();
        
        void resetHeadTracker() {}
        
        void updateDeviceOrientation(); //UIInterfaceOrientation

        bool neckModelEnabled();
        void setNeckModelEnabled(bool enabled);
        
        bool isReady();
    
    private:
        
        void* _motionManager;
        size_t _sampleCount;
        OrientationEKF* _tracker;
        GLKMatrix4 _displayFromDevice;
        GLKMatrix4 _inertialReferenceFrameFromWorld;
        GLKMatrix4 _correctedInertialReferenceFrameFromWorld;
        GLKMatrix4 _lastHeadView;
        double _lastGyroEventTimestamp;
        bool _headingCorrectionComputed;
        bool _neckModelEnabled;
        GLKMatrix4 _neckModelTranslation;
        GLfloat _orientationCorrectionAngle;

        const GLfloat _defaultNeckHorizontalOffset = 0.08f;
        const GLfloat _defaultNeckVerticalOffset = 0.075f;
    };

}

#endif
