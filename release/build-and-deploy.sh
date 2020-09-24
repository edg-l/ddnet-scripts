#!/usr/bin/zsh
autoload zmv
set -e
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
cd /home/deen/isos/ddnet
if [ "$1" = "nightly" ]; then
  UPDATE_FLAGS="-DAUTOUPDATE=OFF -DINFORM_UPDATE=OFF" \
  UPDATE_FLAGS_MACOSX="-DINFORM_UPDATE=OFF" \
  VERSION="nightly$(date +%Y%m%d)"
  ./build.sh $VERSION &> builds/DDNet-nightly.log
elif [ "$1" = "rc" ]; then
  UPDATE_FLAGS="-DAUTOUPDATE=OFF -DINFORM_UPDATE=OFF" \
  UPDATE_FLAGS_MACOSX="-DINFORM_UPDATE=OFF" \
  VERSION=$2
  ./build.sh $VERSION &> builds/DDNet-$VERSION.log
elif [ "$1" = "release" ]; then
  VERSION=$2
  ./build.sh $VERSION &> builds/DDNet-$VERSION.log
else
  echo "Unknown parameter: $1"
  echo ""
  echo "Nightly:"
  echo "./build-and-deploy.sh nightly"
  echo ""
  echo "Release Candidate:"
  echo "MAIN_REPO_USER=def- MAIN_REPO_BRANCH=pr-15.0.5 ./build-and-deploy.sh rc 15.0.5-rc2"
  echo ""
  echo "Release:"
  echo "./build-and-deploy.sh release 15.0.5"
  echo "and set live for beta, default manually in Steamworks"
  exit 1
fi

scp -q builds/DDNet-$VERSION* ddnet:/var/www/downloads/tmp
ssh ddnet mv /var/www/downloads/tmp/DDNet-$VERSION\* /var/www/downloads
cd steam
for i in *.zip; do
  mkdir ${i:r}
  cd ${i:r}
  unzip ../$i
  cd ..
done
zmv -W "DDNet-$VERSION-*" '*'
cd /home/deen/isos/ddnet/steamcmd/
sed -e "s/Nightly Build/$VERSION/" app_build_412220.vdf > tmp.vdf
if [ "$1" != "nightly" ]; then
  sed -i "s/\"beta\"/\"releasecandidates\"/" tmp.vdf
fi
steamcmd +login deen_ddnet "$(cat pass)" +run_app_build /home/deen/isos/ddnet/steamcmd/tmp.vdf +quit
cd ..
rm -rf builds/DDNet-$VERSION* builds/*.log DDNet-$VERSION* steam/*
