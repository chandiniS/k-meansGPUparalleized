/*****************************************************************************************************
*
*					main.cu
*
*****************************************************************************************************/

#include <stdio.h>

#include "support.h"

int main(int argc, char* argv[])
{
 Timer timer;

 //	Initialize variables -----------------------------------------------------

 float *xarr_h, *yarr_h;
 float *xarr_d, *yarr_d;
 float *cx_h, *cy_h;
 float *out_cx, *out_cy;
 int numPoints, numClusters;
 char *datafile;
 cudaError_t cuda_ret;

 //  Allocate values to variables through arguments
 
 printf("\n Setting up the problem ........");
 fflush(stdout);
 startTime(&timer);

 if(argc == 1)
 {
   datafile = "color_histogram68040.txt";
   numClusters = 11;
 }
 else if(argc == 2)
 {
  /*if(sscanf(argv[1], "%s", &datafile) != 1)
  { 
    printf("\nArgument is not an integer");
    exit(0);
  }*/
  datafile = argv[1];
   numClusters = 11;
 }
 else if(argc == 3)
 {
  /*if(sscanf(argv[1], "%s", &datafile) != 1)
  {
   printf("\n Argument for file of points is not a string");
   exit(0);
  }*/
  datafile = argv[1];
  if(sscanf(argv[2], "%d", &numClusters) != 1)
  {
   printf("\n Argument for number of clusters is not an integer");
   exit(0);
  }
 }
 else 
 {
   printf("\n Invalid input parameters");
   exit(0);
 }
 stopTime(&timer);
 printf("%f s\n", elapsedTime(timer));
  

 // Number of points from the input file  ---------------------------------------

 numPoints = countPoints(datafile); 
 printf("\nInput size for points = %d, Size for clusters = %d\n", numPoints, numClusters);

 // Allocating and initializing host variables -------------------------------

  printf("Allocating host variables ................");
  fflush(stdout);
  startTime(&timer);  

  xarr_h = (float*)malloc(numPoints * sizeof(float));
  if(xarr_h == NULL)
  {
   printf("\n Unable to allcate host variable");
   exit(0);
  } 
  yarr_h = (float*)malloc(numPoints * sizeof(float));
  if(yarr_h == NULL)
  {
    printf("\n Unable to allocate host variable");
    exit(0);
  }
  cx_h = (float*)malloc(numClusters * sizeof(float));
  if(cx_h == NULL)
  {
    printf("\n Unable to allocate host variables");
    exit(0);
  }
  cy_h = (float*)malloc(numClusters * sizeof(float));
  if(cy_h == NULL)
  {
    printf("\n Unable to allocate host variables");
    exit(0);
  }
  out_cx = (float*)malloc(numClusters * sizeof(float));
  if(out_cx == NULL)
  {
    printf("\n Unable to allocate host variables");
    exit(0);
  }
  out_cy = (float*)malloc(numClusters * sizeof(float));
  if(out_cy == NULL)
  {
    printf("\n Unable to allocate host variables");
    exit(0);
  }

  stopTime(&timer);
  printf("%f s\n", elapsedTime(timer));

 // Allocating device variables ----------------------------------------------

 printf("\n Allocating device variables........");
 fflush(stdout);
 startTime(&timer);

 cuda_ret = cudaMalloc((void**)&xarr_d, numPoints*sizeof(float));
 if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }
 cuda_ret = cudaMalloc((void**)&yarr_d, numPoints*sizeof(float));
 if(cuda_ret != cudaSuccess)
 {
   printf("\n Unable to allocate device memory");
   exit(0);
 }
 
 cudaDeviceSynchronize();
 stopTime(&timer);
 printf("%f s\n", elapsedTime(timer));
 
 
 // Random generation of points in 2-D plane  ---------------------------------------
 
  //observationGen(numPoints);

 // Store Points in host variables   -----------------------------------------------

  storePoints(xarr_h, yarr_h, datafile, numPoints);

 // Randomly select distinct numClusters points from availabe points -----------------

  clusterPoints(cx_h, cy_h, xarr_h, yarr_h, numClusters, numPoints);
   // Initial cluster centers values --------------------------------------

  /* printf("Initial values for cluster centres\n");

   for(int j = 0; j < numClusters; ++j)
   {
     printf("For cluster %d :-\n",j+1);
     printf("x-> ini = %f\n", cx_h[j]);
     printf("y-> ini = %f\n", cy_h[j]);
   }
*/
  // Copy host variables to device  memory ---------------------------------------------------

  printf("\nCopying data from host to device\n");
  fflush(stdout);
  startTime(&timer);

  cuda_ret = cudaMemcpy(xarr_d, xarr_h, numPoints*sizeof(float), cudaMemcpyHostToDevice);
  if(cuda_ret != cudaSuccess)
  {
    printf("Unable to copy memory to device\n");
    exit(0);
  }
  cuda_ret = cudaMemcpy(yarr_d, yarr_h, numPoints*sizeof(float), cudaMemcpyHostToDevice);
  if(cuda_ret != cudaSuccess)
  {
    printf("Unable to copy memory to device\n");
    exit(0);
  }
  
  cudaDeviceSynchronize();
  stopTime(&timer);
  printf("%f s\n", elapsedTime(timer)); 

  // Kernel invocation

   /*printf("Launching kernel ...........\n");
   fflush(stdout);
   startTime(&timer);*/

   /* Kernel will get setup and invoked inside findclusterInvok function in kernelinvoc.cu file*/

   findclusterInvoc(xarr_d, yarr_d, cx_h, cy_h, out_cx, out_cy, numPoints, numClusters);

   cuda_ret = cudaDeviceSynchronize();
   if(cuda_ret != cudaSuccess)
   {
     printf("Unable to launch/execute kernel\n");
     exit(0);
   }

   // Checking cluster centers values --------------------------------------

/*   printf("Initial and final values\n");

   for(int j = 0; j < numClusters; ++j)
   {
     printf("For cluster %d :-\n",j+1);
     printf("x-> ini = %f, fin = %f\n", cx_h[j], out_cx[j]);
     printf("y-> ini = %f, fin = %f\n", cy_h[j], out_cy[j]);
   }
*/
//   stopTime(&timer);
  // printf("Elapsed time for kernel execution = %f s\n", elapsedTime(timer));

  //Getting cluster centers in file outCenter.txt

   clusterCenters(out_cx, out_cy, numClusters);


  // Free Memory ----------------------------------------------------

  cudaFree(xarr_d);
  cudaFree(yarr_d);
  cudaFree(out_cx);
  cudaFree(out_cy);
  free(xarr_h);
  free(yarr_h);
  free(cx_h);
  free(cy_h);
 
 return 0;
}
