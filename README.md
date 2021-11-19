# Attach-Detach-Sw
A Swift Recreation of Attach-Detach, with some configurable options

## Usage
To use, you'll need to specify if you are attaching or detaching, See below:

### Attaching
To Attach a DMG, the following command should be run: `attachdetachsw --attach/-a DMGFILE`. Where `DMGFile` is the path of the DMG to attach.
Example output: 
```
iPhone:~ mobile% attachdetachsw -a attachdetachsw.dmg
Attached as disk6
regEntryID: 4295106556
```

### Detaching 
To detach/eject a disk, the following command should be run: `attachdetachsw --detach/-d diskWithNumebr` Where `diskWithNumebr` is the disk to eject.
Example output:
```
