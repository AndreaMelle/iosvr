#include "hfglMathUtils.h"

#include <algorithm>
#include <iostream>

namespace hfgl
{
    float clampf(float lhs, float lowerbound, float upperbound)
    {
        
        return std::max(std::min(lhs,upperbound),lowerbound);
    }
    
    double* simpleLeastSquaresSolver(double* vecX, double** matA, double* vecY, size_t dim, size_t numSamples)
    {
        if(dim != 2)
        {
            std::cerr << "simpleLeastSquaresSolverf: only dim 2 currently supported" << std::endl;
            return 0;
        }
        
        double** matATA;
        double** matInvATA;
        double* vecATY;
        
        matATA = new double*[dim];
        matInvATA = new double*[dim];
        vecATY = new double[dim];
        
        for (int k = 0; k < dim; ++k)
        {
            matATA[k] = new double[dim];
            matInvATA[k] = new double[dim];
        }
        
        for (int k = 0; k < dim; ++k)
        {
            for (int j = 0; j < dim; ++j)
            {
                double sum = 0.0f;
                for (int i = 0; i < numSamples; ++i)
                {
                    sum += matA[i][j] * matA[i][k];
                }
                matATA[j][k] = sum;
            }
        }
        
        double det = matATA[0][0] * matATA[1][1] - matATA[0][1] * matATA[1][0];
        matInvATA[0][0] = (matATA[1][1] / det);
        matInvATA[1][1] = (matATA[0][0] / det);
        matInvATA[0][1] = (-matATA[1][0] / det);
        matInvATA[1][0] = (-matATA[0][1] / det);
        
        
        for (int j = 0; j < dim; ++j)
        {
            double sum = 0.0f;
            for (int i = 0; i < numSamples; ++i)
            {
                sum += matA[i][j] * vecY[i];
            }
            vecATY[j] = sum;
        }
        
        for (int j = 0; j < dim; ++j)
        {
            double sum = 0.0f;
            for (int i = 0; i < dim; ++i)
            {
                sum += matInvATA[i][j] * vecATY[i];
            }
            vecX[j] = sum;
        }
        
        for (int k = 0; k < dim; ++k)
        {
            delete matATA[k];
            delete matInvATA[k];
        }
        
        delete matATA;
        delete matInvATA;
        delete vecATY;
        
        return vecX;
    }
    
};