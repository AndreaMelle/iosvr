//
//  FieldOfView.cpp
//  iosvr
//

#include "FieldOfView.h"
#include <hfgl/hfglMathUtils.h>

namespace iosvr
{
    
    GLfloat FieldOfView::DefaultViewAngle = 40.0f;

    FieldOfView::FieldOfView() :
        left(DefaultViewAngle),
        right(DefaultViewAngle),
        bottom(DefaultViewAngle),
        top(DefaultViewAngle)
    {
    }

    FieldOfView::FieldOfView(GLfloat _left, GLfloat _right, GLfloat _bottom, GLfloat _top)
    {
        this->left = _left;
        this->right = _right;
        this->bottom = _bottom;
        this->top = _top;
    }
    
    FieldOfView::FieldOfView(const FieldOfView &other)
    {
        this->left = other.left;
        this->right = other.right;
        this->top = other.top;
        this->bottom = other.bottom;
    }

    FieldOfView::~FieldOfView() { }
    
    FieldOfView& FieldOfView::operator=(const FieldOfView &other)
    {
        if (this != &other)
        {
            this->left = other.left;
            this->right = other.right;
            this->top = other.top;
            this->bottom = other.bottom;
        }
        
        return *this;
    }
    
    bool FieldOfView::operator==(const FieldOfView &other) const
    {
        return (this->left == other.left
                && this->right == other.right
                && this->top == other.top
                && this->bottom == other.bottom);
    }
    
    bool FieldOfView::operator!=(const FieldOfView &other) const {
        return !(*this == other);
    }

    void FieldOfView::setLeft(GLfloat _left)
    {
        this->left = _left;
    }

    GLfloat FieldOfView::getLeft()
    {
        return this->left;
    }

    void FieldOfView::setRight(GLfloat _right)
    {
        this->right = _right;
    }

    GLfloat FieldOfView::getRight()
    {
        return right;
    }

    void FieldOfView::setBottom(GLfloat _bottom)
    {
        this->bottom = _bottom;
    }

    GLfloat FieldOfView::getBottom()
    {
        return this->bottom;
    }

    void FieldOfView::setTop(GLfloat _top)
    {
        this->top = _top;
    }

    GLfloat FieldOfView::getTop()
    {
        return this->top;
    }

    GLKMatrix4 FieldOfView::toPerspectiveMatrix(GLfloat near, GLfloat far)
    {
        GLfloat l = -tanf(DEG_TO_RAD(left)) * near;
        GLfloat r = tanf(DEG_TO_RAD(right)) * near;
        GLfloat b = -tanf(DEG_TO_RAD(bottom)) * near;
        GLfloat t = tanf(DEG_TO_RAD(top)) * near;
        
        GLKMatrix4 frustrum = GLKMatrix4MakeFrustum(l, r, b, t, near, far);
        return frustrum;
    }

}