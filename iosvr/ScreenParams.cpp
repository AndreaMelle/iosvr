//
//  ScreenParams.cpp
//  iosvr
//

#include "ScreenParams.h"
#include "UIScreenExt.h"
#include <hfgl/hfglMathUtils.h>

namespace iosvr
{
    ScreenParams::ScreenParams(UIScreenExt *screen)
    {
        this->screen = screen;
        
        this->scale = this->screen->getDisplayScale();
        
        GLfloat screenPixelsPerInch = screen->getPixelsPerInch(this->scale);
        
        xMetersPerPixel = (METERS_PER_INCH / screenPixelsPerInch);
        yMetersPerPixel = (METERS_PER_INCH / screenPixelsPerInch);
        
        borderSizeMeters = screen->getBorderMeters();
    }
    
    ScreenParams::ScreenParams(const ScreenParams &other)
    {
        this->scale = other.scale;
        this->xMetersPerPixel = other.xMetersPerPixel;
        this->yMetersPerPixel = other.yMetersPerPixel;
        this->borderSizeMeters = other.borderSizeMeters;
    }
        
    ScreenParams::~ScreenParams()
    {
        if(this->screen != 0)
        {
            delete this->screen;
            this->screen = 0;
        }
    }
        
    ScreenParams& ScreenParams::operator=(const ScreenParams &other)
    {
        if(*this != other)
        {
            this->scale = other.scale;
            this->xMetersPerPixel = other.xMetersPerPixel;
            this->yMetersPerPixel = other.yMetersPerPixel;
            this->borderSizeMeters = other.borderSizeMeters;
        }
        
        return *this;
    }
        
    bool ScreenParams::operator==(const ScreenParams &other) const
    {
        return (this->scale == other.scale
                && this->xMetersPerPixel == other.xMetersPerPixel
                && this->yMetersPerPixel == other.yMetersPerPixel
                && this->borderSizeMeters == other.borderSizeMeters);
    }
    
    bool ScreenParams::operator!=(const ScreenParams &other) const
    {
        return !(*this == other);
    }

    int ScreenParams::getWidth()
    {
        return screen->getOrientationAwareWidth() * scale;
    }

    int ScreenParams::getHeight()
    {
        return screen->getOrientationAwareHeight() * scale;
    }

    GLfloat ScreenParams::getWidthInMeters()
    {
        GLfloat meters = this->getWidth() * xMetersPerPixel * screen->getPhysicalSizeScale();
        return meters;
    }

    GLfloat ScreenParams::getHeightInMeters()
    {
        GLfloat meters = this->getHeight() * yMetersPerPixel * screen->getPhysicalSizeScale();
        return meters;
    }

    void ScreenParams::setBorderSizeInMeters(GLfloat screenBorderSize)
    {
        borderSizeMeters = screenBorderSize;
    }

    GLfloat ScreenParams::getBorderSizeInMeters()
    {
        return borderSizeMeters;
    }

}