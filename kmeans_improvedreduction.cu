/****************************************************************************************
*Reduction kernel that performs add upon first load to shared memory and then unrolls
* the loop when data size is less than 32.
*
*(idea from Nvidia developer zone- CudaGuide- Mark Harris)
*
*
*
*
* ***************************************************************************************/
#define BLOCK_SIZE 1024

//pass as parameters- location in global memory of input data,location where output should be wriiten to
__global__ void reduction_improved(int* g_input,int* g_outputsum){


unsigned int tx= threadIdx.x;
unsigned inti tid=blockIdx.x*(blockDim.x*2)+threadIdx.x; // for block 0 tid will be- 0...1024,for block 1:2048 till 3072. each thread adds two data & loads into shared memory

__shared__ int shared_input[];

//loading data into shared memory

shared_input[tx]=g_input[tid]+g_input[tid+blockDim.x];

__syncthreads();


for(unsigned int stride=blockDim.x/2;strie>32,stride>>=1)
{

if(threadIdx.x<stride)
shared_input[tx]+=shared_input[tx+stride];
__syncthreads();

}

//unrolling last warp here

if(tx<32){
shared_input[tx]+=shared_input[tx+32];
shared_input[tx]+=shared_input[tx+16];
shared_input[tx]+=shared_input[tx+8];
shared_input[tx]+=shared_input[tx+4];
shared_input[tx]+=shared_input[tx+2];
shared_input[tx]+=shared_input[tx+1];


}

//write back result to global memory using thread 0

if(threadIdx.x==0){

g_outputsum[blockIdx.x]=shared_input[0];
}

