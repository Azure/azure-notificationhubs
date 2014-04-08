function error_exit
{
    echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
    exit 1
}

ABSPATH=$(cd "$(dirname "$0")"; pwd)
cd $ABSPATH

#create build directory
path=../../../build/"$(date +%Y-%m%d-%H%M%S)"
mkdir -p $path

#prepare log file names
buildLogPath=../$path/buildLog.txt
testLogPath=../$path/testLog.txt

#build framework
echo "******Build framework************" 2>&1 | tee -a $bvtLogPath
cd WindowsAzureMessaging
xcodebuild clean &> /dev/null
xcodebuild -scheme Framework -target Framework -configuration Release BUILD_DIR=./Build | sed '/setenv/d' 2>&1 | tee -a $bvtLogPath

#check if build is succeed, zip bins and copy framework to BVT folder
if [ ! -e build/Release-iphonesimulator/WindowsAzureMessaging.framework ] ; then
    error_exit "****** Build framework failed ************" 2>&1 | tee -a $bvtLogPath
fi
cd build/Release-iphonesimulator
ditto WindowsAzureMessaging.framework ../../../BVT/WindowsAzureMessaging.framework/
zip -r ../../../$path/WindowsAzureMessaging.framework.zip WindowsAzureMessaging.framework
cd ../../
echo "******Build framework SUCCEEDED ************" 2>&1 | tee -a $bvtLogPath

#build and run CIT
echo "******Build and run CIT************" 2>&1 | tee -a $bvtLogPath
cd ../WindowsAzureMessagingTest/
xcodebuild -scheme WindowsAzureMessagingTest -destination 'platform=iOS Simulator,name=iPhone' test | sed '/Compile/d' | sed '/GenerateDSYMFile/d' | sed '/ProcessInfoPlistFile/d' | sed '/builtin/d' | sed '/Ld/d' | sed '/ld/d' |sed '/CopyStringsFile/d' | sed '/PhaseScript/d' | sed '/cd/d' | sed '/\/bin\/sh/d' | sed '/setenv/d' | sed '/\/Application/d' | sed '/^$/N;/^\n$/D' 2>&1 | tee -a $bvtLogPath

#check if test is succeed
grep " TEST SUCCEEDED " $testLogPath &> /dev/null
if [ "$?" != "0" ]; then
    error_exit "******Build or run CIT FAILED ************" 2>&1 | tee -a $bvtLogPath
fi
echo "******CIT SUCCEEDED ************" 2>&1 | tee -a $bvtLogPath