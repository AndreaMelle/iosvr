//
//  CardboardDeviceParams.cpp
//  iosvr
//

#include "CardboardDeviceParams.h"

#include "Distortion.h"
#include "FieldOfView.h"

namespace iosvr
{
    GLfloat CardboardDeviceParams::DefaultInterLensDistance = 0.06f;
    GLfloat CardboardDeviceParams::DefaultVerticalDistanceToLensCenter = 0.035f;
    GLfloat CardboardDeviceParams::DefaultScreenToLensDistance = 0.042f;

    CardboardDeviceParams::CardboardDeviceParams()
    {
        this->interLensDistance = DefaultInterLensDistance;
        verticalDistanceToLensCenter = DefaultVerticalDistanceToLensCenter;
        screenToLensDistance = DefaultScreenToLensDistance;
        
        distortion = new Distortion();
        maximumLeftEyeFOV = new FieldOfView();
    }

    CardboardDeviceParams::CardboardDeviceParams(const CardboardDeviceParams& other)
    {
        this->interLensDistance = other.interLensDistance;
        this->verticalDistanceToLensCenter = other.verticalDistanceToLensCenter;
        this->screenToLensDistance = other.screenToLensDistance;
        
        this->maximumLeftEyeFOV = new FieldOfView(*other.maximumLeftEyeFOV);
        this->distortion = new Distortion(*other.distortion);
    }

    CardboardDeviceParams::~CardboardDeviceParams()
    {
        if (distortion != 0)
        {
            delete distortion;
        }
        
        if (maximumLeftEyeFOV != 0)
        {
            delete maximumLeftEyeFOV;
        }
    }
    
    CardboardDeviceParams& CardboardDeviceParams::operator=(const CardboardDeviceParams &other)
    {
        if (this != &other)
        {
            this->interLensDistance = other.interLensDistance;
            this->verticalDistanceToLensCenter = other.verticalDistanceToLensCenter;
            this->screenToLensDistance = other.screenToLensDistance;
            
            this->maximumLeftEyeFOV = new FieldOfView(*other.maximumLeftEyeFOV);
            this->distortion = new Distortion(*other.distortion);
        }
        
        return *this;
    }
    
    bool CardboardDeviceParams::operator==(const CardboardDeviceParams &other) const
    {
        return (this->interLensDistance == other.interLensDistance
                && this->verticalDistanceToLensCenter == other.verticalDistanceToLensCenter
                && this->screenToLensDistance == other.screenToLensDistance
                && this->maximumLeftEyeFOV == other.maximumLeftEyeFOV
                && this->distortion == other.distortion);
    }
    
    bool CardboardDeviceParams::operator!=(const CardboardDeviceParams &other) const
    {
        return !(*this == other);
    }

    GLfloat CardboardDeviceParams::getInterLensDistance()
    {
        return interLensDistance;
    }

    GLfloat CardboardDeviceParams::getVerticalDistanceToLensCenter()
    {
        return verticalDistanceToLensCenter;
    }

    GLfloat CardboardDeviceParams::getScreenToLensDistance()
    {
        return screenToLensDistance;
    }

    FieldOfView *CardboardDeviceParams::getMaximumLeftEyeFOV()
    {
        return maximumLeftEyeFOV;
    }

    Distortion *CardboardDeviceParams::getDistortion()
    {
        return distortion;
    }

}