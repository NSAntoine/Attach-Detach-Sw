import Foundation
import DI2Support

let CMDLineArgs = Array(CommandLine.arguments.dropFirst())

let arrOfSpecifiedDMGs = CMDLineArgs.filter() { NSString(string: $0).pathExtension == "dmg" && FileManager.default.fileExists(atPath: $0) }
// Detect if the user used --attach/-a or if the user specified a DMG without --attach/-a
let doAttach = (CMDLineArgs.contains("--attach") || CMDLineArgs.contains("-a")) || !arrOfSpecifiedDMGs.isEmpty

let arrOfDiskPathsSpecified = CMDLineArgs.filter() { $0.contains("disk") && NSString(string: $0).pathExtension != "dmg" }
// Detect if the user used --detach/-d or if the user specified a disk without --detach/-d
let doDetach = (CMDLineArgs.contains("--detach") || CMDLineArgs.contains("-d")) || !arrOfDiskPathsSpecified.isEmpty

let userWantsHelpMessage = CMDLineArgs.contains("--help") || CMDLineArgs.contains("-h")
let shouldPrintRegEntryID = CMDLineArgs.contains("--reg-entry-id") || CMDLineArgs.contains("-r")
let shouldPrintAllDiskDirs = CMDLineArgs.contains("--all-dirs") || CMDLineArgs.contains("-o")
// Short option for --detach: -d
// Short option for --dont-verify: -D
let shouldntVerify = CMDLineArgs.contains("--dont-verify") || CMDLineArgs.contains("-D")

func printHelp() {
    print("""
          AttachDetachSW --- A Swift recreation of attach-detach.
          
          General Options:
            -a, --attach [DMGFILE]            Specify a DMG file to attach
            -d, --detach [DISKNAME]           Specify a disk name to detach
          
          Attach Options:
            -o, --all-dirs                    Prints all the /dev/disk directories that the DMG was attached to
            -f, --file-mode=FILEMODE-NUMBER   Specify the filemode to attach the specified DMG with
            -s, --set-auto-mount              Sets the automount to true while attaching specified DMG
            -D, --dont-verify                 Don't verify that the DMG was attached successfully
            -r, --reg-entry-id                Prints the RegEntryID of the disk the DMG was attached to
          
          Notes:
            If the user does not specify --attach/-a or --detach/-d, then it will attach any DMGs given or detach any given disk, which means using --attach/-a or --detach/-d is not needed most of the time. See example usage
          
          Example usage:
            attachdetachsw --attach randomDMG.dmg
            attachdetachsw --detach disk7
            attachdetachsw someDMG.dmg --verify
            attachdetachsw disk8
          """)
}
if CMDLineArgs.isEmpty || userWantsHelpMessage || (!doDetach && !doAttach) {
    printHelp()
}

if doDetach {
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
    guard !arrOfSpecifiedDMGs.isEmpty else {
        fatalError("User used --attach / -a however either didn't specify a DMG file or specified a DMG file that doesn't exist. See attachdetachsw --help for more information.")
    }
    
    for dmg in arrOfSpecifiedDMGs {
        let DMGURL = URL(fileURLWithPath: dmg)
        var attachParamsErr:NSError?
        let attachParams = DIAttachParams(url: DMGURL, error: attachParamsErr)
        
        attachParams?.autoMount = CMDLineArgs.contains("--set-auto-mount") || CMDLineArgs.contains("-s")
        
        // Check if the user used --file-mode or -f correctly
        let fileModeArr = CMDLineArgs.filter() { $0.hasPrefix("--file-mode=") || $0.hasPrefix("-f=") }.map() { $0.replacingOccurrences(of: "--file-mode=", with: "").replacingOccurrences(of: "-f=", with: "")}
        let fileModeArrIntOnly = fileModeArr.compactMap() { Int64($0) }
        if !fileModeArrIntOnly.isEmpty {
            let fileModeToSet = fileModeArrIntOnly[0]
            print("Setting filmode to \(fileModeToSet)")
            attachParams?.fileMode = fileModeToSet
        }
        
        // We should check for attachParams error only after we actually set all the parameters
        guard attachParamsErr == nil else {
            let errToShow = attachParamsErr?.localizedFailureReason ?? attachParamsErr?.localizedDescription
            fatalError("Error encountered with Setting Attach Parameters: \(errToShow ?? "Unknown Error")")
        }
        
        // Handler which will have the info of the attached DMG
        var handler:DIDeviceHandle?
        
        // If an error occurs while attaching, it'll be set to the following variable
        var attachErr:NSError?
        // Call attach function
        DiskImages2.attach(with: attachParams, handle: &handler, error: &attachErr)
        
        // Make sure no errors were encountered
        guard attachErr == nil else {
            let errToShow = attachErr?.localizedFailureReason ?? attachErr?.localizedDescription
            fatalError("Error encountered while attaching DMG \"\(dmg)\": \(errToShow ?? "Unknown Error")")
        }
        // Get information from handler and make sure the program can get the name of the disk that the DMG was attached to
        guard let handler = handler, let BSDName = handler.bsdName else {
            fatalError("Attached DMG However couldn't get info from handler..")
        }
        
        if shouldntVerify {
            print("Not verifying with DIVerifyParams becuase the user specified not to.")
        } else {
            var verifyErr:NSError?
            let DIVerify = DIVerifyParams(url: URL(fileURLWithPath: "/dev/\(BSDName)"), error: verifyErr)
            guard let wasSuccessfullyAttached = DIVerify?.verifyWithError(verifyErr), wasSuccessfullyAttached else {
                let errorEncountered = verifyErr?.localizedFailureReason ?? verifyErr?.localizedDescription
                fatalError("Couldn't verify that DMG \"\(dmg)\" was succssfully attached, Error encountered: \(errorEncountered ?? "Unknown Error")")
            }
            print("Verified that DMG Was successfully attached.")
        }
        
        print("Attached as \(BSDName)")
        
        if shouldPrintRegEntryID {
            print("regEntryID: \(handler.regEntryID)")
        }
        
        // Make an array of the devDisk Dirs that should exist, and filter by the ones that actually do
        let devDiskDirsThatDoExist = ["/dev/\(BSDName)", "/dev/\(BSDName)s1", "/dev/\(BSDName)s1s1"].filter() { FileManager.default.fileExists(atPath: $0) }
        
        if shouldPrintAllDiskDirs {
            print("All dev disk directories DMG Was attached to: \(devDiskDirsThatDoExist.joined(separator: ", "))")
        }
    }
}
