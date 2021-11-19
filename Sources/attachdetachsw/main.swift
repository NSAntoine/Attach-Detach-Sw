import Foundation
import DI2Support

let CMDLineArgs = Array(CommandLine.arguments.dropFirst())

let doDetach = CMDLineArgs.contains("--detach") || CMDLineArgs.contains("-d")
let doAttach = CMDLineArgs.contains("--attach") || CMDLineArgs.contains("-a")
let userWantsHelpMessage = CMDLineArgs.contains("--help") || CMDLineArgs.contains("-h")
let shouldSetAutoMount = CMDLineArgs.contains("--set-auto-mount")
let shouldPrintRegEntryID = CMDLineArgs.contains("--get-reg-entry-id") || CMDLineArgs.contains("-g")

func printHelp() {
    print("""
          AttachDetachSW --- A Swift recreation of attach-detach.
          
          General Options:
          -a, --attach [DMGFILE]            Specify a DMG file to attach
          -d, --detach [DISKNAME]           Specify a disk name to detach
          
          Attach Options:
          --file-mode=FILEMODE              Specify the filemode to attach the specified DMG with
          --set-auto-mount                  Sets the automount to true while attaching specified DMG
          -g, --get-reg-entry-id            Prints the RegEntryID after attaching DMG
          
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
    let arrOfSpecifiedDMGs = CMDLineArgs.filter() { NSString(string: $0).pathExtension == "dmg" }
    var handler: DIDeviceHandle?
    for dmg in arrOfSpecifiedDMGs {
        guard FileManager.default.fileExists(atPath: dmg) else {
            fatalError("File \"\(dmg)\" doesn't exist, there it can't be used.")
        }
        let DMGURL = URL(fileURLWithPath: dmg)
        var err:NSError?
        let attachParams = DIAttachParams(url: DMGURL, error: err)
        guard err == nil else {
            let errToShow = err?.localizedFailureReason ?? err?.localizedDescription
            fatalError("Error encountered with DIAttachParams: \(errToShow ?? "Unknown Error")")
        }
        attachParams?.autoMount = shouldSetAutoMount
        let fileModeArr = CMDLineArgs.filter() { $0.hasPrefix("--file-mode=") }
        if !fileModeArr.isEmpty {
            let fileModeSpecified = fileModeArr[0].replacingOccurrences(of: "--file-mode=", with: "")
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
        if shouldPrintRegEntryID {
            if let regEntryID = handler?.regEntryID() {
                print("regEntryID: \(regEntryID)")
            } else {
                print("Wasn't able to obtain regEntryID.")
            }
        }
    }
}
