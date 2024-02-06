from functions import *


if __name__ == '__main__':

    # variables
    weaviate_url = 'http://weaviate:11550' # change to local ip
    CPUs = 32
    efConstruction_array = [64, 128]
    maxConnections_array = [16, 32]
    ef_array = [64, 128, 256, 512]

    benchmark_file_array = [
       #  ['deep-image-96-angular.hdf5', 'cosine'],
       #  ['mnist-784-euclidean.hdf5', 'l2-squared'],
       #  ['gist-960-euclidean.hdf5', 'l2-squared'],
        ['glove-25-angular.hdf5', 'cosine']
    ]   
 
    # Starts the actual benchmark, prints "completed" when done
    run_the_benchmarks(weaviate_url, CPUs, efConstruction_array, maxConnections_array, ef_array, benchmark_file_array)
