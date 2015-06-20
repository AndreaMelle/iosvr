#include "hfglShader.h"

#include <string>
#include <sstream>
#include <iostream>

namespace hfgl
{
    bool Shader::CompileShader(GLuint *shader, GLenum type, const GLchar *source)
    {
        if (!source)
        {
            std::cerr << "CompileShader: null source" << std::endl;
            return false;
        }
        
        *shader = glCreateShader(type);
        glShaderSource(*shader, 1, &source, NULL);
        glCompileShader(*shader);
        
#if defined(DEBUG)
        GLint logLength = 0;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            std::cout << "CompileShader log: " << log << std::endl;
            free(log);
        }
#endif
        
        GLint status = 0;
        glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
        if (status == 0)
        {
            glDeleteShader(*shader);
            return false;
        }
        
        return true;
    }
    
    bool Shader::LinkProgram(GLuint program)
    {
        GLint status;
        glLinkProgram(program);
        
#if defined(DEBUG)
        GLint logLength;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetProgramInfoLog(program, logLength, &logLength, log);
            std::cout << "LinkProgram log: " << log << std::endl;
            free(log);
        }
#endif
        
        glGetProgramiv(program, GL_LINK_STATUS, &status);
        if (status == 0)
        {
            return false;
        }
        
        return true;
    }
    
    bool Shader::ValidateProgram(GLuint program)
    {
        GLint logLength, status;
        
        glValidateProgram(program);
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetProgramInfoLog(program, logLength, &logLength, log);
            std::cout << "ValidateProgram log " << log <<std::endl;
            free(log);
        }
        
        glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
        if (status == 0)
        {
            return false;
        }
        
        return true;
    }
    
    
    GLuint Shader::BuildProgram(const char* vertSource, const char* fragSource)
    {
        GLuint vertexShader;
        GLuint fragmentShader;
        
        if(!Shader::CompileShader(&vertexShader, GL_VERTEX_SHADER, vertSource))
        {
            exit(1);
        }
        
        if(!Shader::CompileShader(&fragmentShader, GL_FRAGMENT_SHADER, fragSource))
        {
            exit(1);
        }
        
        GLuint programHandle = glCreateProgram();
        glAttachShader(programHandle, vertexShader);
        glAttachShader(programHandle, fragmentShader);
        
        if (!Shader::LinkProgram(programHandle))
        {
            exit(1);
        }
        
        return programHandle;
    }
    
    void Shader::TeardownProgram(GLuint program)
    {
        if ( program )
        {
            glDeleteProgram( program );
            program = 0;
        }
    }
    

    Shader::Shader() { }
    Shader::~Shader() { }
};