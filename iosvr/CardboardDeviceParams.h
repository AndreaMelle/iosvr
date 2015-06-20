//
//  CardboardDeviceParams.h
//  iosvr
//

#ifndef __IOSVR__CARDBOARD_DEVICE_PARAMS_H__
#define __IOSVR__CARDBOARD_DEVICE_PARAMS_H__

#include <stdio.h>
#include <hfgl/hfglVersion.h>

namespace iosvr
{
    class Distortion;
    class FieldOfView;

    class CardboardDeviceParams
    {
      public:
        CardboardDeviceParams();
        CardboardDeviceParams(const CardboardDeviceParams& other);
        
        virtual ~CardboardDeviceParams();
        
        CardboardDeviceParams& operator=(const CardboardDeviceParams &other);
        
        bool operator==(const CardboardDeviceParams &other) const;
        bool operator!=(const CardboardDeviceParams &other) const;
        
        GLfloat getInterLensDistance();
        GLfloat getVerticalDistanceToLensCenter();
        GLfloat getScreenToLensDistance();
        
        FieldOfView* getMaximumLeftEyeFOV();
        Distortion* getDistortion();
        
    private:

        static GLfloat DefaultInterLensDistance;
        static GLfloat DefaultVerticalDistanceToLensCenter;
        static GLfloat DefaultScreenToLensDistance;
        
        GLfloat interLensDistance;
        GLfloat verticalDistanceToLensCenter;
        GLfloat screenToLensDistance;

        FieldOfView* maximumLeftEyeFOV;
        Distortion* distortion;
    };

};

#endif //
