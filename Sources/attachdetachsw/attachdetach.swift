import Foundation
import DI2Support

let fm = FileManager.default

func resolveSymlinks(ofPath path: String) -> String {
    let resolvedPath = try? fm.destinationOfSymbolicLink(atPath: path)
    // Return the resolved path if we can get ti
    // otherwise return the original path
    return resolvedPath ?? path
}

func getIoctlNumber(group: Character, number n:UInt) -> UInt {
    let void = UInt(IOC_VOID)
    let g: UInt = UInt(group.asciiValue!) << 8
    
    return void | g | n
}

func detachDisk(diskPath path: String, completionHandler: (_ didDetach: Bool, _ errorEncountered: String?) -> Void) {
    let fd = open(path, O_RDONLY)
    guard fd != -1 else {
        // Convert C-String strerror to swift
        let errorEncountered = String(cString: strerror(errno))
        return completionHandler(false, errorEncountered)
    }
    
    let ioctlEjectCode = getIoctlNumber(group: "d", number: 21)
    
    let ret = ioctl(fd, ioctlEjectCode)
    guard ret != -1 else {
        let errorEncountered = String(cString: strerror(errno))
        return completionHandler(false, errorEncountered)
    }
    
    return completionHandler(true, nil)
}

func AttachDMG(atPath path: String, doAutoMount: Bool = true, fileMode: Int64 = 0, completionHandler: (DIDeviceHandle?, Error?) -> Void) {
    
    do {
        let AttachParams = try DIAttachParams(url: URL(fileURLWithPath: path))

        // Set the filemode
        AttachParams.fileMode = fileMode
        
        // Set whether or not to auto mount the DMG
        AttachParams.autoMount = doAutoMount
        
        var Handler: DIDeviceHandle?
        
        try DiskImages2.attach(with: AttachParams, handle: &Handler)
        return completionHandler(Handler, nil)
    } catch {
        return completionHandler(nil, error)
    }
    
}

/// Returns the Attach filemode specified by the user using the `--file-mode=/-f=` options
func returnFileModeFromCMDLine() -> Int64 {
    /// The array who's first element (may) be the specified filemode
    let fileModeArray = CMDLineArgs.filter {
        $0.starts(with: "--file-mode=") || $0.starts(with: "-f=")
    }.flatMap {
        // Seperate the strings by the =
        $0.components(separatedBy: "=")
    }.compactMap {
        // Now only allow the number
        Int64($0)
    }
    
    return fileModeArray.isEmpty ? 0 : fileModeArray[0]
}

/// Returns the original image URL
/// that a disk was attached with
func getImageURLOfDisk(atPath path: String) throws -> URL? {
    let url = URL(fileURLWithPath: path)
    let ImageURL = try DiskImages2.imageURL(
        fromDevice: url
    )
    return ImageURL as? URL
}

let helpMessage = """
AttachDetachSW --- By Serena-io
A CommandLine Tool to attach and detach DMGs on iOS
Usage: attachdetachsw [--attach/-a | --detach/-d] [FILE], where FILE is a Disk Name to detach or a DMG to attach
Options:

    General Options:
        -a, --attach    [DMGFILE]                  Attach the specified DMG File
        -d, --detach    [DISKNAME]                 Detach the specified Disk name
        -i, --image-url [DISKNAME]                 Print the original image url that the specified disk name was attached with

    Attach Options:
        -f, --file-mode=FILE-MODE                  Specify a FileMode to attach the DMG with, specified FileMode must be a number
        -m, --auto-mount                           Sets Auto-Mount to true while attaching
        -r, --reg-entry-id                         Prints the RegEntryID of the disk that the DMG was attached to
        -o, --all-dirs                             Prints all the directories to which the DMG was attached to

Example usage:
    attachdetachsw --attach randomDMG.dmg
    attachdetachsw --detach disk8
"""
