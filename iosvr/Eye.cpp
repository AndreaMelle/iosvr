//
//  Eye.cpp
//  iosvr
//

#include "Eye.h"

#include "FieldOfView.h"
#include "Viewport.h"
#include "CMTransforms.h"

namespace iosvr
{

    Eye::Eye(Eye::EyeType eye) :
        type(eye),
        eyeView(GLKMatrix4Identity),
        perspective(GLKMatrix4Identity),
        projectionChanged(true),
        lastZNear(0),
        lastZFar(0)
    {
        perspectiveMTL = CM::identity();
        viewport = new Viewport();
        fov = new FieldOfView();
    }

    Eye::~Eye()
    {
        if (viewport != 0)
        {
            delete viewport;
        }
        
        if (fov != 0)
        {
            delete fov;
        }
    }

    Eye::EyeType Eye::getType()
    {
        return type;
    }

    GLKMatrix4 Eye::getEyeView()
    {
        return eyeView;
    }
    
    simd::float4x4 Eye::getEyeViewMTL()
    {
        return CM::fromGLKMatrix4(this->getEyeView());
    }

    void Eye::setEyeView(GLKMatrix4 _eyeView)
    {
        this->eyeView = _eyeView;
    }
    
    void Eye::setEyeViewMTL(simd::float4x4 _eyeView)
    {
        this->setEyeView(CM::toGLKMatrix4(_eyeView));
    }

    GLKMatrix4 Eye::getPerspective(GLfloat zNear, GLfloat zFar)
    {
        if (!projectionChanged && lastZNear == zNear && lastZFar == zFar)
        {
            return perspective;
        }
        perspective = fov->toPerspectiveMatrix(zNear, zFar);
        lastZNear = zNear;
        lastZFar = zFar;
        projectionChanged = false;
        return perspective;
    }
    
    simd::float4x4 Eye::getPerspectiveMTL(GLfloat zNear, GLfloat zFar)
    {
        if (!projectionChanged && lastZNear == zNear && lastZFar == zFar)
        {
            return perspectiveMTL;
        }
        perspectiveMTL = fov->toPerspectiveMatrixMTL(zNear, zFar);
        lastZNear = zNear;
        lastZFar = zFar;
        projectionChanged = false;
        return perspectiveMTL;
    }

    Viewport *Eye::getViewport()
    {
        return viewport;
    }

    FieldOfView *Eye::getFov()
    {
        return fov;
    }

    void Eye::setProjectionChanged()
    {
        projectionChanged = true;
    }
}