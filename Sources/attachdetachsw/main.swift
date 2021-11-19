import Foundation
import DI2Support

let CMDLineArgs = Array(CommandLine.arguments.dropFirst())

let doDetach = CMDLineArgs.contains("--detach") || CMDLineArgs.contains("-d")
let doAttach = CMDLineArgs.contains("--attach") || CMDLineArgs.contains("-a")
let userWantsHelpMessage = CMDLineArgs.contains("--help") || CMDLineArgs.contains("-h")
let shouldSetAutoMount = CMDLineArgs.contains("--set-auto-mount") || CMDLineArgs.contains("-s")
let shouldPrintRegEntryID = CMDLineArgs.contains("--get-reg-entry-id") || CMDLineArgs.contains("-g")
let shouldPrintAllDiskDirs = CMDLineArgs.contains("--all-disk-dirs")

func printHelp() {
    print("""
          AttachDetachSW --- A Swift recreation of attach-detach.
          
          General Options:
            -a, --attach [DMGFILE]            Specify a DMG file to attach
            -d, --detach [DISKNAME]           Specify a disk name to detach
          
          Attach Options:
            --all-disk-dirs                   Prints all the /dev/disk directories that the DMG was attached to
            -f, --file-mode=FILEMODE          Specify the filemode to attach the specified DMG with, where FILEMODE is a number
            -s, --set-auto-mount              Sets the automount to true while attaching specified DMG
            -g, --get-reg-entry-id            Prints the RegEntryID of the disk that the DMG was attached to
          
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
    var handler: DIDeviceHandle?
    for dmg in arrOfSpecifiedDMGs {
        let DMGURL = URL(fileURLWithPath: dmg)
        var err:NSError?
        let attachParams = DIAttachParams(url: DMGURL, error: err)
        guard err == nil else {
            let errToShow = err?.localizedFailureReason ?? err?.localizedDescription
            fatalError("Error encountered with DIAttachParams: \(errToShow ?? "Unknown Error")")
        }
        attachParams?.autoMount = shouldSetAutoMount
        let fileModeArr = CMDLineArgs.filter() { $0.hasPrefix("--file-mode=") || $0.hasPrefix("-f=") }
        if !fileModeArr.isEmpty {
            let fileModeSpecified = fileModeArr[0].replacingOccurrences(of: "--file-mode=", with: "").replacingOccurrences(of: "-f=", with: "") // remove both --file-mode= and -f= in order to get the specified number
            guard let fileModeSpecifiedInt = Int64(fileModeSpecified) else {
                fatalError("User used --file-mode however there was either no file mode specified or the filemode specified wasn't an Int. SYNTAX: --file-mode=FILE-MODE, example: --file-mode=2")
            }
            attachParams?.fileMode = fileModeSpecifiedInt
            print("Set file mode to \(fileModeSpecifiedInt)")
        }
        
        DiskImages2.attach(with: attachParams, handle: &handler, error: &err)
        
        guard err == nil else {
            let errToShow = err?.localizedFailureReason ?? err?.localizedDescription
            fatalError("Error encountered while attaching DMG \"\(dmg)\": \(errToShow ?? "Unknown Error")")
        }
        
        guard let bsdName = handler?.bsdName() else {
            fatalError("Attached DMG \"\(dmg)\" However couldn't get name of attached disk.")
        }
        print("Attached as \(bsdName)")
        let devDiskDirsThatShouldExist = ["/dev/\(bsdName)", "/dev/\(bsdName)s1", "/dev/\(bsdName)s1s1"].filter() { FileManager.default.fileExists(atPath: $0) }
        if shouldPrintAllDiskDirs {
            print("dev disk dirs that exist: ")
            for dir in devDiskDirsThatShouldExist {
                print(dir)
            }
        }
        if shouldPrintRegEntryID {
            if let regEntryID = handler?.regEntryID() {
                print("regEntryID: \(regEntryID)")
            } else {
                print("Wasn't able to obtain regEntryID.")
            }
        }
    }
}
