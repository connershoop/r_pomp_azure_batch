#!/usr/bin/env bash

set -x

# Set your Azure Container Registry (ACR) name and image details
ACR_NAME=<azureContainerRegistryName>
IMAGE_NAME="r-pomp"
VERSION="4.4.1"

# Log in to Azure Container Registry
az acr login --name $ACR_NAME

# Build the Docker image
IMAGE=$ACR_NAME.azurecr.io/$IMAGE_NAME:$VERSION
docker build -t $IMAGE --build-arg "VERSION=$VERSION" .

# Push the Docker image to ACR
docker push $IMAGE
