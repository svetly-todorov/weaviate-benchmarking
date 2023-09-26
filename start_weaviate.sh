#!/bin/bash

start_weaviate() {
  # Start waeviate on 11550
  sudo docker compose up weaviate -d

  # Get the container id of the weaviate service
  container_id=""
  retry_count=0
  max_retries=60  # Maximum retries to avoid infinite loop

  echo "[Info] Waiting for the weaviate service to start..."

  while [[ -z "$container_id" && $retry_count -lt $max_retries ]]; do
    container_id=$(docker ps -qf "name=weaviate")

    if [[ -z "$container_id" ]]; then
      # If container_id is still empty, sleep for a bit before trying again
      sleep 1
      ((retry_count++))
    fi
  done

  if [[ -z "$container_id" ]]; then
    echo "[Error] weaviate service didn't start within the expected time."
    exit 1
  fi

  # Waiting the weaviate server to fully start
  sleep 10

  echo "[Info] weaviate service is up with container id: $container_id"
  # Update the container's cpuset
  sudo docker update --cpuset-cpus='32-63' "$container_id"
}

download_data() {
  # Define the directory to store the downloaded files
  DIR="benchmark-data"

  # Create the directory if it doesn't exist
  [ ! -d "$DIR" ] && mkdir "$DIR"

  # List of files to download
  FILES=(
    "deep-image-96-angular.hdf5"
    "mnist-784-euclidean.hdf5"
    "gist-960-euclidean.hdf5"
    "glove-25-angular.hdf5"
  )

  # Base URL to download the files
  BASE_URL="http://ann-benchmarks.com"

  # Loop through each file and download it if it doesn't exist
  for file in "${FILES[@]}"; do
    # Construct the file path
    file_path="$DIR/$file"
  
    # Check if the file already exists
    if [ ! -f "$file_path" ]; then
      echo "[Info] Downloading $file..."
      curl -o "$file_path" "$BASE_URL/$file"
    else
      echo "[Info] $file already exists. Skipping download."
    fi
  done

  echo "[Info] Done data download."
}

start_ann() {
  # Build ann image
  sudo docker compose build
  IMAGE_NAME="benchmark-ann"
  # Start the container
  sudo docker compose up benchmark-ann -d
  # Get the container id of the benchmark-ann
  container_id=""
  retry_count=0
  max_retries=60  # Maximum retries to avoid infinite loop

  echo "[Info] Waiting for the benchmark-ann to start..."

  while [[ -z "$container_id" && $retry_count -lt $max_retries ]]; do
    container_id=$(docker ps -qf "name=benchmark-ann")

    if [[ -z "$container_id" ]]; then
      # If container_id is still empty, sleep for a bit before trying again
      sleep 1
      ((retry_count++))
    fi
  done

  if [[ -z "$container_id" ]]; then
    echo "[Error] benchmark-ann didn't start within the expected time."
    exit 1
  fi

  echo "[Info] benchmark-ann is up with container id: $container_id"
  # Update the container's cpuset
  sudo docker update --cpuset-cpus='0-31' "$container_id"
}

stop_weaviate() {
  sudo docker compose down
}

# Start benchmarks
start_weaviate
download_data
start_ann
# Check if a container with the specified image name is running
while :; do
  container_id=$(sudo docker ps -qf "name=$IMAGE_NAME")
  # If a container with the specified image name is found
  if [[ -n "$container_id" ]]; then
    # Check the status of the container
    container_status=$(docker inspect --format '{{.State.Status}}' "$container_id")

    # If the container has exited, call the stop_weaviate function and exit the loop
    if [[ "$container_status" == "exited" ]]; then
      echo "[Info] $IMAGE_NAME Done"
      stop_weaviate
      break
    fi
  else
    echo "[Error] Container with image $IMAGE_NAME not found. Exiting..."
    stop_weaviate
    break
  fi

  # Sleep for a while before checking again
  sleep 5
done
