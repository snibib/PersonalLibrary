#!/bin/bash

#
#确保脚本在任意目录启动
PROJECT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $PROJECT_PATH

#
#build libs
#build simulator static lib
xcodebuild IPHONEOS_DEPLOYMENT_TARGET='7.0' -target PersonalLibrary -sdk iphonesimulator -configuration Debug
#
##build iphoneos static lib
xcodebuild IPHONEOS_DEPLOYMENT_TARGET='7.0' -target PersonalLibrary -sdk iphoneos -configuration Debug
#
##merge libs
lipo -create build/Debug-iphoneos/libPersonalLibrary.a build/Debug-iphonesimulator/libPersonalLibrary.a -output build/libPersonalLibrary.a
#
##export files
cd $PROJECT_PATH
rm -rf Export
mkdir -p Export/include
mkdir -p Export/lib
cp build/*.a Export/lib/
cp -r PersonalLibrary/Sources/Classes/*.h Export/include/

