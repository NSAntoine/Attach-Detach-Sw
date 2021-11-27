import Foundation

let CMDLineArgs = Array(CommandLine.arguments.dropFirst())

let arrOfSpecifiedDMGs = CMDLineArgs.filter() { NSString(string: $0).pathExtension == "dmg" && FileManager.default.fileExists(atPath: $0) }
// Detect if the user used --attach/-a or if the user specified a DMG without --attach/-a
let doAttach = (CMDLineArgs.contains("--attach") || CMDLineArgs.contains("-a")) || !arrOfSpecifiedDMGs.isEmpty

let DiskPathsToEject = CMDLineArgs.filter() { $0.contains("disk") && NSString(string: $0).pathExtension != "dmg" }
// Detect if the user used --detach/-d or if the user specified a disk without --detach/-d
let doDetach = (CMDLineArgs.contains("--detach") || CMDLineArgs.contains("-d")) || !DiskPathsToEject.isEmpty

let shouldPrintRegEntryID = CMDLineArgs.contains("--reg-entry-id") || CMDLineArgs.contains("-r")
let shouldPrintAllDiskDirs = CMDLineArgs.contains("--all-dirs") || CMDLineArgs.contains("-o")
// Short option for --detach: -d

func printHelp() {
    print("""
          AttachDetachSW --- A Swift recreation of attach-detach with some configurable options.
          Made by Serena-io.
          
          General Options:
            -a, --attach [DMGFILE]            Specify a DMG file to attach
            -d, --detach [DISKNAME]           Specify a disk name to detach
          
          Attach Options:
            -o, --all-dirs                    Prints all the /dev/disk directories that the DMG was attached to
            -f, --file-mode=FILEMODE-NUMBER   Specify the filemode to attach the specified DMG with
            -s, --set-auto-mount              Sets the automount to true while attaching specified DMG
            -r, --reg-entry-id                Prints the RegEntryID of the disk the DMG was attached to
          
          Notes:
            If the user does not specify --attach/-a or --detach/-d, then it will attach any DMGs given or detach any given disk, which means using --attach/-a or --detach/-d is not needed most of the time. See example usage
          
          Example usage:
            attachdetachsw --attach randomDMG.dmg
            attachdetachsw --detach disk7
            attachdetachsw someDMG.dmg
            attachdetachsw disk8
          """)
}
if CMDLineArgs.contains("--help") || CMDLineArgs.contains("-h") {
    printHelp()
    exit(0)
}

if CMDLineArgs.isEmpty || (!doDetach && !doAttach) {
    print("User must specify a DMG to attach, or a disk name to detach")
    print("Examples:")
    print("attachdetachsw --attach randomDMG.dmg")
    print("attachdetachsw --detach disk7")
    print("Use attachdetachsw --help to see more.")
    print("Exiting.")
    exit(2)
}

if doDetach {
    guard !DiskPathsToEject.isEmpty else {
        fatalError("User used --detach / -d however did not specify a valid disk name. See attachdetachsw --help for more information.")
    }
    for var DiskName in DiskPathsToEject {
        detachDisk(DiskName: &DiskName)
    }
}

if doAttach {
    guard !arrOfSpecifiedDMGs.isEmpty else {
        fatalError("User used --attach / -a however either didn't specify a DMG file or specified a DMG file that doesn't exist. See attachdetachsw --help for more information.")
    }
    
    for dmg in arrOfSpecifiedDMGs {
        attachDMG(DMGFile: dmg)
    }
}
