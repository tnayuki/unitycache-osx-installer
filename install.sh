#!/bin/bash

UNITYCACHE_URL=http://netstorage.unity3d.com/unity/CacheServer-4.3.3.zip

curl --silent --url ${UNITYCACHE_URL} -o /tmp/CacheServer.zip
unzip /tmp/CacheServer.zip -d /tmp

mkdir -p /Users/Shared/UnityCacheServer/Home /var/log/unitycache

mv /tmp/CacheServer/* /Users/Shared/UnityCacheServer/Home

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
    dscl . -create /Users/unitycache NFSHomeDirectory /Users/Shared/UnityCacheServer

    dscl . -append /Groups/unitycache GroupMembership unitycache
fi

chown -R unitycache:unitycache /Users/Shared/UnityCacheServer /var/log/unitycache

cat > /Library/LaunchDaemons/com.unity3d.cacheserver.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.unity3d.cacheserver</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Users/Shared/UnityCacheServer/Home/RunOSX.command</string>
    </array>

    <key>WorkingDirectory</key>
	<string>/Users/Shared/UnityCacheServer/Home</string>

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
