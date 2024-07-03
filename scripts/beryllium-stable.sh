#!/usr/bin/env bash

rm -rf kernel
git clone --depth=1 $source_kernel -b $branch kernel
cd kernel
mkdir -p out
mkdir out/RvKernel
mkdir out/RvKernel/NSE_Stock_old_driver
mkdir out/RvKernel/NSE_Stock_new_driver
mkdir out/RvKernel/NSE_800_old_driver
mkdir out/RvKernel/NSE_800_new_driver
mkdir out/RvKernel/NSE_835_old_driver
mkdir out/RvKernel/NSE_835_new_driver
mkdir out/RvKernel/SE_Stock_old_driver
mkdir out/RvKernel/SE_Stock_new_driver
mkdir out/RvKernel/SE_800_old_driver
mkdir out/RvKernel/SE_800_new_driver
mkdir out/RvKernel/SE_835_old_driver
mkdir out/RvKernel/SE_835_new_driver

setup_clang() {
    rm -rf clang
    echo "Downloading clang..."
    mkdir -p ${PWD}/clang
        wget --no-check-certificate https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r522817.tar.gz -O ${PWD}/clang/clang-r522817.tar.gz &>/dev/null
        tar -xzf ${PWD}/clang/clang-r522817.tar.gz -C ${PWD}/clang
        PATH="${PWD}/clang/bin:${PATH}"
    echo "Done"
}

#setup
IMAGE="$GITHUB_WORKSPACE/kernel/out/arch/arm64/boot/Image.gz-dtb"
DATE=$(date +"%Y%m%d-%H%M")
START=$(date +"%s")
KBUILD_COMPILER_STRING="AOSP Clang 18.0.1"
export KBUILD_COMPILER_STRING
ARCH=arm64
export ARCH
KBUILD_BUILD_HOST="Rve27"
export KBUILD_BUILD_HOST
KBUILD_BUILD_USER="Radika"
export KBUILD_BUILD_USER
DEVICE="Pocophone F1"
export DEVICE
CODENAME="beryllium"
export CODENAME
DEFCONFIG="rvkernel/rvkernel_defconfig"
export DEFCONFIG
COMMIT_HASH=$(git rev-parse --short HEAD)
export COMMIT_HASH
PROCS=$(nproc --all)
export PROCS
ccache -M 100G
export USE_CCACHE=1
LC_ALL=C
export LC_ALL

tg() {
    curl -sX POST https://api.telegram.org/bot"${token}"/sendMessage \
        -d chat_id="${chat_id}" \
        -d parse_mode=Markdown \
        -d disable_web_page_preview=true \
        -d message_thread_id="${topic_id}" \
        -d text="$1" &>/dev/null
}

tgs() {
    MD5=$(md5sum "$1" | cut -d' ' -f1)
    curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${token}"/sendDocument \
        -F "chat_id=${chat_id_2}" \
        -F "parse_mode=Markdown" \
        -F "caption=$2 | *MD5*: \`$MD5\`"
}

# Send Build Info
sendinfo() {
    tg "
• RvKernel Pocophone F1 (beryllium) •
*Building on*: \`Github actions\`
*Date*: \`${DATE}\`
*Device*: \`${DEVICE} (${CODENAME})\`
*Branch*: \`$(git rev-parse --abbrev-ref HEAD)\`
*Last Commit*: [${COMMIT_HASH}](${source_kernel}/commit/${COMMIT_HASH})
*Compiler*: \`${KBUILD_COMPILER_STRING}\`
*Build Status*: \`${STATUS}\`"
}

# Push kernel to channel
push() {
    cd $GITHUB_WORKSPACE/kernel/out/RvKernel
    ZIP=$(echo *.zip)
    tgs "${ZIP}" "Build took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s). | For *${DEVICE} (${CODENAME})* | ${KBUILD_COMPILER_STRING}"
}

# Catch Error
finderr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build failed | *${DEVICE} (${CODENAME})* | ${KBUILD_COMPILER_STRING}"
    exit 1
}

# Compile
compile() {
    make O=out ARCH=arm64 $DEFCONFIG
    make -j$(nproc --all) O=out LLVM=1 \
        ARCH=arm64 \
        CC="ccache clang" \
        LD=ld.lld \
        AR=llvm-ar \
        AS=llvm-as \
        NM=llvm-nm \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}

nse_stock_old_driver() {
cp RvKernel/NSE/* arch/arm64/boot/dts/qcom/
cp RvKernel/STOCK/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/STOCK/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-9.1.24/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/NSE_Stock_old_driver/Image.gz-dtb
    fi
}

nse_stock_new_driver() {
cp RvKernel/NSE/* arch/arm64/boot/dts/qcom/
cp RvKernel/STOCK/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/STOCK/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-10.3.7/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/NSE_Stock_new_driver/Image.gz-dtb
    fi
}

nse_800_old_driver() {
cp RvKernel/NSE/* arch/arm64/boot/dts/qcom/
cp RvKernel/OC/800/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/OC/800/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-9.1.24/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/NSE_800_old_driver/Image.gz-dtb
    fi
}

nse_800_new_driver() {
cp RvKernel/NSE/* arch/arm64/boot/dts/qcom/
cp RvKernel/OC/800/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/OC/800/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-10.3.7/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/NSE_800_new_driver/Image.gz-dtb
    fi
}

nse_835_old_driver() {
cp RvKernel/NSE/* arch/arm64/boot/dts/qcom/
cp RvKernel/OC/835/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/OC/835/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-9.1.24/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/NSE_835_old_driver/Image.gz-dtb
    fi
}

nse_800_new_driver() {
cp RvKernel/NSE/* arch/arm64/boot/dts/qcom/
cp RvKernel/OC/835/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/OC/835/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-10.3.7/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/NSE_835_new_driver/Image.gz-dtb
    fi
}

se_stock_old_driver() {
cp RvKernel/SE/* arch/arm64/boot/dts/qcom/
cp RvKernel/STOCK/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/STOCK/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-9.1.24/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/SE_Stock_old_driver/Image.gz-dtb
    fi
}

se_stock_new_driver() {
cp RvKernel/SE/* arch/arm64/boot/dts/qcom/
cp RvKernel/STOCK/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/STOCK/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-10.3.7/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/SE_Stock_new_driver/Image.gz-dtb
    fi
}

se_800_old_driver() {
cp RvKernel/SE/* arch/arm64/boot/dts/qcom/
cp RvKernel/OC/800/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/OC/800/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-9.1.24/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/SE_800_old_driver/Image.gz-dtb
    fi
}

se_800_new_driver() {
cp RvKernel/SE/* arch/arm64/boot/dts/qcom/
cp RvKernel/OC/800/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/OC/800/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-10.3.7/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/SE_800_new_driver/Image.gz-dtb
    fi
}

se_835_old_driver() {
cp RvKernel/SE/* arch/arm64/boot/dts/qcom/
cp RvKernel/OC/835/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/OC/835/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-9.1.24/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/SE_835_old_driver/Image.gz-dtb
    fi
}

se_835_new_driver() {
cp RvKernel/SE/* arch/arm64/boot/dts/qcom/
cp RvKernel/OC/835/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
cp RvKernel/OC/835/gpucc-sdm845.c drivers/clk/qcom/
cp RvKernel/fw-touch-10.3.7/* firmware/
compile
    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    else
        cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/SE_835_new_driver/Image.gz-dtb
    fi
}

# Zipping
zipping() {
    cd out/RvKernel || exit 1
    zip -r9 RvKernel-"${STATUS}"-"${branch}"-"${CODENAME}"-"${DATE}".zip ./*
    cd ..
}

success() {
    tg "
Build success
*${DEVICE} (${CODENAME})* | ${KBUILD_COMPILER_STRING}
$((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)."
}

setup_clang
sendinfo
nse_stock_old_driver
nse_stock_new_driver
nse_800_old_driver
nse_800_new_driver
nse_835_old_driver
nse_835_new_driver
se_stock_old_driver
se_stock_new_driver
se_800_old_driver
se_800_new_driver
se_835_old_driver
se_835_new_driver
zipping
END=$(date +"%s")
DIFF=$((END - START))
push
success
