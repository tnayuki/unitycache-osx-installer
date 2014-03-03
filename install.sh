#!/bin/bash

if [ $# -ne 1 ]; then
  echo "ERROR: URL not specified."
  exit 1
fi

UNITYCACHE_TMPDIR=`mktemp -d /tmp/unitycache-osx-installer.XXXXXX`

curl -f --url $1 -o $UNITYCACHE_TMPDIR/CacheServer.zip

if [ "$?" -ne 0 ] ; then
   echo "ERROR: Download failed."
   exit 1
fi

unzip $UNITYCACHE_TMPDIR/CacheServer.zip -d $UNITYCACHE_TMPDIR

mkdir -p /Library/UnityCacheServer /var/log/unitycache

mv $UNITYCACHE_TMPDIR/CacheServer/* /Library/UnityCacheServer

rm -rf $UNITYCACHE_TMPDIR

if dscl . -list /Users/unitycache; then
    echo 'unitycache user already exists'
else
    uid=$(dscl . -list /Users uid | sort -nrk 2 | awk '$2 < 500 {print $2 + 1; exit 0}')
    if [ $uid -eq 500 ]; then
        echo 'ERROR: All system uids are in use!'
        exit 1
    fi
    echo "Using uid $uid for Unity Cache Server"

	gid=$uid
    while dscl -search /Groups gid $gid | grep -q $gid; do
        echo "gid $gid is not free, trying next"
        gid=$(($gid + 1))
    done
    echo "Using gid $gid for Unity Cache Server"

	dscl . -create /Groups/unitycache PrimaryGroupID $gid

	dscl . -create /Users/unitycache FullName "Unity Cache Server"
    dscl . -create /Users/unitycache UserShell /bin/bash
    dscl . -create /Users/unitycache Password '*'
    dscl . -create /Users/unitycache UniqueID $uid
    dscl . -create /Users/unitycache PrimaryGroupID $gid
    dscl . -create /Users/unitycache NFSHomeDirectory /Library/UnityCacheServer

    dscl . -append /Groups/unitycache GroupMembership unitycache
fi

chown -R unitycache:unitycache /Library/UnityCacheServer /var/log/unitycache

cat > /Library/LaunchDaemons/com.unity3d.cacheserver.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.unity3d.cacheserver</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Library/UnityCacheServer/RunOSX.command</string>
        <string>--path</string>
        <string>/Library/Caches/com.unity3d.cacheserver</string>
    </array>

    <key>WorkingDirectory</key>
	<string>/Library/UnityCacheServer</string>

    <key>RunAtLoad</key>
    <true />

    <key>KeepAlive</key>
    <true />

    <key>UserName</key>
    <string>unitycache</string>

    <key>GroupName</key>
    <string>daemon</string>

    <key>StandardErrorPath</key>
    <string>/var/log/unitycache/unitycache.log</string>

    <key>StandardOutPath</key>
    <string>/var/log/unitycache/unitycache.log</string>
  </dict>
</plist>
EOF

launchctl load /Library/LaunchDaemons/com.unity3d.cacheserver.plist
