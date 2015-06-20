//
//  Distortion.h
//  iosvr
//

#ifndef __CardboardSDK_iOS__Distortion__
#define __CardboardSDK_iOS__Distortion__

#include <iostream>
#include <hfgl/hfglVersion.h>

#define NUM_COEFFICIENTS 2

namespace iosvr
{
    class Distortion
    {
      public:
        
        Distortion();
        Distortion(const Distortion &other);
        
        Distortion& operator=(const Distortion &other);
        
        bool operator==(const Distortion &other) const;
        bool operator!=(const Distortion &other) const;
        
        virtual ~Distortion();
        
        void setCoefficients(GLfloat *coefficients);
        GLfloat *getCoefficients();
        
        GLfloat getDistortionFactor(GLfloat radius);
        GLfloat distort(GLfloat radius);
        GLfloat distortInverse(GLfloat radius);
        
        Distortion* getApproximateInverseDistortion(GLfloat maxRadius);
        
      private:
        
        static GLfloat DefaultCoefficients[NUM_COEFFICIENTS];
        GLfloat coefficients[NUM_COEFFICIENTS];
    };

};

#endif
