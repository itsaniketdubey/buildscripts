#!/bin/bash 

Build_failiure () {
echo "Build failed"
#curl -s -X POST https://api.telegram.org/bot${BOTID}/sendMessage -d text="$KERNELNAME kernel: Build throwing errors" -d chat_id=${CHATID} -d parse_mode=HTML
cd ${WDIR}
BUILD=$(($BUILD - 1))
echo $BUILD > tee buildno.txt
}


#Variables 
KERNELDIR="/home/madeofgreat/Development/delta_beryllium"
COMPILERDIR="/home/madeofgreat/toolchains/proton-clang"
LOGDIR="/home/madeofgreat/logs"
ANYKERNELDIR="/home/madeofgreat/Development/AnyKernel3"
DEVICE="beryllium"
ARCH="arm64"
SUBARCH="arm64"
LINKER=""
KERNELNAME="micode"
CHATID=-"ded chat"
BOTID="no"
VERSION="no"
BUILD=$(cat buildno.txt)
WDIR=$(pwd)


echo "
    Building $KERNELNAME kernel for $DEVICE
    The source directory is $KERNELDIR
    The compiler directory is $COMPILERDIR
    The linker chosen is $LINKER
    "
    

# Build no.
cd ${WDIR}
BUILD=$(($BUILD + 1))
echo ${BUILD} > buildno.txt


# Building starts here
cd ${KERNELDIR}
#curl -s -X POST https://api.telegram.org/bot${BOTID}/sendMessage -d text="$KERNELNAME kernel for ${DEVICE}: Build ${BUILD} started at HEAD: <code>$(git log --pretty=format:'%h : %s' -1)</code>" -d chat_id=${CHATID} -d parse_mode=HTML
make O=out ARCH=$ARCH ${DEVICE}_defconfig
if [ $? -ne 0 ]
then
    Build_failiure
else
    echo "  Made ${DEVICE}_defconfig"
    if [ -z $LINKER ]
    then
        PATH="${COMPILERDIR}/bin:${PATH}" \
        make -j$(nproc --all) O=out \
        ARCH=${ARCH} \
        CC=clang \
        CROSS_COMPILE=${COMPILERDIR}/bin/aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=${COMPILERDIR}/bin/arm-linux-gnueabi- 
    else 
        PATH="${COMPILERDIR}/bin:${PATH}" \
        make LD=ld.$LINKER -j$(nproc --all) O=out \
        ARCH=${ARCH} \
        CC=clang \
        CROSS_COMPILE=${COMPILERDIR}/bin/aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=${COMPILERDIR}/bin/arm-linux-gnueabi- \
        ld-name=$LINKER
        if [ $? -ne 0 ]
        then
            Build_failiure
        else 
            echo "Build succesful"
            
            # Making flashable .zip
            mv ${KERNELDIR}/out/arch/arm64/boot/Image.gz-dtb ${ANYKERNELDIR}/
            cd ${ANYKERNELDIR}
            echo ${KERNELNAME}_Kernel_${DEVICE}_${VERSION}_T${BUILD} > version
            zip -r ${ANYKERNELDIR}/${KERNELNAME}_Kernel_${DEVICE}_${VERSION}_${BUILD}.zip *
        
            # Telegram post
            #curl -s -X POST https://api.telegram.org/bot${BOTID}/sendMessage -d text="$KERNELNAME kernel: Build succesful" -d chat_id="${CHATID}" -d parse_mode=HTML
            #curl -F chat_id="${CHATID}" -F document=@"${ANYKERNELDIR}/${KERNELNAME}_Kernel_${DEVICE}_${VERSION}_${BUILD}.zip" https://api.telegram.org/bot${BOTID}/sendDocument
            
            # Removing uploaded file
            #rm ${ANYKERNELDIR}/${KERNELNAME}_Kernel_${DEVICE}_${VERSION}_${BUILD}.zip
        fi
    fi
fi
