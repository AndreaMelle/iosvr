//
//  Viewport.h
//  iosvr
//


#ifndef __IOSVR__VIEWPORT_H__
#define __IOSVR__VIEWPORT_H__

#include <stdio.h>
#include <hfgl/hfglVersion.h>

namespace iosvr
{

    class Viewport
    {
      public:
        Viewport();
        virtual ~Viewport();
        GLint x;
        GLint y;
        GLint width;
        GLint height;

        void setViewport(GLint _x, GLint _y, GLint _width, GLint _height);
        void setGLViewport();
        void setGLScissor();
        
    };

};

#endif //__IOSVR__VIEWPORT_H__