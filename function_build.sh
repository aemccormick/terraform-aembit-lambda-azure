#! /bin/bash

# 1. Create a clean build directory
echo "Creating a clean build directory..."
rm -rf build
mkdir build
mkdir -p artifacts

# 2. Install dependencies from requirements.txt into the build directory
echo "Installing Python dependencies..."
pip3 install --platform manylinux2014_x86_64 --implementation cp --python-version 3.11 --only-binary=:all: --upgrade -r src/requirements.txt -t build/

# 3. Copy the Lambda function code into the build directory
echo "Copying function code..."
cp src/lambda_function.py build/
