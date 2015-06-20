//
//  UIScreenExt.h
//  iosvr
//
//  Created by Andrea Melle on 02/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#ifndef __iosvr__UIScreenExt__
#define __iosvr__UIScreenExt__

#include <stdio.h>
#include <hfgl/hfglVersion.h>
#include <vector>

namespace iosvr
{
    class UIScreenExt
    {
    public:
        class OrientationObserver
        {
        public:
            virtual void OnOrientationChanged() = 0;
        };
        
    public:
        UIScreenExt();
        virtual ~UIScreenExt();
        
        GLfloat getDisplayScale();
        GLfloat getBorderMeters();
        
        bool getCorrectViewportSize();
        GLfloat getPhysicalSizeScale();
        
        GLint getOrientationAwareHeight();
        GLint getOrientationAwareWidth();
        GLfloat getPixelsPerInch(GLfloat scale);
        
        void notifyDeviceOrientationChange();
        
        void addObserver(OrientationObserver* observer);
        void removeObserver(OrientationObserver* observer);
        void clearAllObservers();
        
    private:
        
        static GLfloat DefaultBorderSizeMeters;
        
        std::vector<OrientationObserver*> observers;
        void notifyObservers();
        
        bool mCorrectViewportSize;
        GLfloat mPhysicalSizeScale;
        
        void *screenHelper;
        
    };
};

#endif /* defined(__iosvr__UIScreenExt__) */
