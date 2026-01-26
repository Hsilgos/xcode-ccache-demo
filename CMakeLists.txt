cmake_minimum_required(VERSION 3.20)

set (CMAKE_Swift_LANGUAGE_VERSION 5.1)
set (CMAKE_CXX_STANDARD 17)

project (CcacheDemo C CXX Swift)

#############################
# Setup XCode to use ccache #
#############################

# Used to enable sanitizers
set (XCODE_DEVELOPER_TOOLCHAINS_ROOT
    "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain" CACHE FILEPATH
    "Path to Xcode toolchains root")

# Path to folder which Xcode considers as root for compiler toolchain location
set (CCACHE_CLANG_LOCATION_ROOT "${CMAKE_BINARY_DIR}")

find_program(CCACHE_PATH ccache)

if (CCACHE_PATH)
    message(STATUS "ccache is enabled")
    set (C_LAUNCHER   "${CCACHE_PATH}")
    set (CXX_LAUNCHER "${CCACHE_PATH}")
    set (CCACHE_CLANG_WRAPPER_DIR "${CCACHE_CLANG_LOCATION_ROOT}/usr/bin")
    configure_file(launch-c.in ${CCACHE_CLANG_WRAPPER_DIR}/clang)
    configure_file(launch-cxx.in ${CCACHE_CLANG_WRAPPER_DIR}/clang++)
    execute_process(
        COMMAND chmod a+rx
                "${CCACHE_CLANG_WRAPPER_DIR}/clang"
                "${CCACHE_CLANG_WRAPPER_DIR}/clang++")

    set(CMAKE_XCODE_ATTRIBUTE_CC         "${CCACHE_CLANG_WRAPPER_DIR}/clang")
    set(CMAKE_XCODE_ATTRIBUTE_CXX        "${CCACHE_CLANG_WRAPPER_DIR}/clang++")
    set(CMAKE_XCODE_ATTRIBUTE_LD         "${CCACHE_CLANG_WRAPPER_DIR}/clang")
    set(CMAKE_XCODE_ATTRIBUTE_LDPLUSPLUS "${CCACHE_CLANG_WRAPPER_DIR}/clang++")

    # Sanitizers.
    # Xcode is looking for ASAN libraries in paths relative to `clang`.
    # As path to `clang` is overridden to ccache wrapper above, it's necessary
    # to create symlink which reflects original clang layout.
    file(MAKE_DIRECTORY "${CCACHE_CLANG_LOCATION_ROOT}/usr/lib")
    file(CREATE_LINK "${XCODE_DEVELOPER_TOOLCHAINS_ROOT}/usr/lib/clang" "${CCACHE_CLANG_LOCATION_ROOT}/usr/lib/clang" SYMBOLIC)
else()
    message(STATUS "ccache is disabled")
endif()

###################################################################
# Create a simple framework with C++ accessing deallocated memory #
###################################################################

add_library(my_framework SHARED foo.cpp foo_swift.swift)

# Note: Bridging header is necessary to call C from Swift.
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