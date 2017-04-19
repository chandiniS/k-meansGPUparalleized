/****************************************************************************
*
*			datagen.c
*
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "support.h"

void observationGen(int numPoints) 
{
/*int main(int argc, char *argv[])
{
  int numPoints;
  if (sscanf(argv[1], "%d", &numPoints) != 1)
  {
    printf("error - argument is not an integer");
    exit(0);
  }*/


  FILE *fp;
  fp = fopen("input.txt", "w");
  fprintf(fp, "%d\n", numPoints);
  for(int i = 1; i <= numPoints; ++i)
  {
    float xc = rand() % numPoints;
    float yc = rand() % numPoints;
    fprintf(fp, "%d %f %f\n", i, xc, yc);
  }
  fclose(fp);


  /*fp = fopen("input.txt", "r");
  int i, ret;
  float xo, yo;
  ret = fscanf(fp, "%d\n", &i);
  printf("%d %d\n", ret, i);
  while (!feof(fp))
  {
   ret = fscanf(fp, "%d %f %f\n", &i, &xo, &yo);
   printf("%d %d %f %f\n", ret, i, xo, yo);
  }
  fclose(fp);*/


  return 0;
}


