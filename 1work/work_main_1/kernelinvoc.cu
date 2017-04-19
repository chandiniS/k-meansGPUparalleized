/*****************************************************************************************
*
*				kernelinvoc.cu
*
******************************************************************************************/


#include <stdio.h>
#include <math.h>

#include "kernel.cu"
#include "support.h"

#define BLOCK_SIZE 256
 

void findclusterInvoc(float* xarray, float* yarray, float* cx_h, float* cy_h, float* out_cx, float* out_cy, int numPoints, int numClusters)
{
 float *hx, *hy;
 float *tempx, *tempy;
 float *reducedx, *reducedy;
 int *count_d, *reducCount, *count_h;
 //int num_sec= (numPoints%(BLOCK_SIZE<<1) == 0) ? (numPoints/(BLOCK_SIZE<<1)) : (numPoints/(BLOCK_SIZE<<1) + 1);  
 int num_sec= (numPoints%(BLOCK_SIZE) == 0) ? (numPoints/(BLOCK_SIZE)) : (numPoints/(BLOCK_SIZE) + 1);  
 //int reducedsec= (num_sec%(BLOCK_SIZE<<1) == 0) ? (num_sec/(BLOCK_SIZE<<1)) : (num_sec/(BLOCK_SIZE<<1) + 1);  
 int reducedsec= (num_sec%(BLOCK_SIZE) == 0) ? (num_sec/(BLOCK_SIZE)) : (num_sec/(BLOCK_SIZE) + 1);  
 int clusind = 0;
 float delx, dely;
 bool flag = false;

 dim3 dimGrid, dimGridNext, dimBlock;

  cudaError_t cuda_ret;

 /******* Allocating host memory**************************************/

  hx = (float*)malloc(reducedsec*sizeof(float));
  if(hx == NULL)
  {
    printf("Unable to allocate host memory\n");
    exit(0);
  }
  hy = (float*)malloc(reducedsec*sizeof(float));
  if(hy == NULL)
  {
    printf("Unable to allocate host memory\n");
    exit(0);
  }
  count_h = (int*)malloc(reducedsec*sizeof(int));
  if(hy == NULL)
  {
    printf("Unable to allocate host memory\n");
    exit(0);
  }

 /******* Allocating device memory**************************************/

  cuda_ret = cudaMemcpyToSymbol(cx_cm, cx_h, numClusters*sizeof(float));
  if(cuda_ret != cudaSuccess)
  {
    printf("Unable to copy memory to constant memory\n");
    exit(0);
  }
  cuda_ret = cudaMemcpyToSymbol(cy_cm, cy_h, numClusters*sizeof(float));
  if(cuda_ret != cudaSuccess)
  {
    printf("Unable to copy memory to constant memory\n");
    exit(0);
  }

 cuda_ret = cudaMalloc((void**)&tempx, num_sec*sizeof(float));
 if(cuda_ret != cudaSuccess)
 {
  printf("\n Unable to allocate device memory");
  exit(0);
 }
 cuda_ret = cudaMemset(tempx, 0.0, num_sec*sizeof(float));
  if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }
 cuda_ret = cudaMalloc((void**)&tempy, num_sec*sizeof(float));
  if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }
 cuda_ret = cudaMemset(tempy, 0.0, num_sec*sizeof(float));
  if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }
 cuda_ret = cudaMalloc((void**)&count_d, num_sec*sizeof(int));
  if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }
 cuda_ret = cudaMemset(count_d, 0, num_sec*sizeof(int));
  if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }


 cuda_ret = cudaMalloc((void**)&reducedx, reducedsec*sizeof(float));
 if(cuda_ret != cudaSuccess)
 {
  printf("\n Unable to allocate device memory");
  exit(0);
 }
 cuda_ret = cudaMemset(reducedx, 0.0, reducedsec*sizeof(float));
  if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }
 cuda_ret = cudaMalloc((void**)&reducedy, reducedsec*sizeof(float));
 if(cuda_ret != cudaSuccess)
 {
  printf("\n Unable to allocate device memory");
  exit(0);
 }
 cuda_ret = cudaMemset(reducedy, 0.0, reducedsec*sizeof(float));
  if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }
 cuda_ret = cudaMalloc((void**)&reducCount, reducedsec*sizeof(int));
 if(cuda_ret != cudaSuccess)
 {
  printf("\n Unable to allocate device memory");
  exit(0);
 }
 cuda_ret = cudaMemset(reducCount, 0, reducedsec*sizeof(int));
  if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }

 cudaDeviceSynchronize();

 /***************Invoking kernel*****************************************/

  dimGrid = num_sec;
  dimGridNext = reducedsec;
  dimBlock = BLOCK_SIZE;

  int loop = 0;
 
   do
   { 
    flag = false;
    ++loop;
    clusind = 0;

    while(clusind < numClusters)
   {
     findCluster<<<dimGrid, dimBlock>>>(xarray, yarray, tempx, tempy, count_d, numPoints, numClusters, clusind);

     reduceResult<<<dimGridNext, dimBlock>>>(tempx, tempy, count_d, reducedx, reducedy, reducCount, num_sec);
     
     cuda_ret = cudaMemcpy(hx, reducedx, reducedsec*sizeof(float), cudaMemcpyDeviceToHost);
     if(cuda_ret != cudaSuccess)
     {
       printf("Unable to copy device to host");
       exit(0);
     }
     cuda_ret = cudaMemcpy(hy, reducedy, reducedsec*sizeof(float), cudaMemcpyDeviceToHost);
     if(cuda_ret != cudaSuccess)
     {
       printf("Unable to copy device to host");
       exit(0);
     }
     cuda_ret = cudaMemcpy(count_h, reducCount, reducedsec*sizeof(int), cudaMemcpyDeviceToHost);
     if(cuda_ret != cudaSuccess)
     {
       printf("Unable to copy device to host");
       exit(0);
     }
     
     cudaDeviceSynchronize();
     
    // printf("loop = %d, clusind = %d, sumx = %f, sumy = %f, num = %d\n",loop, clusind, hx[0], hy[0], count_h[0]);
     hx[0] /= count_h[0];
     hy[0] /= count_h[0];
     out_cx[clusind] = hx[0];
     out_cy[clusind] = hy[0];
     clusind++;
   }

    for(int i = 0; i < numClusters; ++i)
    {
     delx = (cx_h[i] - out_cx[i])<0 ? (out_cx[i]-cx_h[i]) : (cx_h[i] - out_cx[i]);
     dely = (cy_h[i] - out_cy[i])<0 ? (out_cy[i]-cy_h[i]) : (cy_h[i] - out_cy[i]);
     if(delx > pow(10, -2) || dely > pow(10, -2))
     {
       flag = true;
     }
     //printf("delx = %f, dely = %f\n", delx, dely);
    }

    // Checking cluster centers values --------------------------------------

   //printf("Initial and current values\n");

   for(int j = 0; j < numClusters; ++j)
   {
     //printf("For cluster %d :-\n",j+1);
     //printf("x-> ini = %f, cur = %f\n", cx_h[j], out_cx[j]);
     //printf("y-> ini = %f, cur = %f\n", cy_h[j], out_cy[j]);
   }

    
    if(flag == true)
    {
      memcpy(cx_h, out_cx, numClusters*sizeof(float));
      memcpy(cy_h, out_cy, numClusters*sizeof(float));

     cuda_ret = cudaMemcpyToSymbol(cx_cm, out_cx, numClusters*sizeof(float));
     if(cuda_ret != cudaSuccess)
     {
      printf("\n Unable to copy to constant memory");
      exit(0);
     }
     cuda_ret = cudaMemcpyToSymbol(cy_cm, out_cy, numClusters*sizeof(float));
     if(cuda_ret != cudaSuccess)
     {
      printf("\n Unable to copy to constant memory");
      exit(0);
     }

     cuda_ret = cudaMemset(tempx, 0.0, num_sec*sizeof(float));
     if(cuda_ret != cudaSuccess)
     {
       printf("\n Unable to allocate device memory");
       exit(0);
     }
     cuda_ret = cudaMemset(tempy, 0.0, num_sec*sizeof(float));
     if(cuda_ret != cudaSuccess)
     {
       printf("\n Unable to allocate device memory");
       exit(0);
     }
     cuda_ret = cudaMemset(count_d, 0, num_sec*sizeof(int));
     if(cuda_ret != cudaSuccess)
     {
       printf("\n Unable to allocate device memory");
       exit(0);
     }
     cuda_ret = cudaMemset(reducedx, 0.0, reducedsec*sizeof(float));
     if(cuda_ret != cudaSuccess)
     {
       printf("\n Unable to allocate device memory");
       exit(0);
     }
     cuda_ret = cudaMemset(reducedy, 0.0, reducedsec*sizeof(float));
     if(cuda_ret != cudaSuccess)
     {
       printf("\n Unable to allocate device memory");
       exit(0);
     }
     cuda_ret = cudaMemset(reducCount, 0, reducedsec*sizeof(int));
     if(cuda_ret != cudaSuccess)
     {
       printf("\n Unable to allocate device memory");
       exit(0);
     }


     cudaDeviceSynchronize();
    }

    if(loop == 2)
    {
    // break;
    }
    
  }while(flag == true);
 
   // Free Memory -------------------------------------------------------------

   cudaFree(tempx);
   cudaFree(tempy);
   cudaFree(count_d);
   cudaFree(reducedx);
   cudaFree(reducedy);
   cudaFree(reducCount);
   free(hx);
   free(hy);
   free(count_h);
 
 return;
}
