//
//  HeadTransform.cpp
//  iosvr
//


#include "HeadTransform.h"
#include <math.h>

namespace iosvr
{

    HeadTransform::HeadTransform() : headView(GLKMatrix4Identity) { }
    
    HeadTransform::~HeadTransform() { }

    void HeadTransform::setHeadView(GLKMatrix4 _headview)
    {
        this->headView = _headview;
    }

    GLKMatrix4 HeadTransform::getHeadView()
    {
        return headView;
    }

    GLKVector3 HeadTransform::translation()
    {
        return GLKVector3Make(headView.m[12], headView.m[13], headView.m[14]);
    }

    GLKVector3 HeadTransform::forwardVector()
    {
        return GLKVector3Make(-headView.m[8], -headView.m[9], -headView.m[10]);
    }

    GLKVector3 HeadTransform::upVector()
    {
        return GLKVector3Make(headView.m[4], headView.m[5], headView.m[6]);
    }

    GLKVector3 HeadTransform::rightVector()
    {
        return GLKVector3Make(headView.m[0], headView.m[1], headView.m[2]);
    }

    GLKQuaternion HeadTransform::quaternion()
    {
        GLfloat t = headView.m[0] + headView.m[5] + headView.m[10];
        GLfloat s, w, x, y, z;
        if (t >= 0.0f)
        {
            s = sqrtf(t + 1.0f);
            w = 0.5f * s;
            s = 0.5f / s;
            x = (headView.m[9] - headView.m[6]) * s;
            y = (headView.m[2] - headView.m[8]) * s;
            z = (headView.m[4] - headView.m[1]) * s;
        }
        else if ((headView.m[0] > headView.m[5]) && (headView.m[0] > headView.m[10]))
            {
                s = sqrtf(1.0f + headView.m[0] - headView.m[5] - headView.m[10]);
                x = s * 0.5f;
                s = 0.5f / s;
                y = (headView.m[4] + headView.m[1]) * s;
                z = (headView.m[2] + headView.m[8]) * s;
                w = (headView.m[9] - headView.m[6]) * s;
            }
        else if (headView.m[5] > headView.m[10])
        {
            s = sqrtf(1.0f + headView.m[5] - headView.m[0] - headView.m[10]);
            y = s * 0.5f;
            s = 0.5f / s;
            x = (headView.m[4] + headView.m[1]) * s;
            z = (headView.m[9] + headView.m[6]) * s;
            w = (headView.m[2] - headView.m[8]) * s;
        }
        else
        {
            s = sqrtf(1.0f + headView.m[10] - headView.m[0] - headView.m[5]);
            z = s * 0.5f;
            s = 0.5f / s;
            x = (headView.m[2] + headView.m[8]) * s;
            y = (headView.m[9] + headView.m[6]) * s;
            w = (headView.m[4] - headView.m[1]) * s;
        }
        
        return GLKQuaternionMake(x, y, z, w);
    }

    GLKVector3 HeadTransform::eulerAngles()
    {
        GLfloat yaw = 0;
        GLfloat roll = 0;
        GLfloat pitch = asinf(headView.m[6]);
        if (sqrtf(1.0f - headView.m[6] * headView.m[6]) >= 0.01f)
        {
            yaw = atan2f(-headView.m[2], headView.m[10]);
            roll = atan2f(-headView.m[4], headView.m[5]);
        }
        else
        {
            yaw = 0.0f;
            roll = atan2f(headView.m[1], headView.m[0]);
        }
        return GLKVector3Make(-pitch, -yaw, -roll);
    }

}