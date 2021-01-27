# OSX-Debug
A script to generate debugging files for hackintosh by black.dragon74

# Installation
- Open up Terminal and type:
```bash
sudo curl -o /usr/local/bin/gen_debug https://raw.githubusercontent.com/black-dragon74/OSX-Debug/master/gen_debug.sh && sudo chmod a+x /usr/local/bin/gen_debug
```

# Usage
It is fully automated script. All the dependencies are fetched automatically from the git.

Just open up terminal and type: gen_debug

In case you have no internet connectivity, do the following :-
- Download the source code as a zip file from github
- Open Terminal and type,

- cd ~/Downloads/OSX-Debu*
- mkdir -p ~/Library/debugNk
- cp -rf ./* ~/Library/debugNk
- sudo cp gen_debug.sh /usr/bin/gen_debug
- sudo chmod a+x /usr/bin/gen_debug
- unzip -o IORegistryExplorer.zip -d /Applications/

That's it, you can now use the script offline as all required files are available offline just by launching terminal and typing: gen_debug

# Credits
RehabMan for MountEFI script

# Notes
A few files namely, mount_efi.sh and patchmatic are present here on github as they are verified by their MD5 sums upon downloading.

I, black.dragon74, in no way intend to offense any developer. I respect them. If you have any issues you can easily contact me.

All the best!
