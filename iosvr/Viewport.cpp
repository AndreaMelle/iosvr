//
//  Viewport.cpp
//  iosvr
//


#include "Viewport.h"

#include <hfgl/hfglVersion.h>


namespace iosvr
{
    
    Viewport::Viewport() : x(0), y(0), width(0), height(0)
    {
        
    }
    
    Viewport::~Viewport()
    {
        
    }
    
    void Viewport::setViewport(GLint _x, GLint _y, GLint _width, GLint _height)
    {
        this->x = _x;
        this->y = _y;
        this->width = _width;
        this->height = _height;
    }

    void Viewport::setGLViewport()
    {
        glViewport(x, y, width, height);
    }

    void Viewport::setGLScissor()
    {
        glScissor(x, y, width, height);
    }

}