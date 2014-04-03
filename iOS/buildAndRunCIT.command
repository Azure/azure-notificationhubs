function error_exit
{
    echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
    exit 1
}

ABSPATH=$(cd "$(dirname "$0")"; pwd)
cd $ABSPATH

cd WORKSPACE

#create build directory
path=../build/"$(date +%Y-%m%d-%H%M%S)"
mkdir -p $path

#prepare lof file names
buildLogPath=../../../$path/buildLog.txt
testLogPath=../../../$path/testLog.txt


#build framework
echo "******Build framework************"
cd Push_iOS_SDK_CI/iOS/WindowsAzureMessaging
xcodebuild clean &> /dev/null
xcodebuild | sed '/setenv/d' 2>&1 | tee $buildLogPath

#check if build is succeed and zip bins
if [ ! -e build/Release-iphonesimulator/WindowsAzureMessaging.framework ] ; then
    error_exit "****** Build framework failed ************"
fi
cd build/Release-iphonesimulator
zip -r ../../../../../$path/WindowsAzureMessaging.framework.zip WindowsAzureMessaging.framework
cd ../../
echo "******Build framework SUCCEEDED ************"

#build and run CIT
echo "******Build and run CIT************"
cd ../WindowsAzureMessagingTest/
xcodebuild -scheme WindowsAzureMessagingTest -destination 'platform=iOS Simulator,name=iPhone' test | sed '/Compile/d' | sed '/GenerateDSYMFile/d' | sed '/ProcessInfoPlistFile/d' | sed '/builtin/d' | sed '/Ld/d' | sed '/ld/d' |sed '/CopyStringsFile/d' | sed '/PhaseScript/d' | sed '/cd/d' | sed '/\/bin\/sh/d' | sed '/setenv/d' | sed '/\/Application/d' | sed '/^$/N;/^\n$/D' 2>&1 | tee $testLogPath

#check whether test is succeed
grep " TEST SUCCEEDED " $testLogPath &> /dev/null
if [ "$?" != "0" ]; then
    error_exit "******Build or run CIT FAILED ************"
fi
echo "******CIT SUCCEEDED ************"