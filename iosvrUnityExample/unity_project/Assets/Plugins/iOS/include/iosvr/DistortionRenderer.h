//
//  DistortionRenderer.h
//  iosvr
//

#ifndef __IOSVR_DISTORTION_RENDERER_H__
#define __IOSVR_DISTORTION_RENDERER_H__

#include <stdio.h>
#include <hfgl/hfglVersion.h>

namespace hfgl
{
    class hfglStateBackup;
};

namespace iosvr
{
    class Distortion;
    class Eye;
    class FieldOfView;
    class HeadMountedDisplay;
    class Viewport;
    class DistortionProgramHolder;
    class DistortionMesh;

    class DistortionRenderer
    {
    public:
        
        DistortionRenderer();
        virtual ~DistortionRenderer();
        
        void beforeDrawFrame();
        void afterDrawFrame();
        
        void setResolutionScale(GLfloat scale);
        
        bool getRestoreGLStateEnabled();
        void setRestoreGLStateEnabled(bool enabled);
        
        bool getChromaticAberrationEnabled();
        void setChromaticAberrationEnabled(bool enabled);
        
        bool getVignetteEnabled();
        void setVignetteEnabled(bool enabled);
        
        bool getViewportsChanged();
        void updateViewports(Viewport *leftViewport, Viewport *rightViewport);

        void onFovDidChange(HeadMountedDisplay *hmd, FieldOfView *leftEyeFov, FieldOfView *rightEyeFov, GLfloat virtualEyeToScreenDistance);
        
        void undistortTexture(GLint textureID);
        
        void setTextureFormat(GLint textureFormat, GLint textureType);
    
    private:
        
        class EyeViewport
        {
        public:
            GLfloat x;
            GLfloat y;
            GLfloat width;
            GLfloat height;
            GLfloat eyeX;
            GLfloat eyeY;
        };
        
        GLuint mTextureID;
        GLuint mRenderbufferID;
        GLuint mFramebufferID;
        GLuint mOriginalFramebufferID;
        GLenum mTextureFormat;
        GLenum mTextureType;
        GLfloat mResolutionScale;
        bool mRestoreGLStateEnabled;
        bool mChromaticAberrationCorrectionEnabled;
        bool mVignetteEnabled;
        DistortionMesh *mLeftEyeDistortionMesh;
        DistortionMesh *mRightEyeDistortionMesh;
        hfgl::hfglStateBackup *mGlStateBackup;
        hfgl::hfglStateBackup *mGlStateBackupAberration;
        HeadMountedDisplay *mHeadMountedDisplay;
        EyeViewport *mLeftEyeViewport;
        EyeViewport *mRightEyeViewport;
        bool mFovsChanged;
        bool mViewportsChanged;
        bool mTextureFormatChanged;
        bool mDrawingFrame;
        GLfloat mXPxPerTanAngle;
        GLfloat mYPxPerTanAngle;
        GLfloat mMetersPerTanAngle;
        
        DistortionProgramHolder* mProgramHolder;
        DistortionProgramHolder* mProgramHolderAberration;
        
        EyeViewport *initViewportForEye(FieldOfView *eyeFieldOfView, GLfloat xOffsetM);
        
        
        void updateTextureAndDistortionMesh();
        

        DistortionMesh* createDistortionMesh(EyeViewport *eyeViewport,
                                             GLfloat textureWidthTanAngle,
                                             GLfloat textureHeightTanAngle,
                                             GLfloat xEyeOffsetTanAngleScreen,
                                             GLfloat yEyeOffsetTanAngleScreen);
        
        void renderDistortionMesh(DistortionMesh *mesh, GLint textureID);
        
        GLfloat computeDistortionScale(Distortion *distortion, GLfloat screenWidthM, GLfloat interpupillaryDistanceM);
        
        GLuint createTexture(GLint width, GLint height, GLint textureFormat, GLint textureType);
        GLuint setupRenderTextureAndRenderbuffer(GLint width, GLint height);
        GLuint createProgram(const GLchar *vertexSource, const GLchar *fragmentSource);
        
        DistortionProgramHolder *createProgramHolder(bool aberrationCorrected);
    };

};

#endif //__IOSVR_DISTORTION_RENDERER_H__
