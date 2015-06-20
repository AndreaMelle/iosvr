#include "hfglDebugUtils.h"
#include "hfglVersion.h"
#include <string>
#include <sstream>
#include <iostream>

namespace hfgl
{
    void CheckGlErrors()
    {
        GLenum err = glGetError();
        if (err != GL_NO_ERROR)
        {
            std::cerr << "CheckGlErrors: " << err <<std::endl;
        }
    }
    
    void ClearGLErrors()
    {
        
    }
};