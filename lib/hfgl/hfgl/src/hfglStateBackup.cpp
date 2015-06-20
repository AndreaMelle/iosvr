//
//  hfhfglStateBackup.cpp
//  hfgl
//

#include "hfglStateBackup.h"

namespace hfgl
{

    hfglStateBackup::VertexAttributeState::VertexAttributeState(GLuint attributeId) :
        attributeId(attributeId),
        enabled(false)
    {
    }
    
    void hfglStateBackup::VertexAttributeState::readFromGL()
    {
        glGetVertexAttribiv(attributeId, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &enabled);
    }

    void hfglStateBackup::VertexAttributeState::writeToGL() {
        if (enabled == false)
        {
            glDisableVertexAttribArray(attributeId);
        }
        else
        {
            glEnableVertexAttribArray(attributeId);
        }
    }


    hfglStateBackup::hfglStateBackup() :
        cullFaceEnabled(false),
        scissorTestEnabled(false),
        depthTestEnabled(false),
        shaderProgram(-1),
        activeTexture(-1),
        texture2DBinding(-1),
        arrayBufferBinding(-1),
        elementArrayBufferBinding(-1)
    {
        for (size_t i = 0; i < 4; i++)
        {
            viewport[i] = 0;
            clearColor[i] = 0;
            scissorBox[i] = 0;
        }
        
    }
    
    hfglStateBackup::~hfglStateBackup()
    {
        
    }

    void hfglStateBackup::addTrackedVertexAttribute(GLuint attributeId)
    {
        vertexAttributes.push_back(VertexAttributeState(attributeId));
    }

    void hfglStateBackup::clearTrackedVertexAttributes()
    {
        vertexAttributes.clear();
    }

    void hfglStateBackup::readFromGL()
    {
        glGetIntegerv(GL_VIEWPORT, viewport);
        cullFaceEnabled = glIsEnabled(GL_CULL_FACE);
        scissorTestEnabled = glIsEnabled(GL_SCISSOR_TEST);
        depthTestEnabled = glIsEnabled(GL_DEPTH_TEST);
        glGetFloatv(GL_COLOR_CLEAR_VALUE, clearColor);
        glGetIntegerv(GL_CURRENT_PROGRAM, &shaderProgram);
        glGetIntegerv(GL_SCISSOR_BOX, scissorBox);
        glGetIntegerv(GL_ACTIVE_TEXTURE, &activeTexture);
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &texture2DBinding);
        glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &arrayBufferBinding);
        glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &elementArrayBufferBinding);
        
        for (std::vector<VertexAttributeState>::iterator it = vertexAttributes.begin();
             it != vertexAttributes.end();
             ++it)
        {
            (*it).readFromGL();
        }
    }

    void hfglStateBackup::writeToGL()
    {
        for (std::vector<VertexAttributeState>::iterator it = vertexAttributes.begin();
             it != vertexAttributes.end();
             ++it)
        {
            (*it).writeToGL();
        }
        
        glBindBuffer(GL_ARRAY_BUFFER, arrayBufferBinding);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementArrayBufferBinding);
        glBindTexture(GL_TEXTURE_2D, texture2DBinding);
        glActiveTexture(activeTexture);
        glScissor(scissorBox[0], scissorBox[1], scissorBox[2], scissorBox[3]);
        glUseProgram(shaderProgram);
        glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3]);
        
        if (cullFaceEnabled)
        {
            glEnable(GL_CULL_FACE);
        }
        else
        {
            glDisable(GL_CULL_FACE);
        }
        if (scissorTestEnabled)
        {
            glEnable(GL_SCISSOR_TEST);
        }
        else
        {
            glDisable(GL_SCISSOR_TEST);
        }
        if (depthTestEnabled)
        {
            glEnable(GL_DEPTH_TEST);
        }
        else
        {
            glDisable(GL_DEPTH_TEST);
        }
        
        glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    }

}