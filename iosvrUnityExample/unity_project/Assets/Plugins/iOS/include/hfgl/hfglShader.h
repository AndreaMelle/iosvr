//
//  hfglShader.h
//  hfgl
//
//  Created by Andrea Melle on 02/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#ifndef __HFGL_SHADER_H__
#define __HFGL_SHADER_H__

#include <stdio.h>
#include "hfglVersion.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

namespace hfgl
{
    class Shader
    {
    public:
        static bool CompileShader(GLuint *shader, GLenum type, const GLchar *source);
        static bool LinkProgram(GLuint program);
        static bool ValidateProgram(GLuint program);
        static GLuint BuildProgram(const char* verSource, const char* fragSource);
        static void TeardownProgram(GLuint program);
        
    protected:
        Shader();
        virtual ~Shader();
        
    };
    
};

#endif //__HFGL_SHADER_H__
