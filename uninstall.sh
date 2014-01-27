#!/bin/sh

launchctl unload /Library/LaunchDaemons/com.unity3d.cacheserver.plist

rm -f /Library/LaunchDaemons/com.unity3d.cacheserver.plist
rm -rf /Users/Shared/UnityCacheServer /var/log/unitycache

dscl . -delete /Users/unitycache
dscl . -delete /Groups/unitycache
