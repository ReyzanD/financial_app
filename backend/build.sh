#!/bin/bash
# Build script for cloud deployment (optional - not used for local SQLite setup)
# This file is kept for reference if you want to deploy to cloud hosting later
# Ensures setuptools and wheel are installed before other packages

set -e

echo "Installing build dependencies..."
pip install --upgrade pip setuptools wheel

echo "Installing project dependencies..."
pip install -r requirements.txt

echo "Build completed successfully!"

