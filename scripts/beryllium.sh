#!/usr/bin/env bash

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
STATUS=Testing
export STATUS
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
*Last Commit*: [${COMMIT_HASH}](${REPO}/commit/${COMMIT_HASH})
*Compiler*: \`${KBUILD_COMPILER_STRING}\`
*Build Status*: \`${STATUS}\`"
}

# Push kernel to channel
push() {
    cd AnyKernel || exit 1
    ZIP=$(echo *.zip)
    tgs "${ZIP}" "Build took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s). | For *${DEVICE} (${CODENAME})* | ${KBUILD_COMPILER_STRING}"
}

# Catch Error
finderr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}

# Compile
compile() {
    cp RvKernel/SE/* arch/arm64/boot/dts/qcom/
    cp RvKernel/OC/sdm845-v2.dtsi arch/arm64/boot/dts/qcom/
    cp RvKernel/OC/gpucc-sdm845.c drivers/clk/qcom/

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

    if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
    fi

    git clone --depth=1 https://github.com/Rve27/AnyKernel3.git AnyKernel -b master
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
zipping() {
    cd AnyKernel || exit 1
    zip -r9 RvKernel-testing-"${BRANCH}"-"${CODENAME}"-"${DATE}".zip ./*
    cd ..
}

sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$((END - START))
push
