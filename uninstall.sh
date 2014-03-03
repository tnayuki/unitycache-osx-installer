#!/bin/sh

launchctl unload /Library/LaunchDaemons/com.unity3d.cacheserver.plist

rm -f /Library/LaunchDaemons/com.unity3d.cacheserver.plist
rm -rf /Library/UnityCacheServer /var/log/unitycache /Library/Caches/com.unity3d.cacheserver

dscl . -delete /Users/unitycache
dscl . -delete /Groups/unitycache
