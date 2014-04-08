function error_exit
{
    echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
    exit 1
}

ABSPATH=$(cd "$(dirname "$0")"; pwd)
cd $ABSPATH

#create build directory
path=../../../productionReadyBins/"$(date +%Y-%m%d-%H%M%S)"
mkdir -p $path

#prepare log file names
bvtLogPath=../$path/BVTLog.txt

#prepare test framework
cd BVT
unzip -o GHUnitIOS.framework.zip
sudo rm -rf RunTests.sh
unzip -o RunTests.sh.zip
cd IosSdkTests
unzip -o png.zip
cd ..

echo "***************Build and run BVT *****************" 2>&1 | tee -a $bvtLogPath
GHUNIT_CLI=1 xcodebuild -scheme IosSdkTests -destination 'platform=iOS Simulator,name=iPhone' -configuration Debug -sdk iphonesimulator6.1 clean build 2>&1 | tee -a $bvtLogPath

grep "with 0 failures" $bvtLogPath &> /dev/null
if [ "$?" != "0" ]; then
    error_exit echo "**************IOS SDK BVT Failed*******************"
fi
zip -r ../$path/WindowsAzureMessaging.framework.zip WindowsAzureMessaging.framework
echo "===================================================" 2>&1 | tee -a $bvtLogPath
lipo -info WindowsAzureMessaging.framework/WindowsAzureMessaging 2>&1 | tee -a $bvtLogPath
echo "***************IOS SDK BVT Passed *****************" 2>&1 | tee -a $bvtLogPath