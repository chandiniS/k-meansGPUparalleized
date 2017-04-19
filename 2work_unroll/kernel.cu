/*******************************************************************************************
*
*      				          kernel.cu
*
*******************************************************************************************/

#include <math.h>

#include "support.h"

#define BLOCK_SIZE 256

__global__ void findCluster(float* xarray, float* yarray, float* tempx, float* tempy, int* countP, int numPoints, int numClusters, int clusid)
{
 
 __shared__ float sx[2*BLOCK_SIZE];
 __shared__ float sy[2*BLOCK_SIZE];
 __shared__ int cp[2*BLOCK_SIZE];
 
 //int i = blockIdx.x * blockDim.x + threadIdx.x;
 int startSection = 2*blockIdx.x*blockDim.x;
 int index1 = startSection + threadIdx.x;
 int index2 = startSection + blockDim.x + threadIdx.x;

 sx[threadIdx.x] = (index1 < numPoints) ? xarray[index1] : 0.0;
 sx[blockDim.x + threadIdx.x] = (index2 < numPoints) ? xarray[index2] : 0.0;
 sy[threadIdx.x] = (index1 < numPoints) ? yarray[index1] : 0.0;
 sy[blockDim.x + threadIdx.x] = (index2 < numPoints) ? yarray[index2] : 0.0;
 cp[threadIdx.x] = (index1 < numPoints) ? 1 : 0;
 cp[blockDim.x + threadIdx.x] = (index2 < numPoints) ? 1 : 0;

 __syncthreads();
  
  // Finding points that belongs to this cluster


 int id = 0;
 float distMin = (sx[threadIdx.x] - cx_cm[id])*(sx[threadIdx.x] - cx_cm[id]) + (sy[threadIdx.x] - cy_cm[id])*(sy[threadIdx.x] - cy_cm[id]);

 float distTemp;
 for(int k = 1; k < numClusters; ++k) 
 {
   distTemp = (sx[threadIdx.x] - cx_cm[k])*(sx[threadIdx.x] - cx_cm[k]) + (sy[threadIdx.x] - cy_cm[k])*(sy[threadIdx.x] - cy_cm[k]);
   if(distTemp < distMin)
   {
     distMin = distTemp;
     id = k;
   }
 }

 if (id != clusid)
 {
   sx[threadIdx.x] = 0.0;
   sy[threadIdx.x] = 0.0;
   cp[threadIdx.x] = 0;
 }

 id = 0;
 distMin = (sx[blockDim.x + threadIdx.x] - cx_cm[id])*(sx[blockDim.x + threadIdx.x] - cx_cm[id]) + (sy[blockDim.x + threadIdx.x] - cy_cm[id])*(sy[blockDim.x + threadIdx.x] - cy_cm[id]);
  
 for(int k = 1; k < numClusters; ++k)
 {
  distTemp = (sx[blockDim.x + threadIdx.x] - cx_cm[k])*(sx[blockDim.x + threadIdx.x] - cx_cm[k]) + (sy[blockDim.x + threadIdx.x] - cy_cm[k])*(sy[blockDim.x + threadIdx.x] - cy_cm[k]);
   if(distTemp < distMin)
   {
     distMin = distTemp;
     id = k;
   }
 }
 
 if (id != clusid)
 {
   sx[blockDim.x + threadIdx.x] = 0.0;
   sy[blockDim.x + threadIdx.x] = 0.0;
   cp[blockDim.x + threadIdx.x] = 0;
 }
 //    printf("cp[%d] = %d\n", threadIdx.x, cp[threadIdx.x]);
 // Summing the value of points and number of points with the help of reduction
 
 for(int stride = blockDim.x; stride > 32; stride >>= 1) 
 {
   __syncthreads();
    
   if(threadIdx.x < stride)
   {
     sx[threadIdx.x] += sx[stride + threadIdx.x];
     sy[threadIdx.x] += sy[stride + threadIdx.x];
     cp[threadIdx.x] += cp[stride + threadIdx.x];
  //   printf("cp[%d] = %d\n", threadIdx.x, cp[threadIdx.x]);
   }

 }

//unrolling last warp here

   if(threadIdx.x < 32)
   {
    __syncthreads();
     
     sx[threadIdx.x] += sx[32 + threadIdx.x];
     sy[threadIdx.x] += sy[32 + threadIdx.x];
     cp[threadIdx.x] += cp[32 + threadIdx.x];
    __syncthreads();
     sx[threadIdx.x] += sx[16 + threadIdx.x];
     sy[threadIdx.x] += sy[16 + threadIdx.x];
     cp[threadIdx.x] += cp[16 + threadIdx.x];
    __syncthreads();
     sx[threadIdx.x] += sx[8 + threadIdx.x];
     sy[threadIdx.x] += sy[8 + threadIdx.x];
     cp[threadIdx.x] += cp[8 + threadIdx.x];
    __syncthreads();
     sx[threadIdx.x] += sx[4 + threadIdx.x];
     sy[threadIdx.x] += sy[4 + threadIdx.x];
     cp[threadIdx.x] += cp[4 + threadIdx.x];
    __syncthreads();
     sx[threadIdx.x] += sx[2 + threadIdx.x];
     sy[threadIdx.x] += sy[2 + threadIdx.x];
     cp[threadIdx.x] += cp[2 + threadIdx.x];
    __syncthreads();
     sx[threadIdx.x] += sx[1 + threadIdx.x];
     sy[threadIdx.x] += sy[1 + threadIdx.x];
     cp[threadIdx.x] += cp[1 + threadIdx.x];
   }

   __syncthreads();
 tempx[blockIdx.x] = sx[0]; 
 tempy[blockIdx.x] = sy[0]; 
 countP[blockIdx.x] = cp[0];
}


__global__ void reduceResult(float* tempx, float* tempy, int* count_d, float* reducedx, float* reducedy, int* reducCount, int num_sec)
{
 __shared__ float sumx[2*BLOCK_SIZE];
 __shared__ float sumy[2*BLOCK_SIZE];
 __shared__ int sumcount[2*BLOCK_SIZE];

    unsigned int t = threadIdx.x;
    unsigned int start = 2 * blockIdx.x * blockDim.x;

    unsigned int indexin = start + t;
    unsigned int indexpast = start + blockDim.x + t;
    sumx[t] = (indexin < num_sec) ? tempx[indexin] : 0.0;
    sumx[blockDim.x + t] = (indexpast < num_sec) ? tempx[indexpast] : 0.0;
    sumy[t] = (indexin < num_sec) ? tempy[indexin] : 0.0;
    sumy[blockDim.x + t] = (indexpast < num_sec) ? tempy[indexpast] : 0.0;
    sumcount[t] = (indexin < num_sec) ? count_d[indexin] : 0;
    sumcount[blockDim.x + t] = (indexpast < num_sec) ? count_d[indexpast] : 0;
    
    for (unsigned int stride = blockDim.x; stride > 0; stride >>= 1)
    {
        __syncthreads();
        if (t < stride)
        {
          sumx[t] += sumx[t + stride];
          sumy[t] += sumy[t + stride];
          sumcount[t] += sumcount[t + stride];
        }
    }
    reducedx[blockIdx.x] = sumx[0];
    reducedy[blockIdx.x] = sumy[0];
    reducCount[blockIdx.x] = sumcount[0];
}
