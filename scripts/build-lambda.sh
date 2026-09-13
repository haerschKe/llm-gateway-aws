#!/usr/bin/env bash
set -e
cd lambda
rm -rf build && mkdir build
cp gateway.py build/

# export locked dependencies from uv.lock exportieren and install into build-directory
uv export --no-dev --no-hashes -o build/requirements.txt
uv pip install --python 3.14 --target build -r build/requirements.txt

cd build
zip -r ../gateway.zip .
cd ../..