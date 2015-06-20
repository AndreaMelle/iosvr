//
//  HeadTransform.h
//  iosvr
//

#ifndef __IOSVR__HEAD_TRANSFORM_H__
#define __IOSVR__HEAD_TRANSFORM_H__

#include <stdio.h>
#include <hfgl/hfglVersion.h>
#include <GLKit/GLKVector3.h>
#include <GLKit/GLKMatrix4.h>

namespace iosvr
{
    class HeadTransform
    {
      public:
        HeadTransform();
        virtual ~HeadTransform();

        void setHeadView(GLKMatrix4 headView);
        GLKMatrix4 getHeadView();

        GLKVector3 translation();
        GLKVector3 forwardVector();
        GLKVector3 upVector();
        GLKVector3 rightVector();
        GLKQuaternion quaternion();
        GLKVector3 eulerAngles();

      private:
        GLKMatrix4 headView;
    };

};

#endif //__IOSVR__HEAD_TRANSFORM_H__
