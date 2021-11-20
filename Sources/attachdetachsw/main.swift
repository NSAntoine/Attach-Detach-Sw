import Foundation
import DI2Support

let CMDLineArgs = Array(CommandLine.arguments.dropFirst())

let doDetach = CMDLineArgs.contains("--detach") || CMDLineArgs.contains("-d")
let doAttach = CMDLineArgs.contains("--attach") || CMDLineArgs.contains("-a")
let userWantsHelpMessage = CMDLineArgs.contains("--help") || CMDLineArgs.contains("-h")
let shouldSetAutoMount = CMDLineArgs.contains("--set-auto-mount") || CMDLineArgs.contains("-s")
let shouldPrintRegEntryID = CMDLineArgs.contains("--reg-entry-id") || CMDLineArgs.contains("-r")
let shouldPrintAllDiskDirs = CMDLineArgs.contains("--all-dirs") || CMDLineArgs.contains("-o")
let shouldPrintioMedia = CMDLineArgs.contains("--io-media") || CMDLineArgs.contains("-i")

func printHelp() {
    print("""
          AttachDetachSW --- A Swift recreation of attach-detach.
          
          General Options:
            -a, --attach [DMGFILE]            Specify a DMG file to attach
            -d, --detach [DISKNAME]           Specify a disk name to detach
          
          Attach Options:
            -o, --all-dirs                    Prints all the /dev/disk directories that the DMG was attached to
            -f, --file-mode=FILEMODE          Specify the filemode to attach the specified DMG with, where FILEMODE is a number
            -s, --set-auto-mount              Sets the automount to true while attaching specified DMG
            -r, --reg-entry-id                Prints the RegEntryID of the disk the DMG was attached to
            -i, --io-media                    Prints the IOMedia of the disk the DMG was attached to
          
          Notes:
            It doesn't make sense to use any Attach Options with --detach / -d
          
          Example usage:
            attachdetachsw --attach randomDMG.dmg
            attachdetachsw --detach disk7
          """)
}
if CMDLineArgs.isEmpty || userWantsHelpMessage || (!doDetach && !doAttach) {
    printHelp()
}

if doDetach {
    let arrOfDiskPathsSpecified = CMDLineArgs.filter() { $0.contains("disk") }
    guard !arrOfDiskPathsSpecified.isEmpty else {
        fatalError("User used --detach / -d however did not specify a valid disk name. See attachdetachsw --help for more information.")
    }
    for DiskName in arrOfDiskPathsSpecified {
        var diskNameToUse = DiskName
        diskNameToUse.hasPrefix("/dev/") ? nil : diskNameToUse.insert(contentsOf: "/dev/", at: diskNameToUse.startIndex)
        
        let fd = open(diskNameToUse, O_RDONLY)
        guard fd != -1 else {
            close(fd)
            fatalError("Error encountered while opening \(diskNameToUse): \(String(cString: strerror(errno)))")
        }
        
        // See more here: https://stackoverflow.com/questions/69961734/getting-ioctl-numbers-in-swit/69961934#69961934
        
        var ioctlEjectCode:UInt {
            let IOC_VOID: UInt = 0x20000000
            // DKIOEJECT Code is the 21th of group d
            let char = "d" as Character
            let num = 21 as UInt
            let g = UInt(UInt(char.asciiValue!) << 8)
            
            return IOC_VOID | g | num
        }
        let ret = ioctl(fd, ioctlEjectCode)
        guard ret != -1 else {
            close(fd)
            fatalError("Error encountered while ejecting \(diskNameToUse): \(String(cString: strerror(errno)))")
        }
        print("Detached \(diskNameToUse)")
    }
}

if doAttach {
    let arrOfSpecifiedDMGs = CMDLineArgs.filter() { NSString(string: $0).pathExtension == "dmg" && FileManager.default.fileExists(atPath: $0) }
    guard !arrOfSpecifiedDMGs.isEmpty else {
        fatalError("User used --attach / -a however either didn't specify a DMG file or specified a DMG file that doesn't exist. See attachdetachsw --help for more information.")
    }
    var handler:DIDeviceHandle?
    
    for dmg in arrOfSpecifiedDMGs {
        let DMGURL = URL(fileURLWithPath: dmg)
        var err:NSError?
        let attachParams = DIAttachParams(url: DMGURL, error: err)
        guard err == nil else {
            let errToShow = err?.localizedFailureReason ?? err?.localizedDescription
            fatalError("Error encountered with DIAttachParams: \(errToShow ?? "Unknown Error")")
        }
        attachParams?.autoMount = shouldSetAutoMount
        let fileModeArr = CMDLineArgs.filter() { $0.hasPrefix("--file-mode=") || $0.hasPrefix("-f=") }.map() { $0.replacingOccurrences(of: "--file-mode=", with: "").replacingOccurrences(of: "-f=", with: "")}
        if fileModeArr.indices.contains(0) {
            guard let fileModeSpecified = Int64(fileModeArr[0]) else {
                fatalError("User used --file-mode/-f however the filemode specified is not valid, the filemode specified must be an integer. Example: --file-mode=3")
            }
            print("Setting filemode to \(fileModeSpecified)")
            attachParams?.fileMode = fileModeSpecified
        }
        DiskImages2.attach(with: attachParams, handle: &handler, error: &err)
        
        guard err == nil else {
            let errToShow = err?.localizedFailureReason ?? err?.localizedDescription
            fatalError("Error encountered while attaching DMG \"\(dmg)\": \(errToShow ?? "Unknown Error")")
        }
        guard let handler = handler, let BSDName = handler.bsdName else {
            fatalError("Attached DMG However couldn't get info from handler..")
        }
        print("Attached as \(BSDName)")
        shouldPrintRegEntryID ? print("regEntryID: \(handler.regEntryID)") : nil
        let devDiskDirsThatDoExist = ["/dev/\(BSDName)", "/dev/\(BSDName)s1", "/dev/\(BSDName)s1s1"].filter() { FileManager.default.fileExists(atPath: $0) } // Make an array of the devDisk Dirs that should exist, and filter by the ones that actually do
        shouldPrintAllDiskDirs ? print("All dev disk directories DMG Was attached to: \(devDiskDirsThatDoExist.joined(separator: ", "))") : nil
        shouldPrintioMedia ? print("ioMedia: \(handler.ioMedia)") : nil
    }
}
