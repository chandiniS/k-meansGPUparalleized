/********************************************************************************************
*
* 					getpoints.c
*
*********************************************************************************************/

#include <stdio.h>

#include "support.h"

int countPoints(char *datafile)
{
 FILE *fp = fopen(datafile,"r");
 int numP;
 if(!feof(fp))
 {
 printf("Reached here\n");
  fscanf(fp, "%d", &numP);
 }
 else
 {
  printf("Input File is empty\n");
  exit(0);
 }
 fclose(fp);
 return numP;
}

void storePoints(float *xarray, float *yarray, char *datafile, int sizearr)
{
 FILE *fp = fopen(datafile,"r");
 int i, ret;
 if(feof(fp))
 {
   printf("File contents sort before expected\n");
 }
 ret = fscanf(fp, "%d\n", &i);
 if(ret != 1)
 {
   printf("Input file is empty\n");
   exit(0);
 }
 for(int j = 1; j <= sizearr; ++j)
 {
   if(feof(fp))
   {
     printf("File contents sort before expected\n");
   }
   ret = fscanf(fp, "%d %f %f\n", &i, (xarray+(j-1)), (yarray+(j-1)));
   if(ret != 3)
   {
     printf("File does not contains relevant data , j = %d\n", j);
     exit(0);
   }
 }
 fclose(fp);
 /*for(int i = 0; i < 21; ++i)
 {
   printf("xarray[%d] = %f, yarray[%d] = %f\n", i, xarray[i], i, yarray[i]);
 }*/
 return;
}

void clusterCenters(float *outx, float *outy, int numClusters)
{
 FILE *fp = fopen("outCenter.txt", "w");
 
 fprintf(fp, "%d\n", numClusters);
 
 for(int i = 0; i < numClusters; ++i)
 {
   fprintf(fp, "%d %f %f\n", (i+1), outx[i], outy[i]);
 }
 fclose(fp);

 return;
}

 void clusterPoints(float *clusx, float *clusy, float * xarray, float * yarray, int numClusters, int numPoints)
 {
   /*int previousPos = -1;
   for(int k = 0; k < numClusters; ++k)
   {
     int next = (rand() % (numPoints - previousPos - 1 - (numClusters - k - 1))) + previousPos + 1;
     previousPos = next;
     
     clusx[k] = xarray[next];
     clusy[k] = yarray[next];
   }*/
   for(int i = 0; i < numClusters; ++i)
   {
     clusx[i] = xarray[i];
     clusy[i] = yarray[i];
   //  printf("clusx[%d] = %f, clusy[%d] = %f\n", i, clusx[i], i, clusy[i]);
   }
   return;
 }

void startTime(Timer* timer) {
    gettimeofday(&(timer->startTime), NULL);
}

void stopTime(Timer* timer) {
    gettimeofday(&(timer->endTime), NULL);
}

float elapsedTime(Timer timer) {
    return ((float) ((timer.endTime.tv_sec - timer.startTime.tv_sec) \
                + (timer.endTime.tv_usec - timer.startTime.tv_usec)/1.0e6));
}
