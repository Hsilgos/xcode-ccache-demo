cmake_minimum_required(VERSION 3.20)

set (CMAKE_Swift_LANGUAGE_VERSION 5.1)
set (CMAKE_CXX_STANDARD 17)

project (CcacheDemo C CXX Swift)

#############################
# Setup XCode to use ccache #
#############################
find_program(CCACHE_PATH ccache)

if (CCACHE_PATH)
    message(STATUS "ccache is enabled")
    set(C_LAUNCHER   "${CCACHE_PATH}")
    set(CXX_LAUNCHER "${CCACHE_PATH}")
    configure_file(launch-c.in clang)
    configure_file(launch-cxx.in clang++)
    execute_process(
        COMMAND chmod a+rx
                "${CMAKE_BINARY_DIR}/clang"
                "${CMAKE_BINARY_DIR}/clang++")

    set(CMAKE_XCODE_ATTRIBUTE_CC         "${CMAKE_BINARY_DIR}/clang")
    set(CMAKE_XCODE_ATTRIBUTE_CXX        "${CMAKE_BINARY_DIR}/clang++")
    set(CMAKE_XCODE_ATTRIBUTE_LD         "${CMAKE_BINARY_DIR}/clang")
    set(CMAKE_XCODE_ATTRIBUTE_LDPLUSPLUS "${CMAKE_BINARY_DIR}/clang++")
else()
    message(STATUS "ccache is disabled")
endif()

#######################
# Copy ASAN libraries #
#######################
set (XCODE_DEVELOPER_TOOLCHAINS_ROOT
     "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain")

# Here is detection for iOS/MacOS, but other platforms also can be added here like tvos, watchos, xros
if (IOS)
    set (PLATFORM_SUFFIX "ios")
else ()
    set (PLATFORM_SUFFIX "osx")
endif ()

file (GLOB_RECURSE _asan_libs "${XCODE_DEVELOPER_TOOLCHAINS_ROOT}/*/libclang_rt.*an_${PLATFORM_SUFFIX}*_dynamic.dylib")

if ("${_asan_libs}" STREQUAL "_asan_libs-NOTFOUND")
    message(FATAL_ERROR "No ASAN libs are found in ${XCODE_DEVELOPER_TOOLCHAINS_ROOT}")
endif ()

foreach (_asan_lib ${_asan_libs})
    file (RELATIVE_PATH _asan_relative_to_toolchain "${XCODE_DEVELOPER_TOOLCHAINS_ROOT}/usr/" "${_asan_lib}")
    if (NOT _asan_relative_to_toolchain)
        message (
            FATAL_ERROR
                "Failed to find relative path from ${XCODE_DEVELOPER_TOOLCHAINS_ROOT} to ${_asan_lib}"
            )
    endif ()
    message (
        STATUS "Copying: ${_asan_lib} -> ${CMAKE_BINARY_DIR}/../${_asan_relative_to_toolchain}")
    configure_file ("${_asan_lib}" "${CMAKE_BINARY_DIR}/../${_asan_relative_to_toolchain}" COPYONLY)
endforeach ()

###################################################################
# Create a simple framework with C++ accessing deallocated memory #
###################################################################

add_library(my_framework SHARED foo.cpp foo_swift.swift foo_objc.m)

# Note: Bridging header is necessary to call Objective C from Swift.
set_target_properties(my_framework PROPERTIES
    FRAMEWORK TRUE
    XCODE_ATTRIBUTE_DEFINES_MODULE YES
    XCODE_GENERATE_SCHEME YES
    XCODE_ATTRIBUTE_SWIFT_OBJC_BRIDGING_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/ObjC-Swift-Bridging.h"
    XCODE_ATTRIBUTE_SWIFT_OPTIMIZATION_LEVEL "$<IF:$<CONFIG:Debug>,-Onone,-O>"
    XCODE_ATTRIBUTE_GCC_OPTIMIZATION_LEVEL
        "$<$<CONFIG:Debug>:0>$<$<CONFIG:MinSizeRel>:s>$<$<CONFIG:RelWithDebInfo>:2>$<$<CONFIG:Release>:3>"
    XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS YES)

##########################################
# Create an app which uses the framework #
##########################################

if (IOS)
    # cmake .. -GXcode -DCMAKE_OSX_SYSROOT=iphonesimulator -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES="arm64"
    set (PRODUCT_NAME "TestApp")
    set (MACOSX_BUNDLE_EXECUTABLE_NAME my_app)
    set (MACOSX_BUNDLE_INFO_STRING "com.test")
    set (MACOSX_BUNDLE_GUI_IDENTIFIER "com.test")
    set (MACOSX_BUNDLE_BUNDLE_NAME "com.test")
    set (MACOSX_BUNDLE_ICON_FILE icon.icns)
    set (MACOSX_BUNDLE_LONG_VERSION_STRING 1.0.0)
    set (MACOSX_BUNDLE_SHORT_VERSION_STRING 1.0.0)
    set (MACOSX_BUNDLE_BUNDLE_VERSION 1.0.0)

    set (APP_SOURCES TestAppUIApp.swift ContentView.swift)
else ()
    # cmake .. -GXcode
    set (APP_SOURCES main.swift)
endif ()

add_executable (my_app MACOSX_BUNDLE ${APP_SOURCES})

target_link_libraries(my_app PRIVATE "-framework my_framework")

set_target_properties (
    my_app
    PROPERTIES
            XCODE_ATTRIBUTE_SWIFT_OPTIMIZATION_LEVEL "$<IF:$<CONFIG:Debug>,-Onone,-O>"
            XCODE_GENERATE_SCHEME YES)