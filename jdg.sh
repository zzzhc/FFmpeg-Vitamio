#!/bin/bash

echo "  _    __   _    __                           _             "
echo " | |  / /  (_)  / /_   ____ _   ____ ___     (_)  ___       "
echo " | | / /  / /  / __/  / __ \/  / __ __  \   / /  / __ \     "
echo " | |/ /  / /  / /_   / /_/ /  / / / / / /  / /  / /_/ /     "
echo " |___/  /_/   \__/   \__,_/  /_/ /_/ /_/  /_/   \____/      "


#RTMPDUMP
RTMPDUMP=/home/le/Code/VPlayer/git.vplayer.net/vplayer/librtmp
if [ -z "$RTMPDUMP" ]; then
  echo "No define RTMPDUMP before starting"
  echo "Please clone from git@github.com:yixia/librtmp.git, and run ndk-build ";
  exit 1
fi
# Test script

DEST=`pwd`/build/android
SOURCE=`pwd`
SSL=$SSL


TOOLCHAIN=/tmp/vitamio
SYSROOT=$TOOLCHAIN/sysroot/
if [ -d $TOOLCHAIN ]; then
    echo "Toolchain is already build."
else
		$ANDROID_NDK/build/tools/make-standalone-toolchain.sh --toolchain=arm-linux-androideabi-4.8 \
			--system=linux-x86_64 --platform=android-14 --install-dir=$TOOLCHAIN
fi

export PATH=$TOOLCHAIN/bin:$PATH
export CC="ccache arm-linux-androideabi-gcc"
export LD=arm-linux-androideabi-ld
export AR=arm-linux-androideabi-ar

CFLAGS="-std=c99 -O3 -Wall -mthumb -pipe -fpic -fasm \
  -finline-limit=300 -ffast-math \
  -Wno-psabi -Wa,--noexecstack \
  -fdiagnostics-color=always \
  -D__ARM_ARCH_5__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5TE__ \
  -DANDROID -DNDEBUG \
  -I$SSL/include"

LDFLAGS="-lm -lz -Wl,--no-undefined -Wl,-z,noexecstack"

FFMPEG_FLAGS_COMMON="--target-os=linux \
  --cross-prefix=arm-linux-androideabi- \
    --enable-cross-compile \
    --enable-version3 \
    --enable-shared \
    --disable-static \
    --disable-symver \
    --disable-programs \
    --disable-doc \
    --disable-avdevice \
    --disable-encoders  \
    --disable-muxers \
    --disable-devices \
    --disable-everything \
    --disable-protocols  \
    --disable-demuxers \
    --disable-decoders \
    --disable-bsfs \
    --disable-debug \
    --enable-optimizations \
    --enable-filters \
    --enable-parsers \
    --disable-parser=hevc \
    --enable-swscale  \
    --enable-network \
    --enable-protocol=file \
    --enable-protocol=http \
    --enable-protocol=rtmp \
    --enable-protocol=rtp \
    --enable-protocol=mmst \
    --enable-protocol=mmsh \
    --enable-protocol=hls \
    --enable-protocol=crypto \
    --enable-demuxer=hls \
    --enable-demuxer=mpegts \
    --enable-demuxer=mpegtsraw \
    --enable-demuxer=mpegvideo \
    --enable-demuxer=concat \
    --enable-demuxer=mov \
    --enable-demuxer=flv \
    --enable-demuxer=rtsp \
    --enable-demuxer=mp3 \
    --enable-demuxer=matroska \
    --enable-decoder=mpeg4 \
    --enable-decoder=mpegvideo \
    --enable-decoder=mpeg1video \
    --enable-decoder=mpeg2video \
    --enable-decoder=h264 \
    --enable-decoder=h263 \
    --enable-decoder=flv \
    --enable-decoder=vp8 \
    --enable-decoder=wmv3 \
    --enable-decoder=aac \
    --enable-decoder=ac3 \
    --enable-decoder=mp3 \
    --enable-decoder=nellymoser \
    --enable-muxer=mp4 \
    --enable-asm \
    --enable-pic"

for version in neon; do

  cd $SOURCE

  FFMPEG_FLAGS="$FFMPEG_FLAGS_COMMON"

  case $version in
    neon)
      FFMPEG_FLAGS="--arch=armv7-a \
        --cpu=cortex-a8 \
        $FFMPEG_FLAGS"
      EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mvectorize-with-neon-quad"
      EXTRA_LDFLAGS="-Wl,--fix-cortex-a8 -L$SSL/libs/armeabi-v7a -L$RTMPDUMP/libs/armeabi-v7a"
      SSL_OBJS=`find $SSL/obj/local/armeabi-v7a/objs/ssl $SSL/obj/local/armeabi-v7a/objs/crypto -type f -name "*.o"`
      RTMP_OBJS=`find $RTMPDUMP/obj/local/armeabi-v7a/objs/rtmp -type f -name "*.o"`
      ;;
    armv7)
      FFMPEG_FLAGS="--arch=armv7-a \
        --cpu=cortex-a8 \
        $FFMPEG_FLAGS"
      EXTRA_CFLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp"
      EXTRA_LDFLAGS="-Wl,--fix-cortex-a8 -L$SSL/libs/armeabi-v7a"
      SSL_OBJS=`find $SSL/obj/local/armeabi-v7a/objs/ssl $SSL/obj/local/armeabi-v7a/objs/crypto -type f -name "*.o"`
      ;;
    vfp)
      FFMPEG_FLAGS="--arch=arm \
        $FFMPEG_FLAGS"
      EXTRA_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=softfp"
      EXTRA_LDFLAGS="-L$SSL/libs/armeabi"
      SSL_OBJS=`find $SSL/obj/local/armeabi/objs/ssl $SSL/obj/local/armeabi/objs/crypto -type f -name "*.o"`
      ;;
    armv6)
      FFMPEG_FLAGS="--arch=arm \
        $FFMPEG_FLAGS"
      EXTRA_CFLAGS="-march=armv6"
      EXTRA_LDFLAGS="-L$SSL/libs/armeabi"
      SSL_OBJS=`find $SSL/obj/local/armeabi/objs/ssl $SSL/obj/local/armeabi/objs/crypto -type f -name "*.o"`
      ;;
    *)
      FFMPEG_FLAGS=""
      EXTRA_CFLAGS=""
      EXTRA_LDFLAGS=""
      SSL_OBJS=""
      ;;
  esac

  #PREFIX="$DEST/$version" && rm -rf $PREFIX && mkdir -p $PREFIX
  #FFMPEG_FLAGS="$FFMPEG_FLAGS --prefix=$PREFIX"

   #./configure $FFMPEG_FLAGS --extra-cflags="$CFLAGS $EXTRA_CFLAGS" --extra-ldflags="$LDFLAGS $EXTRA_LDFLAGS" | tee $PREFIX/configuration.txt
  #cp config.* $PREFIX
  #[ $PIPESTATUS == 0 ] || exit 1

  #make clean
  #find . -name "*.o" -type f -delete
  make -j4 || exit 1

  rm libavcodec/log2_tab.o libavformat/log2_tab.o libswresample/log2_tab.o
      $CC -o $PREFIX/libffmpeg.so -shared $LDFLAGS $EXTRA_LDFLAGS $SSL_OBJS $RTMP_OBJS\
    libavutil/*.o libavutil/arm/*.o libavcodec/*.o libavcodec/arm/*.o libavformat/*.o libavfilter/*.o libswresample/*.o libswresample/arm/*.o libswscale/*.o compat/*.o


  cp $PREFIX/libffmpeg.so $PREFIX/libffmpeg-debug.so
  arm-linux-androideabi-strip --strip-unneeded $PREFIX/libffmpeg.so

  adb push $PREFIX/libffmpeg.so /data/data/io.vov.vitamio.demo/libs/

done
