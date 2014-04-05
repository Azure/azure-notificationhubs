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
bvtLogPath=../$path/sdkLog.txt

#prepare test framework
cd BVT
unzip -o GHUnitIOS.framework.zip
sudo rm -rf RunTests.sh
unzip -o RunTests.sh.zip
cd IosSdkTests
unzip -o png.zip
cd ..

GHUNIT_CLI=1 xcodebuild -scheme IosSdkTests -destination 'platform=iOS Simulator,name=iPhone' -configuration Debug -sdk iphonesimulator6.1 clean build | grep -e "Executed" -e "SUCCESS" -e "Starting" -e "FAIL"  2>&1 | tee $bvtLogPath

grep "with 0 failures" $bvtLogPath &> /dev/null
if [ "$?" != "0" ]; then
    error_exit echo "**************IOS SDK BVT Failed*******************"
fi
echo "***************IOS SDK BVT Passed *****************"