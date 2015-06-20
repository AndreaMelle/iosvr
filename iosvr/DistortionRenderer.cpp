//
//  DistortionRenderer.cpp
//  iosvr
//


#include "DistortionRenderer.h"

#include "CardboardDeviceParams.h"
#include "Distortion.h"
#include "Eye.h"
#include "FieldOfView.h"
#include <hfgl/hfglStateBackup.h>
#include "HeadMountedDisplay.h"
#include "ScreenParams.h"
#include "Viewport.h"
#include "DistortionMesh.h"
#include "DistortionProgramHolder.h"

#include <hfgl/hfglDebugUtils.h>
#include <hfgl/hfglMathUtils.h>
#include <hfgl/hfglShader.h>

#include <iostream>
#include <math.h>

namespace iosvr
{

    DistortionRenderer::DistortionRenderer() :
        mTextureID(-1),
        mRenderbufferID(-1),
        mFramebufferID(-1),
        // originalFramebufferID(-1),
        mTextureFormat(GL_RGB),
        mTextureType(GL_UNSIGNED_BYTE),
        mResolutionScale(1.0f),
        mRestoreGLStateEnabled(true),
        mChromaticAberrationCorrectionEnabled(false),
        mVignetteEnabled(true),
        mLeftEyeDistortionMesh(0),
        mRightEyeDistortionMesh(0),
        mGlStateBackup(0),
        mGlStateBackupAberration(0),
        mHeadMountedDisplay(0),
        mLeftEyeViewport(0),
        mRightEyeViewport(0),
        mFovsChanged(false),
        mViewportsChanged(false),
        mTextureFormatChanged(false),
        mDrawingFrame(false),
        mXPxPerTanAngle(0),
        mYPxPerTanAngle(0),
        mMetersPerTanAngle(0),
        mProgramHolder(0),
        mProgramHolderAberration(0)
    {
        mGlStateBackup = new hfgl::hfglStateBackup();
        mGlStateBackupAberration = new hfgl::hfglStateBackup();
    }

    DistortionRenderer::~DistortionRenderer()
    {
        if (mGlStateBackup != 0) { delete mGlStateBackup; }
        if (mGlStateBackupAberration != 0) { delete mGlStateBackupAberration; }
        
        if (mLeftEyeDistortionMesh != 0) { delete mLeftEyeDistortionMesh; }
        if (mRightEyeDistortionMesh != 0) { delete mRightEyeDistortionMesh; }
            
        if (mLeftEyeViewport != 0) { delete mLeftEyeViewport; }
        if (mRightEyeViewport != 0) { delete mRightEyeViewport; }
        
        if (mProgramHolder != 0) { delete mProgramHolder; }
        if (mProgramHolderAberration != 0) { delete mProgramHolderAberration; }
    }

    void DistortionRenderer::setTextureFormat(GLint _textureFormat, GLint _textureType)
    {
        if (mDrawingFrame)
        {
            std::cerr << "Cannot change texture format during rendering" << std::endl;
        }
        else if (this->mTextureFormat != _textureFormat || this->mTextureType != _textureType)
        {
            this->mTextureFormat = _textureFormat;
            this->mTextureType = _textureType;
            mTextureFormatChanged = true;
        }
    }

    void DistortionRenderer::beforeDrawFrame()
    {
        mDrawingFrame = true;
        
        if (mFovsChanged || mTextureFormatChanged)
        {
            updateTextureAndDistortionMesh();
        }
        
        // glGetIntegerv(GL_FRAMEBUFFER_BINDING, &originalFramebufferID);
        glBindFramebuffer(GL_FRAMEBUFFER, mFramebufferID);
    }

    void DistortionRenderer::afterDrawFrame()
    {
        // glBindFramebuffer(GL_FRAMEBUFFER, originalFramebufferID);
        undistortTexture(mTextureID);
        mDrawingFrame = false;
    }

    void DistortionRenderer::undistortTexture(GLint _textureID)
    {
        if (mRestoreGLStateEnabled) {
            if (mChromaticAberrationCorrectionEnabled)
            {
                mGlStateBackupAberration->readFromGL();
            }
            else
            {
                mGlStateBackup->readFromGL();
            }
        }
        if (mFovsChanged || mTextureFormatChanged)
        {
            updateTextureAndDistortionMesh();
        }

        ScreenParams *screen = mHeadMountedDisplay->getScreen();
        glViewport(0, 0, screen->getWidth(), screen->getHeight());
        
        glDisable(GL_CULL_FACE);
        glDisable(GL_SCISSOR_TEST);
        
        glClearColor(0.0F, 0.0F, 0.0F, 1.0F);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        if (mChromaticAberrationCorrectionEnabled)
        {
            glUseProgram(mProgramHolderAberration->program);
        }
        else
        {
            glUseProgram(mProgramHolder->program);
        }
        
        glEnable(GL_SCISSOR_TEST);
        
        glScissor(0, 0, screen->getWidth() / 2, screen->getHeight());
        
        renderDistortionMesh(mLeftEyeDistortionMesh, _textureID);
        
        glScissor(screen->getWidth() / 2, 0, screen->getWidth() / 2, screen->getHeight());
        
        renderDistortionMesh(mRightEyeDistortionMesh, _textureID);

        if (mRestoreGLStateEnabled)
        {
            if (mChromaticAberrationCorrectionEnabled)
            {
                mGlStateBackupAberration->writeToGL();
            }
            else
            {
                mGlStateBackup->writeToGL();
            }
        }
        
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
    }

    void DistortionRenderer::setResolutionScale(GLfloat _scale)
    {
        mResolutionScale = _scale;
        mViewportsChanged = true;
    }

    bool DistortionRenderer::getRestoreGLStateEnabled()
    {
        return mRestoreGLStateEnabled;;
    }

    void DistortionRenderer::setRestoreGLStateEnabled(bool enabled)
    {
        mRestoreGLStateEnabled = enabled;
    }

    bool DistortionRenderer::getChromaticAberrationEnabled()
    {
        return mChromaticAberrationCorrectionEnabled;
    }

    void DistortionRenderer::setChromaticAberrationEnabled(bool enabled)
    {
        mChromaticAberrationCorrectionEnabled = enabled;
    }

    bool DistortionRenderer::getVignetteEnabled()
    {
        return mVignetteEnabled;;
    }

    void DistortionRenderer::setVignetteEnabled(bool enabled)
    {
        mVignetteEnabled = enabled;
        mFovsChanged = true;
    }

    void DistortionRenderer::onFovDidChange(HeadMountedDisplay *_headMountedDisplay,
                                            FieldOfView *_leftEyeFov,
                                            FieldOfView *_rightEyeFov,
                                            GLfloat _virtualEyeToScreenDistance)
    {
        if (mDrawingFrame)
        {
            std::cerr << "Cannot change FOV while rendering a frame." << std::endl;
            return;
        }
        
        this->mHeadMountedDisplay = _headMountedDisplay;
        if (mLeftEyeViewport != 0) { delete mLeftEyeViewport; }
        if (mRightEyeViewport != 0) { delete mRightEyeViewport; }
        mLeftEyeViewport = initViewportForEye(_leftEyeFov, 0.0f);
        mRightEyeViewport = initViewportForEye(_rightEyeFov, mLeftEyeViewport->width);
        mMetersPerTanAngle = _virtualEyeToScreenDistance;
        ScreenParams *screen = _headMountedDisplay->getScreen();
        mXPxPerTanAngle = screen->getWidth() / ( screen->getWidthInMeters() / mMetersPerTanAngle );
        mYPxPerTanAngle = screen->getHeight() / ( screen->getHeightInMeters() / mMetersPerTanAngle );
        mFovsChanged = true;
        mViewportsChanged = true;
    }

    bool DistortionRenderer::getViewportsChanged()
    {
        return mViewportsChanged;
    }

    void DistortionRenderer::updateViewports(Viewport *_leftViewport, Viewport *_rightViewport)
    {
        
        _leftViewport->setViewport(roundf(mLeftEyeViewport->x * mXPxPerTanAngle * mResolutionScale),
                                  roundf(mLeftEyeViewport->y * mYPxPerTanAngle * mResolutionScale),
                                  roundf(mLeftEyeViewport->width * mXPxPerTanAngle * mResolutionScale),
                                  roundf(mLeftEyeViewport->height * mYPxPerTanAngle * mResolutionScale));
        _rightViewport->setViewport(roundf(mRightEyeViewport->x * mXPxPerTanAngle * mResolutionScale),
                                   roundf(mRightEyeViewport->y * mYPxPerTanAngle * mResolutionScale),
                                   roundf(mRightEyeViewport->width * mXPxPerTanAngle * mResolutionScale),
                                   roundf(mRightEyeViewport->height * mYPxPerTanAngle * mResolutionScale));
        mViewportsChanged = false;
    }

    void DistortionRenderer::updateTextureAndDistortionMesh()
    {
        ScreenParams *screen = mHeadMountedDisplay->getScreen();
        CardboardDeviceParams *cardboardDeviceParams = mHeadMountedDisplay->getCardboard();
        
        if (mProgramHolder == 0)
        {
            mProgramHolder = createProgramHolder(false);
        }
        if (mProgramHolderAberration == 0)
        {
            mProgramHolderAberration = createProgramHolder(true);
        }

        GLfloat textureWidthTanAngle = mLeftEyeViewport->width + mRightEyeViewport->width;
        GLfloat textureHeightTanAngle = std::max(mLeftEyeViewport->height, mRightEyeViewport->height);
        GLint maxTextureSize = 0;

        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
        GLint textureWidthPx = std::min<float>(round(textureWidthTanAngle * mXPxPerTanAngle), maxTextureSize);
        GLint textureHeightPx = std::min<float>(round(textureHeightTanAngle * mYPxPerTanAngle), maxTextureSize);
        
        GLfloat xEyeOffsetTanAngleScreen =
            (screen->getWidthInMeters() / 2.0f - cardboardDeviceParams->getInterLensDistance() / 2.0f) / mMetersPerTanAngle;
        GLfloat yEyeOffsetTanAngleScreen =
            (cardboardDeviceParams->getVerticalDistanceToLensCenter() - screen->getBorderSizeInMeters()) / mMetersPerTanAngle;
        
        if (mLeftEyeDistortionMesh != 0) { delete mLeftEyeDistortionMesh; }
        if (mRightEyeDistortionMesh != 0) { delete mRightEyeDistortionMesh; }
        
        mLeftEyeDistortionMesh = createDistortionMesh(mLeftEyeViewport, textureWidthTanAngle, textureHeightTanAngle, xEyeOffsetTanAngleScreen, yEyeOffsetTanAngleScreen);
        
        xEyeOffsetTanAngleScreen = screen->getWidthInMeters() / mMetersPerTanAngle - xEyeOffsetTanAngleScreen;
        
        mRightEyeDistortionMesh = createDistortionMesh(mRightEyeViewport,
                                                       textureWidthTanAngle, textureHeightTanAngle,
                                                       xEyeOffsetTanAngleScreen, yEyeOffsetTanAngleScreen);
        setupRenderTextureAndRenderbuffer(textureWidthPx, textureHeightPx);
        
        mFovsChanged = false;
    }

    DistortionRenderer::EyeViewport *DistortionRenderer::initViewportForEye(FieldOfView *_eyeFieldOfView, GLfloat _xOffset)
    {
        GLfloat left = tanf(DEG_TO_RAD(_eyeFieldOfView->getLeft()));
        GLfloat right = tanf(DEG_TO_RAD(_eyeFieldOfView->getRight()));
        GLfloat bottom = tanf(DEG_TO_RAD(_eyeFieldOfView->getBottom()));
        GLfloat top = tanf(DEG_TO_RAD(_eyeFieldOfView->getTop()));
        
        EyeViewport *eyeViewport = new EyeViewport();
        eyeViewport->x = _xOffset;
        eyeViewport->y = 0.0f;
        eyeViewport->width = (left + right);
        eyeViewport->height = (bottom + top);
        eyeViewport->eyeX = (left + _xOffset);
        eyeViewport->eyeY = bottom;
        
        return eyeViewport;
    }

    DistortionMesh* DistortionRenderer::createDistortionMesh(EyeViewport *_eyeViewport,
                                                             GLfloat _textureWidthTanAngle,
                                                             GLfloat _textureHeightTanAngle,
                                                             GLfloat _xEyeOffsetTanAngleScreen,
                                                             GLfloat _yEyeOffsetTanAngleScreen)
    {
        return new DistortionMesh(mHeadMountedDisplay->getCardboard()->getDistortion(),
                                  mHeadMountedDisplay->getCardboard()->getDistortion(),
                                  mHeadMountedDisplay->getCardboard()->getDistortion(),
                                  mHeadMountedDisplay->getScreen()->getWidthInMeters() / mMetersPerTanAngle,
                                  mHeadMountedDisplay->getScreen()->getHeightInMeters() / mMetersPerTanAngle,
                                  _xEyeOffsetTanAngleScreen, _yEyeOffsetTanAngleScreen,
                                  _textureWidthTanAngle, _textureHeightTanAngle,
                                  _eyeViewport->eyeX, _eyeViewport->eyeY,
                                  _eyeViewport->x, _eyeViewport->y,
                                  _eyeViewport->width, _eyeViewport->height,
                                  mVignetteEnabled);
    }

    void DistortionRenderer::renderDistortionMesh(DistortionMesh *_mesh, GLint _textureID)
    {
        DistortionProgramHolder *_programHolder = 0;
        if (mChromaticAberrationCorrectionEnabled)
        {
            _programHolder = this->mProgramHolderAberration;
        }
        else
        {
            _programHolder = this->mProgramHolder;
        }

        glBindBuffer(GL_ARRAY_BUFFER, _mesh->arrayBufferID);
        glVertexAttribPointer(_programHolder->positionLocation, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), (void *)(0 * sizeof(GLfloat)));
        glEnableVertexAttribArray(_programHolder->positionLocation);
        glVertexAttribPointer(_programHolder->vignetteLocation, 1, GL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), (void *)(2 * sizeof(GLfloat)));
        glEnableVertexAttribArray(_programHolder->vignetteLocation);
        glVertexAttribPointer(_programHolder->blueTextureCoordLocation, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), (void *)(7 * sizeof(GLfloat)));
        glEnableVertexAttribArray(_programHolder->blueTextureCoordLocation);
        
        if (mChromaticAberrationCorrectionEnabled)
        {
            glVertexAttribPointer(_programHolder->redTextureCoordLocation, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), (void *)(3 * sizeof(GLfloat)));
            glEnableVertexAttribArray(_programHolder->redTextureCoordLocation);
            glVertexAttribPointer(_programHolder->greenTextureCoordLocation, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat), (void *)(5 * sizeof(GLfloat)));
            glEnableVertexAttribArray(_programHolder->greenTextureCoordLocation);
        }
        
        glActiveTexture(GL_TEXTURE7);
        glBindTexture(GL_TEXTURE_2D, _textureID);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        
        glUniform1i(_programHolder->uTextureSamplerLocation, 7);
        glUniform1f(_programHolder->uTextureCoordScaleLocation, mResolutionScale);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _mesh->elementBufferID);
        glDrawElements(GL_TRIANGLE_STRIP, _mesh->indices, GL_UNSIGNED_SHORT, 0);
        
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
    }

    GLfloat DistortionRenderer::computeDistortionScale(Distortion *_distortion, GLfloat _screenWidthM, GLfloat _interpupillaryDistanceM)
    {
        return _distortion->getDistortionFactor((_screenWidthM / 2.0f - _interpupillaryDistanceM / 2.0f) / (_screenWidthM / 4.0f));
    }

    GLuint DistortionRenderer::createTexture(GLint _width, GLint _height, GLint _textureFormat, GLint _textureType)
    {
        GLuint _textureID = 0;
        glGenTextures(1, &_textureID);
        glBindTexture(GL_TEXTURE_2D, _textureID);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, _textureFormat, _width, _height, 0, _textureFormat, _textureType, 0);
        
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif

        return _textureID;
    }

    GLuint DistortionRenderer::setupRenderTextureAndRenderbuffer(GLint _width, GLint _height)
    {
        if (mTextureID != -1)
        {
            glDeleteTextures(1, &mTextureID);
        }
        if (mRenderbufferID != -1)
        {
            glDeleteRenderbuffers(1, &mRenderbufferID);
        }
        if (mFramebufferID != -1)
        {
            glDeleteFramebuffers(1, &mFramebufferID);
        }
        
        mTextureID = createTexture(_width, _height, mTextureFormat, mTextureType);
        mTextureFormatChanged = false;
        
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
        
        glGenRenderbuffers(1, &mRenderbufferID);
        glBindRenderbuffer(GL_RENDERBUFFER, mRenderbufferID);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _width, _height);
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
        
        glGenFramebuffers(1, &mFramebufferID);
        glBindFramebuffer(GL_FRAMEBUFFER, mFramebufferID);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, mTextureID, 0);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mRenderbufferID);
        
        GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        if (status != GL_FRAMEBUFFER_COMPLETE)
        {
            std::cerr << "DistortionRenderer: Framebuffer is not complete " << status << std::endl;
            return 0;
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif

        return mFramebufferID;
    }

    GLuint DistortionRenderer::createProgram(const GLchar *vertexSource, const GLchar *fragmentSource)
    {
        GLuint vertexShader = 0;
        hfgl::Shader::CompileShader(&vertexShader, GL_VERTEX_SHADER, vertexSource);
        if (vertexShader == 0)
        {
            return 0;
        }
        GLuint pixelShader = 0;
        hfgl::Shader::CompileShader(&pixelShader, GL_FRAGMENT_SHADER, fragmentSource);
        if (pixelShader == 0)
        {
            return 0;
        }
        GLuint program = glCreateProgram();
        if (program != 0)
        {
            glAttachShader(program, vertexShader);
#if defined(DEBUG)
            hfgl::CheckGlErrors();
#endif
            glAttachShader(program, pixelShader);
#if defined(DEBUG)
            hfgl::CheckGlErrors();
#endif
            hfgl::Shader::LinkProgram(program);
            GLint status;
            glGetProgramiv(program, GL_LINK_STATUS, &status);
            if (status == GL_FALSE)
            {
                GLchar message[256];
                glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
                std::cerr << "Could not link program: " << message << std::endl;
                glDeleteProgram(program);
                program = 0;
            }
        }
        
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif

        return program;
    }

    DistortionProgramHolder *DistortionRenderer::createProgramHolder(bool aberrationCorrected)
    {
        const GLchar *vertexShader =
        "\
        attribute vec2 aPosition;\n\
        attribute float aVignette;\n\
        attribute vec2 aBlueTextureCoord;\n\
        varying vec2 vTextureCoord;\n\
        varying float vVignette;\n\
        uniform float uTextureCoordScale;\n\
        void main() {\n\
        gl_Position = vec4(aPosition, 0.0, 1.0);\n\
        vTextureCoord = aBlueTextureCoord.xy * uTextureCoordScale;\n\
        vVignette = aVignette;\n\
        }\n";
        
        const GLchar *fragmentShader =
        "\
        precision mediump float;\n\
        varying vec2 vTextureCoord;\n\
        varying float vVignette;\n\
        uniform sampler2D uTextureSampler;\n\
        void main() {\n\
        gl_FragColor = vVignette * texture2D(uTextureSampler, vTextureCoord);\n\
        }\n";
        
        const GLchar *vertexShaderAberration =
        "\
        attribute vec2 aPosition;\n\
        attribute float aVignette;\n\
        attribute vec2 aRedTextureCoord;\n\
        attribute vec2 aGreenTextureCoord;\n\
        attribute vec2 aBlueTextureCoord;\n\
        varying vec2 vRedTextureCoord;\n\
        varying vec2 vBlueTextureCoord;\n\
        varying vec2 vGreenTextureCoord;\n\
        varying float vVignette;\n\
        uniform float uTextureCoordScale;\n\
        void main() {\n\
        gl_Position = vec4(aPosition, 0.0, 1.0);\n\
        vRedTextureCoord = aRedTextureCoord.xy * uTextureCoordScale;\n\
        vGreenTextureCoord = aGreenTextureCoord.xy * uTextureCoordScale;\n\
        vBlueTextureCoord = aBlueTextureCoord.xy * uTextureCoordScale;\n\
        vVignette = aVignette;\n\
        }\n";
        
        const GLchar *fragmentShaderAberration =
        
        "\
        precision mediump float;\n\
        varying vec2 vRedTextureCoord;\n\
        varying vec2 vBlueTextureCoord;\n\
        varying vec2 vGreenTextureCoord;\n\
        varying float vVignette;\n\
        uniform sampler2D uTextureSampler;\n\
        void main() {\n\
        gl_FragColor = vVignette * vec4(texture2D(uTextureSampler, vRedTextureCoord).r,\n\
        texture2D(uTextureSampler, vGreenTextureCoord).g,\n\
        texture2D(uTextureSampler, vBlueTextureCoord).b, 1.0);\n\
        }\n";

        
        DistortionProgramHolder *holder = new DistortionProgramHolder();
        hfgl::hfglStateBackup *state = 0;
        if (aberrationCorrected)
        {
            holder->program = createProgram(vertexShaderAberration, fragmentShaderAberration);
            state = mGlStateBackupAberration;
        }
        else
        {
            holder->program = createProgram(vertexShader, fragmentShader);
            state = mGlStateBackup;
        }
        if (holder->program == 0)
        {
            std::cerr << "DistortionRenderer Could not create program" << std::endl;
            delete holder;
            return 0;
        }
        
        holder->positionLocation = glGetAttribLocation(holder->program, "aPosition");
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
        if (holder->positionLocation == -1)
        {
            std::cerr << "DistortionRenderer Could not get attrib location for aPosition" << std::endl;
            delete holder;
            return 0;
        }
        state->addTrackedVertexAttribute(holder->positionLocation);
        
        holder->vignetteLocation = glGetAttribLocation(holder->program, "aVignette");
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
        if (holder->vignetteLocation == -1)
        {
            std::cerr << "DistortionRenderer Could not get attrib location for aVignette" << std::endl;
            delete holder;
            return 0;
        }
        state->addTrackedVertexAttribute(holder->vignetteLocation);
        
        if (aberrationCorrected)
        {
            holder->redTextureCoordLocation = glGetAttribLocation(holder->program, "aRedTextureCoord");
#if defined(DEBUG)
            hfgl::CheckGlErrors();
#endif
            if (holder->redTextureCoordLocation == -1)
            {
                std::cerr << "DistortionRenderer Could not get attrib location for aRedTextureCoord" << std::endl;
                delete holder;
                return 0;
            }
            state->addTrackedVertexAttribute(holder->redTextureCoordLocation);
            
            holder->greenTextureCoordLocation = glGetAttribLocation(holder->program, "aGreenTextureCoord");
#if defined(DEBUG)
            hfgl::CheckGlErrors();
#endif
            if (holder->greenTextureCoordLocation == -1)
            {
                std::cerr << "DistortionRenderer Could not get attrib location for aGreenTextureCoord" << std::endl;
                delete holder;
                return 0;
            }
            state->addTrackedVertexAttribute(holder->greenTextureCoordLocation);
        }
        
        holder->blueTextureCoordLocation = glGetAttribLocation(holder->program, "aBlueTextureCoord");
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
        if (holder->blueTextureCoordLocation == -1)
        {
            std::cerr << "DistortionRenderer Could not get attrib location for aBlueTextureCoord" << std::endl;
            delete holder;
            return 0;
        }
        state->addTrackedVertexAttribute(holder->blueTextureCoordLocation);
        
        holder->uTextureCoordScaleLocation = glGetUniformLocation(holder->program, "uTextureCoordScale");
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
        if (holder->uTextureCoordScaleLocation == -1)
        {
            std::cerr << "DistortionRenderer Could not get attrib location for uTextureCoordScale" << std::endl;
            delete holder;
            return 0;
        }
        
        holder->uTextureSamplerLocation = glGetUniformLocation(holder->program, "uTextureSampler");
#if defined(DEBUG)
        hfgl::CheckGlErrors();
#endif
        if (holder->uTextureSamplerLocation == -1)
        {
            std::cerr << "Could not get attrib location for uTextureSampler" << std::endl;
            delete holder;
            return 0;
        }
        
        return holder;
    }

}