//
//  MagnetSensor.h
//  iosvr
//
//

#ifndef __CardboardSDK_iOS__MagnetSensor__
#define __CardboardSDK_iOS__MagnetSensor__

#include <GLKit/GLKVector3.h>
#include <vector>

namespace iosvr
{
    class MagnetSensor
    {
    public:
        class MagnetSensorObserver
        {
        public:
            virtual void OnMagnetTrigger(MagnetSensor* sender) = 0;
        };
        
      public:
        MagnetSensor();
        virtual ~MagnetSensor();
        void start();
        void stop();
        
        void addObserver(MagnetSensorObserver* observer);
        void removeObserver(MagnetSensorObserver* observer);
        void removeAllObservers();
        
      private:
        void* _manager;
        size_t _sampleIndex;
        GLKVector3 _baseline;
        std::vector<GLKVector3> _sensorData;
        std::vector<float> _offsets;
        
        void addData(GLKVector3 value);
        void evaluateModel();
        void computeOffsets(int start, GLKVector3 baseline);
        
        static const size_t numberOfSamples = 20;
        
        std::vector<MagnetSensorObserver*> observers;
        void notifyObservers();
        
    };

}

#endif