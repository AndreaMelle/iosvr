//
//  hfglStateBackup.h
//  hfgl
//

#ifndef HFGLGLSTATEBACKUPH
#define HFGLGLSTATEBACKUPH

#include <vector>
#include "hfglVersion.h"

namespace hfgl
{
    class hfglStateBackup
    {
    public:
        
        hfglStateBackup();
        virtual ~hfglStateBackup();
        
        void addTrackedVertexAttribute(GLuint attributeId);
        void clearTrackedVertexAttributes();
        void readFromGL();
        void writeToGL();
    
    private:
        class VertexAttributeState
        {
        public:
            VertexAttributeState(GLuint attributeId);
            
            void readFromGL();
            void writeToGL();
        
        private:
            
            GLuint attributeId;
            GLint enabled;
        };
        

        GLint viewport[4];
        bool cullFaceEnabled;
        bool scissorTestEnabled;
        bool depthTestEnabled;
        GLfloat clearColor[4];
        GLint shaderProgram;
        GLint scissorBox[4];
        GLint activeTexture;
        GLint texture2DBinding;
        GLint arrayBufferBinding;
        GLint elementArrayBufferBinding;
        std::vector<VertexAttributeState> vertexAttributes;
    };

};

#endif //HFGLGLSTATEBACKUPH
