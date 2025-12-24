#!/bin/bash
# Build script for Render deployment
# Ensures setuptools and wheel are installed before other packages

set -e

echo "Installing build dependencies..."
pip install --upgrade pip setuptools wheel

echo "Installing project dependencies..."
pip install -r requirements.txt

echo "Build completed successfully!"

