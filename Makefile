
NVCC        = nvcc -arch=sm_20
NVCC_FLAGS  = -O3 -I/usr/local/cuda/include
LD_FLAGS    = -lcudart -L/usr/local/cuda/lib64
EXE	    = kmeans-clustering
OBJ	    = main.o kernelinvoc.o getpoints.o

default: $(EXE)

main.o: main.cu support.h
	$(NVCC) -c -o $@ main.cu $(NVCC_FLAGS)

kernelinvoc.o: kernelinvoc.cu support.h
		$(NVCC) -c -o $@ kernelinvoc.cu $(NVCC_FLAGS)

getpoints.o: getpoints.cu support.h
	   $(NVCC) -c -o $@ getpoints.cu $(NVCC_FLAGS)

$(EXE): $(OBJ)
	$(NVCC) $(OBJ) -o $(EXE) $(LD_FLAGS)

clean:
	rm -rf *.o $(EXE)
