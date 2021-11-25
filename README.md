# Attach-Detach-Sw
A Swift Recreation of Attach-Detach, with some configurable options

## Usage
To use, you'll need to specify if you are attaching or detaching, See below:

### Attaching
To Attach a DMG, the following command should be run: `attachdetachsw --attach/-a DMGFILE`. Where `DMGFile` is the path of the DMG to attach.
Example usage: 
```
iPhone:~ mobile% attachdetachsw -a attachdetachsw.dmg
Attached as disk6
```

### Detaching 
To detach/eject a disk, the following command should be run: `attachdetachsw --detach/-d diskWithNumebr` Where `diskWithNumebr` is the disk to eject.
Example usage:
```
iPhone:~ mobile% attachdetachsw -d disk6
Detached /dev/disk6
```

## Options
Though these aren't necessary, the following options can be used:

### Attach Options
- `-f, --file-mode=FILEMODE` Where FILEMODE is a number, sets the filemode while attaching
- `-s, --set-auto-mount` Sets automount to true while attaching
- `-o, --all-dirs` Prints all the `/dev/disk` directories that the DMG was attached to
- `-v, --verify` Verify that the DMG was successfully attached with DIVerifyParams
- `-r, --reg-entry-id` Prints the RegEntryID of the disk the DMG was attached to

### Detach Options
There are currently no options for detaching.

## Building
To build, you must have Theos and the swift-toolchain, you also must be building with a patched SDK. 
```
git clone https://github.com/Serena-io/Attach-Detach-Sw
cd Attach-Detach-Sw
make package
```
