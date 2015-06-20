//
//  Eye.cpp
//  iosvr
//

#include "Eye.h"

#include "FieldOfView.h"
#include "Viewport.h"

namespace iosvr
{

    Eye::Eye(Eye::EyeType eye) :
        type(eye),
        eyeView(GLKMatrix4Identity),
        projectionChanged(true),
        perspective(GLKMatrix4Identity),
        lastZNear(0),
        lastZFar(0)
    {
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

    void Eye::setEyeView(GLKMatrix4 _eyeView)
    {
        this->eyeView = _eyeView;
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