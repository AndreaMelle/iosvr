//
//  Eye.h
//  iosvr
//

#ifndef __IOSVR_EYE_H__
#define __IOSVR_EYE_H__

#include <GLKit/GLKMatrix4.h>
#include <hfgl/hfglVersion.h>

namespace iosvr
{
    class FieldOfView;
    class Viewport;

    class Eye
    {
      public:

        typedef enum EyeType
        {
            EYE_MONOCULAR = 0,
            EYE_LEFT = 1,
            EYE_RIGHT = 2
        } EyeType;

        Eye(EyeType eye);
        virtual ~Eye();

        EyeType getType();

        GLKMatrix4 getEyeView();
        void setEyeView(GLKMatrix4 _eyeView);
        GLKMatrix4 getPerspective(GLfloat zNear, GLfloat zFar);
        
        Viewport *getViewport();
        FieldOfView *getFov();
        
        void setProjectionChanged();
        
      private:
        
        EyeType type;
        GLKMatrix4 eyeView;
        Viewport *viewport;
        FieldOfView *fov;
        bool projectionChanged;
        GLKMatrix4 perspective;
        GLfloat lastZNear;
        GLfloat lastZFar;
    };

};

#endif //__IOSVR_EYE_H__