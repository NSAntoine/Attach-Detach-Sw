// Contains functions for attaching and detaching

import Foundation
import DI2Support

func detachDisk(DiskName: inout String) {
    
    // If the disk name specified dosesn't start with "/dev/", insert "/dev/" to it at the beginning
    if !DiskName.hasPrefix("/dev/") {
        DiskName.insert(contentsOf: "/dev/", at: DiskName.startIndex)
    }
    
    let fd = open(DiskName, O_RDONLY)
    defer { close(fd) }
    guard fd != -1 else {
        let errorEncountered = String(cString: strerror(errno)) // Convert CString strerror to a swift string
        fatalError("Error encountered while opening \(DiskName): \(errorEncountered)")
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
        let errorEncountered = String(cString: strerror(errno)) // Convert CString strerror to a swift string
        fatalError("Error encountered while ejecting \(DiskName): \(errorEncountered)")
    }
    print("Detached \(DiskName)")
}

func attachDMG(DMGFile dmg:String) {
    let DMGURL = URL(fileURLWithPath: dmg)
    var attachParamsErr:NSError?
    let attachParams = DIAttachParams(url: DMGURL, error: attachParamsErr)
    
    attachParams?.autoMount = CMDLineArgs.contains("--set-auto-mount") || CMDLineArgs.contains("-s")
    
    // Check if the user used --file-mode or -f correctly
    let fileModeSpecified = CMDLineArgs.filter {
        $0.hasPrefix("--file-mode=") || $0.hasPrefix("-f=")
    }.map {
        // Remove --file-mode=/-f= so we just have the number
        $0.replacingOccurrences(of: "--file-mode=", with: "").replacingOccurrences(of: "-f=", with: "")
    }.compactMap {
        Int64($0)
    }
    
    
    // If the user did indeed specify a value with --file-mode/-f
    // set the fileMode to the specified value
    // otherwise keep it as the default.
    if !fileModeSpecified.isEmpty {
        attachParams?.fileMode = fileModeSpecified[0]
    }
    print("Proceeding to attach DMG \(dmg) with filemode \(attachParams?.fileMode ?? 1)")
    
    // check if there were any issues encountered with attach parameters
    if let attachParamsErr = attachParamsErr {
        fatalError("Error encountered while setting Attach Parameters: \(attachParamsErr.localizedDescription)")
    }
    
    // Handler which will have the info of the attached DMG
    var handler:DIDeviceHandle?
    
    // If an error occurs while attaching, it'll be set to the following variable
    var attachErr:NSError?
    
    // Call attach function
    let didSuccessfullyAttach = DiskImages2.attach(with: attachParams, handle: &handler, error: &attachErr)
    
    // Make sure didSuccessfullyAttach returns true
    guard didSuccessfullyAttach else {
        // Print the error if we can
        if let attachErr = attachErr {
            print("Error encountered with attaching DMG: \(attachErr.localizedDescription)")
        }
        fatalError("Couldn't successfully attach DMG \(dmg).")
    }
    // Get information from handler and make sure the program can get the name of the disk that the DMG was attachedq to
    guard let handler = handler, let BSDName = handler.bsdName else {
        fatalError("Attached DMG However couldn't get info from handler..")
    }
    
    print("Attached as \(BSDName)")
    
    if shouldPrintRegEntryID {
        print("\(BSDName) regEntryID: \(handler.regEntryID)")
    }
    
    // Make an array of the devDisk Dirs that should exist, and filter by the ones that actually do
    let devDiskDirsThatDoExist = ["/dev/\(BSDName)", "/dev/\(BSDName)s1", "/dev/\(BSDName)s1s1"].filter() { FileManager.default.fileExists(atPath: $0) }
    
    if shouldPrintAllDiskDirs {
        print("All dev disk directories DMG Was attached to: \(devDiskDirsThatDoExist.joined(separator: ", "))")
    }
}

func resolveSymlink(ofPath path:String) -> String {
    let ResolvedPath = try? FileManager.default.destinationOfSymbolicLink(atPath: path)
    // Return the resolved path if we were able to get it, otherwise return the normal path
    return ResolvedPath ?? path
}

