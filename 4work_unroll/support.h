/***************************************************************************************
*
*				support.h
*
***************************************************************************************/

#ifndef __FILEH__
#define __FILEH__

#include <sys/time.h>

typedef struct {
	struct timeval startTime;
	struct timeval endTime;
} Timer;



#ifdef __cplusplus
extern "C" {
#endif
#define MAX_NUMCLUSTERS 11 
__constant__ float cx_cm[MAX_NUMCLUSTERS];
__constant__ float cy_cm[MAX_NUMCLUSTERS];
void observationGen(int numPoints);
int countPoints(char* datafile);
void storePoints(float *xarray, float *yarray, char* datafile, int sizearr);
void clusterPoints(float *clusx, float *clusy, float * xarray, float * yarray, int numClusters, int numPoints);
void clusterCenters(float *outx, float *outy, int numClusters);
void findclusterInvoc(float* xarray, float* yarray, float* cx_h, float* cy_h, float* out_cx, float* out_cy, int numPoints, int numClusters);
void startTime(Timer* timer);
void stopTime(Timer* timer);
float elapsedTime(Timer timer);
#ifdef __cplusplus
}
#endif

#if __BYTE_ORDER != __LITTLE_ENDIAN
# error "File I/O is not implemented for this system: wrong endianness."
#endif

#endif
