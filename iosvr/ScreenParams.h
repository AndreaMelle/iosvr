//
//  ScreenParams.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__ScreenParams__
#define __CardboardSDK_iOS__ScreenParams__

#include <hfgl/hfglVersion.h>

namespace iosvr
{
    class UIScreenExt;
    
    class ScreenParams
    {
    public:
        
        ScreenParams(UIScreenExt *screen);
        ScreenParams(const ScreenParams &other);
        
        virtual ~ScreenParams();
        
        ScreenParams& operator=(const ScreenParams &other);
        
        bool operator==(const ScreenParams &other) const;
        bool operator!=(const ScreenParams &other) const;
        
        GLint getWidth();
        GLint getHeight();

        GLfloat getWidthInMeters();
        GLfloat getHeightInMeters();

        void setBorderSizeInMeters(GLfloat screenBorderSize);
        GLfloat getBorderSizeInMeters();
        
        UIScreenExt* getScreenDevice() { return this->screen; }
    
    private:
        
        UIScreenExt* screen;
        GLfloat scale;
        GLfloat xMetersPerPixel;
        GLfloat yMetersPerPixel;
        GLfloat borderSizeMeters;

        GLfloat pixelsPerInch(UIScreenExt *screen);
    };

}

#endif
