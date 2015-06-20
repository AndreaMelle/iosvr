//
//  Distortion.cpp
//  iosvr
//

#include "Distortion.h"
#include <math.h>
#include <hfgl/hfglMathUtils.h>

namespace iosvr
{
    GLfloat Distortion::DefaultCoefficients[NUM_COEFFICIENTS] = {0.441f, 0.156f};
    
    Distortion::Distortion()
    {
        for (size_t i = 0; i < NUM_COEFFICIENTS; ++i)
        {
            coefficients[i] = DefaultCoefficients[i];
        }
    }
    
    Distortion::~Distortion()
    {
        
    }

    Distortion::Distortion(const Distortion &other)
    {
        for (size_t i = 0; i < NUM_COEFFICIENTS; ++i)
        {
            this->coefficients[i] = other.coefficients[i];
        }
    }
        
    Distortion& Distortion::operator=(const Distortion &other)
    {
        if (this != &other)
        {
            for (size_t i = 0; i < NUM_COEFFICIENTS; ++i)
            {
                this->coefficients[i] = other.coefficients[i];
            }
        }
        
        return *this;
    }
        
    bool Distortion::operator==(const Distortion &other) const
    {
        for (size_t i = 0; i < NUM_COEFFICIENTS; ++i)
        {
            if (this->coefficients[i] != other.coefficients[i])
            {
                return false;
            }
        }
        
        return true;
    }
    
    bool Distortion::operator!=(const Distortion &other) const
    {
        return !(*this == other);
    }

    void Distortion::setCoefficients(GLfloat *coefficients)
    {
        for (size_t i = 0; i < NUM_COEFFICIENTS; i++)
        {
            coefficients[i] = coefficients[i];
        }
    }

    GLfloat *Distortion::getCoefficients()
    {
        return coefficients;
    }

    GLfloat Distortion::getDistortionFactor(GLfloat radius)
    {
        GLfloat result = 1.0f;
        GLfloat rFactor = 1.0f;
        GLfloat squaredRadius = radius * radius;
        for (size_t i = 0; i < NUM_COEFFICIENTS; i++)
        {
            rFactor *= squaredRadius;
            result += coefficients[i] * rFactor;
        }
        return result;
    }

    GLfloat Distortion::distort(GLfloat radius)
    {
        return radius * this->getDistortionFactor(radius);
    }

    GLfloat Distortion::distortInverse(GLfloat radius)
    {
        GLfloat r0 = radius / 0.9f;
        GLfloat r = radius * 0.9f;
        GLfloat dr0 = radius - this->distort(r0);
        while (fabsf(r - r0) > 0.0001f)
        {
            GLfloat dr = radius - this->distort(r);
            GLfloat r2 = r - dr * ((r - r0) / (dr - dr0));
            r0 = r;
            r = r2;
            dr0 = dr;
        }
        return r;
    }
    
    Distortion* Distortion::getApproximateInverseDistortion(GLfloat maxRadius)
    {
        size_t numSamples = 10;
        size_t numCoefficients = 2;
        
        double** matA;
        double* vecY;
        double* vecK;
        
        matA = new double*[numSamples];
        for (int i = 0; i < numSamples; i++)
        {
            matA[i] = new double[numCoefficients];
        }
        
        vecY = new double[numSamples];
        vecK = new double[numCoefficients];
        
        for (int i = 0; i < numSamples; i++)
        {
            float r = maxRadius * (i + 1) / 10.0F;
            double rp = distort(r);
            double v = rp;
            for (int j = 0; j < numCoefficients; j++)
            {
                v *= rp * rp;
                matA[i][j] = v;
            }
            vecY[i] = (r - rp);
        }
        
        hfgl::simpleLeastSquaresSolver(vecK, matA, vecY, numCoefficients, numSamples);
        
        GLfloat coefficients[numCoefficients];
        for (int i = 0; i < numCoefficients; i++)
        {
            coefficients[i] = ((GLfloat)vecK[i]);
        }
        
        Distortion *inverse = new Distortion();
        inverse->setCoefficients(coefficients);
        
        for (int i = 0; i < numSamples; i++)
        {
            delete matA[i];
        }
        
        delete matA;
        delete vecY;
        delete vecK;
        
        return inverse;
    }

}