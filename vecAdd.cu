#include "vecAdd.h"

#include <algorithm>
#include <stdexcept>

using namespace std;

namespace {

__global__ void _vecAdd(
    const double * a,
    const double * b,
    double * c,
    size_t maxIdx
)
{
    size_t idx = gridDim.x * blockIdx.x + threadIdx.x;
    if(idx < maxIdx) {
        c[idx] = a[idx] + b[idx];
    }
}

} // namespace


void vecAdd(
    const std::vector<double>& a,
    const std::vector<double>& b,
    std::vector<double>& result
)
{
    if(a.size() != b.size()) {
        throw std::logic_error("Vectors must have same size");
    }
    result.resize(a.size());

    // Query current device
    int device;
    cudaGetDevice(&device);

    // Query device properties
    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, device);

    // Assuming that all vectors can fit into GPU's memory!
    const size_t vectorSize = a.size() * sizeof(double);

    double* deviceA;
    cudaMalloc(&deviceA, vectorSize);
    cudaMemcpy(
	deviceA,
	a.data(),
	vectorSize,
	cudaMemcpyHostToDevice
    );

    double* deviceB;
    cudaMalloc(&deviceB, vectorSize);
    cudaMemcpy(
	deviceB,
	b.data(),
	vectorSize,
	cudaMemcpyHostToDevice
    );

    double* deviceC;
    cudaMalloc(&deviceC, vectorSize);

    // Assuming that vectors can be added via a single grid!
    size_t numThreads = min((size_t)props.maxThreadsDim[0], result.size());
    size_t numBlocks = (result.size() - 1) / numThreads + 1;

    _vecAdd<<<numBlocks, numThreads>>>(deviceA, deviceB, deviceC, result.size());
    cudaDeviceSynchronize();

    cudaMemcpy(
        result.data(),
	deviceC,
	vectorSize,
	cudaMemcpyDeviceToHost
    );

    cudaFree(deviceA);
    cudaFree(deviceB);
    cudaFree(deviceC);
}

