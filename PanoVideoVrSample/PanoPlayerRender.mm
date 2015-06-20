//
//  PanoPlayerRender.m
//  iosvr
//
//  Created by Andrea Melle on 16/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "PanoPlayerRender.h"
#import <hfgl/hfglDebugUtils.h>
#import <hfgl/hfglShader.h>
#import <OpenGLES/ES2/glext.h>
#include <vector>
#import <AVFoundation/AVFoundation.h>

enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

enum
{
    UNIFORM_SAMPLER,
    UNIFORM_MVP,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

@interface PanoPlayerRender ()
{
    GLKMatrix4 _perspective;
    GLKMatrix4 _model;
    GLKMatrix4 _camera;
    GLKMatrix4 _view;
    GLKMatrix4 _modelViewProjection;
    GLKMatrix4 _modelView;
    GLKMatrix4 _headView;
    
    GLfloat _zNear;
    GLfloat _zFar;
    
    GLuint mSphereVertexBuffer;
    GLuint mSphereProgram;
    GLuint _coordsPerVertex;
    GLsizei mSphereVertexCount;
    
    CVOpenGLESTextureRef _videoTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
}

@end

@implementation PanoPlayerRender


- (instancetype)init
{
    self = [super init];
    if (!self) { return nil; }
    
    _zNear = 0.1f;
    _zFar = 10.0f;
    
    return self;
}

- (void)setupRendererWithView:(GLKView *)glView
{
    [EAGLContext setCurrentContext:glView.context];
    
    [self setupPrograms];
    
    [self setupVAOS];
    
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.2f, 0.2f, 0.2f, 0.5f); // Dark background so text shows up well.
    
    if (!_videoTextureCache)
    {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, glView.context, NULL, &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
    
    //_model = GLKMatrix4Identity;
    //_model = GLKMatrix4MakeRotation(M_PI * 0.5f, 0, 1.0f, 0.0f);
    _model = GLKMatrix4MakeScale(1.0f, -1.0f, 1.0f);
    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
}

- (BOOL)setupPrograms
{
    NSString *path = nil;
    
    GLuint vertexShader = 0;
    path = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    
    const GLchar *source = (GLchar *)[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    if (!hfgl::Shader::CompileShader(&vertexShader, GL_VERTEX_SHADER, source)) {
        NSLog(@"Failed to compile shader at %@", path);
        return NO;
    }
    
    GLuint fragmentShader = 0;
    path = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    source = (GLchar *)[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    if (!hfgl::Shader::CompileShader(&fragmentShader, GL_FRAGMENT_SHADER, source)) {
        NSLog(@"Failed to compile shader at %@", path);
        return NO;
    }
    
    mSphereProgram = glCreateProgram();
    glAttachShader(mSphereProgram, vertexShader);
    glAttachShader(mSphereProgram, fragmentShader);
    
    glBindAttribLocation(mSphereProgram, ATTRIB_VERTEX, "position");
    glBindAttribLocation(mSphereProgram, ATTRIB_TEXCOORD, "texCoord");
    
    hfgl::Shader::LinkProgram(mSphereProgram);
    glUseProgram(mSphereProgram);
    
    uniforms[UNIFORM_SAMPLER] = glGetUniformLocation(mSphereProgram, "tex");
    uniforms[UNIFORM_MVP] = glGetUniformLocation(mSphereProgram, "u_MVPMatrix");
    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
    
    glUseProgram(0);
    
    return YES;
}

- (void)setupVAOS
{
    // Create a sphere
    GLfloat sphereRadius = 5.0f;
    GLint spherePrecision = 32;
    
    GLfloat theta1 = 0.0f;
    GLfloat theta2 = 0.0f;
    GLfloat theta3 = 0.0f;
    
    GLfloat px, py, pz, pu, pv, nx, ny, nz;

    std::vector<GLfloat> sphereData;
    
    for( int i = 0; i < spherePrecision/2; ++i )
    {
        theta1 = i * 2.0f * M_PI / spherePrecision - M_PI * 0.5f;
        theta2 = (i + 1) * 2.0f * M_PI / spherePrecision - M_PI * 0.5f;
        
        for( int j = 0; j <= spherePrecision; ++j )
        {
            theta3 = j * 2.0f * M_PI / spherePrecision;

            nx = cosf(theta2) * cosf(theta3);
            ny = sinf(theta2);
            nz = cosf(theta2) * sinf(theta3);
            
            px = sphereRadius * nx;
            py = sphereRadius * ny;
            pz = sphereRadius * nz;

            pu  = (j / (float)spherePrecision);
            pv  = 2.0f * (i + 1.0f) / (float)spherePrecision;

            sphereData.push_back(px);
            sphereData.push_back(py);
            sphereData.push_back(pz);
            sphereData.push_back(pu);
            sphereData.push_back(pv);

            nx = cosf(theta1) * cosf(theta3);
            ny = sinf(theta1);
            nz = cosf(theta1) * sinf(theta3);
            px = sphereRadius * nx;
            py = sphereRadius * ny;
            pz = sphereRadius * nz;
     
            pu  = (j/(float)spherePrecision);
            pv  = 2.0f * i / (float)spherePrecision;
            
            sphereData.push_back(px);
            sphereData.push_back(py);
            sphereData.push_back(pz);
            sphereData.push_back(pu);
            sphereData.push_back(pv);
        }
    }
    
    _coordsPerVertex = 5;
    
    glGenBuffers(1, &mSphereVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, mSphereVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * sphereData.size(), &(sphereData[0]), GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), 0);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (void*)(3 * sizeof(GLfloat)));
    
    mSphereVertexCount = (GLsizei)sphereData.size() / 5;
    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);

}

- (void)shutdownRendererWithView:(GLKView *)glView
{
    [self cleanUpTextures];
}

- (void)cleanUpTextures
{
    if (_videoTexture) {
        CFRelease(_videoTexture);
        _videoTexture = NULL;
    }
    
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)dealloc
{
    [self cleanUpTextures];
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
}

- (void)renderViewDidChangeSize:(CGSize)size
{
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
    _camera = GLKMatrix4MakeLookAt(0, 0, 0.0f,
                                   0, 0, 1.0,
                                   0, 1.0f, 0);
    _headView = headViewMatrix;
    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
    //GLint activeTexture = 0;
    //glGetIntegerv(GL_ACTIVE_TEXTURE, &activeTexture);
    
    //glEnable(GL_DEPTH_TEST);
    //glDisable(GL_DEPTH_TEST);
    //glClearColor(1.0f, 1.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //glClear(GL_COLOR_BUFFER_BIT);

    
#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
    
    //_view = GLKMatrix4Multiply([eye eyeViewMatrix], _headView);
    _view = GLKMatrix4Multiply(_headView, _camera);
    
    _perspective = [eye perspectiveMatrixWithZNear:_zNear zFar:_zFar];
    
    _modelView = GLKMatrix4Multiply(_view, _model);
    _modelViewProjection = GLKMatrix4Multiply(_perspective, _modelView);
    
    glUseProgram(mSphereProgram);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(CVOpenGLESTextureGetTarget(_videoTexture), CVOpenGLESTextureGetName(_videoTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(uniforms[UNIFORM_SAMPLER], 1);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MVP], 1, false, &(_modelViewProjection.m[0]));
    
    glBindBuffer(GL_ARRAY_BUFFER, mSphereVertexBuffer);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), 0);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (void*)(3 * sizeof(GLfloat)));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, mSphereVertexCount);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glUseProgram(0);
    
    //glActiveTexture(activeTexture);
    
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVReturn err;
    if (pixelBuffer != NULL) {
        GLsizei frameWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
        GLsizei frameHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
        
        if (!_videoTextureCache) {
            NSLog(@"No video texture cache");
            return;
        }
        
        [self cleanUpTextures];
        
        //glActiveTexture(GL_TEXTURE4);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           frameWidth,
                                                           frameHeight,
                                                           GL_BGRA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_videoTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        
        
        CFRelease(pixelBuffer);
    }
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
}


@end
