# Attach-Detach-Sw
A CLI Tool written in Swift as a recreation of Attach-Detach, with some configurable options


## Attaching 
To attach, use the `-a / --attach` option and specify the DMG(s) to attach, for example:
```
attachdetachsw --attach randomDMG.dmg
```
Will attach `randomDMG.dmg` and print out the disk that it was attached to 

### Attaching options:
The following options can be used with `-a / --attach`:

- `-f, --file-mode=FILE-MODE`        Specify a FileMode to attach the DMG with, specified FileMode must be a number
- `-s, --set-auto-mount=TRUE/FALSE`  Sets Auto-Mount to true or false based on which the user specified
- `-r, --reg-entry-id`               Prints the RegEntryID of the disk that the DMG was attached to
- `-o, --all-dirs`                   Prints all the directories to which the DMG was attached to

*Notes: If -s/--set-auto-mount wasn't used, auto mount is automatically set to true*

## Detaching
To detach, use the `-d / --detach` option and specify the Disk Name(s) to detach, for example:
```
attachdetachsw -d disk7
```
Will detach `disk7`, using `/dev/disk7` would be identical in this situation

*Note: Detaching doesn't have any configurable options*

## Getting the Image URL Of an attached disk
To get the original Image URL of a disk that is already attached, use the `-i / --image-url` option, for example:
```
attachdetachsw -i disk7
```
Will return the URL Of the image that `disk7` was attached was.

So, for example, if `disk7` was attached with a DMG at `/private/var/mobile/randomDMG.dmg`, that path will be printed 
