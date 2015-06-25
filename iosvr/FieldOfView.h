//
//  FieldOfView.h
//  iosvr
//

#ifndef __IOSVR__FIELD_OF_VIEW_H__
#define __IOSVR__FIELD_OF_VIEW_H__

#include <hfgl/hfglVersion.h>
#include <GLKit/GLKMatrix4.h>
#include <simd/simd.h>

namespace iosvr
{
    class FieldOfView
    {
      public:
        
        FieldOfView();
        FieldOfView(GLfloat _left, GLfloat _right, GLfloat _bottom, GLfloat _top);
        FieldOfView(const FieldOfView &other);
        
        virtual ~FieldOfView();
        
        FieldOfView& operator=(const FieldOfView &other);
        
        bool operator==(const FieldOfView &other) const;
        bool operator!=(const FieldOfView &other) const;

        void setLeft(GLfloat _left);
        GLfloat getLeft();

        void setRight(GLfloat _right);
        GLfloat getRight();

        void setBottom(GLfloat _bottom);
        GLfloat getBottom();

        void setTop(GLfloat _top);
        GLfloat getTop();
        
        GLKMatrix4 toPerspectiveMatrix(GLfloat near, GLfloat far);
        simd::float4x4 toPerspectiveMatrixMTL(float near, float far);

      private:
        
        static GLfloat DefaultViewAngle;

        GLfloat left;
        GLfloat right;
        GLfloat bottom;
        GLfloat top;
    };
    
};

#endif //__IOSVR__FIELD_OF_VIEW_H__
