#!/bin/sh

mkdir tmp && cd tmp
wget https://github.com/dengzii/rwkv_libs/releases/download/latest/librwkv_mobile-dev-latest-macos.zip
wget https://github.com/dengzii/rwkv_libs/releases/download/latest/librwkv_mobile-dev-latest-windows-x64.zip
wget https://github.com/dengzii/rwkv_libs/releases/download/latest/librwkv_mobile-dev-latest-linux-x86_64.zip

mkdir windows && cd windows && unzip ../librwkv_mobile-dev-latest-windows-x64.zip && cd ..
mkdir macos && cd macos && unzip ../librwkv_mobile-dev-latest-macos.zip && cd ..
mkdir linux && cd linux && unzip  ../librwkv_mobile-dev-latest-linux-x86_64.zip && cd ..
cd ..

cp -r tmp/macos/* macos/
cp -r tmp/linux/* linux/
cp -r tmp/windows/Release/* windows/
rm -rf tmp