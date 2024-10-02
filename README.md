This project demonstrates how to setup Xcode to use ccache and how to use sanitizers at the same time.

I tried the following environment:
* CMake version: 3.29.3
* Xcode version: 15.3

Actually with Xcode the newer CMake the better.

Project consist of two parts:

## Framework

Simple framework which calls C++ code through ObjectiveC (for simplicity).
C++ code accesses unallocated memory.
This framework is cross-platform and can be built for iOS, MacOS and other Apple OSes.

## Simple application

Minimal application which imports the framework and call the function which leads to access unallocated memory.

## Configure, build and run.

- Open your terminal and go to project dir

- For iOS
```bash
mkdir build_ios
cd build_ios
# If you have M1
cmake .. -GXcode -DCMAKE_OSX_SYSROOT=iphonesimulator -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES="arm64"
# If you have intel then CMAKE_OSX_ARCHITECTURES is different
# cmake .. -GXcode -DCMAKE_OSX_SYSROOT=iphonesimulator -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES="x86_64" 
```

- For MacOS
```bash
mkdir build_macos
cd build_macos
cmake .. -GXcode
```

- Open generated project in Xcode
- Choose `my_app` as target. 
- Go to Product -> Scheme -> Edit Scheme... -> Diagnostics
- Check "Address Sanitizer"
- Run application in Xcode and it should stop in `foo.cpp` with error "Use of deallocated memory"