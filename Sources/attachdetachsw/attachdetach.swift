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

func detachDisk(diskName: inout String) {
    if !diskName.hasPrefix("/dev/") {
        diskName.insert(contentsOf: "/dev/", at: diskName.startIndex)
    }
    
    let fd = open(diskName, O_RDONLY)
    // Just to be safe, close it once done
    defer { close(fd) }
    // Make sure no issues were encountered with opening the disk
    guard fd != -1 else {
        let errorEncountered = String(cString: strerror(errno))
        fatalError("Error encountered with opening \(diskName): \(errorEncountered)")
    }
    
    let ejectIOCTLNumber = getIoctlNumber(group: "d", number: 21)
    
    let ret = ioctl(fd, ejectIOCTLNumber)
    guard ret != -1 else {
        let errorEncountered = String(cString: strerror(errno))
        fatalError("Error encountered with ejecting \(diskName): \(errorEncountered)")
    }
    print("Detached \(diskName)")
}

func AttachDMG(atPath path: String, completionHandler: (DIDeviceHandle?, Error?) -> Void) {
    var AttachParamsErr: NSError?
    let AttachParams = DIAttachParams(url: URL(fileURLWithPath: path), error: AttachParamsErr)
    if let AttachParamsErr = AttachParamsErr {
        return completionHandler(nil, AttachParamsErr)
    }
    
    // Set the filemode
    // if the user didn't specify it by the command line, it'll be 0
    AttachParams?.fileMode = returnFileModeFromCMDLine()
    
    AttachParams?.autoMount = CMDLineArgs.contains("-s") || CMDLineArgs.contains("--set-auto-mount")
    
    var handle: DIDeviceHandle?
    
    var AttachErr: NSError?
    let didSuccessfullyAttach = DiskImages2.attach(with: AttachParams, handle: &handle, error: &AttachErr)
    if let AttachErr = AttachErr {
        return completionHandler(nil, AttachErr)
    }
    
    return completionHandler(handle, nil)
}

/// Returns the Attach filemode specified by the user using the `--file-mode=/-f=` options
func returnFileModeFromCMDLine() -> Int64 {
    /// The array who's first element (may) be the specified filemode
    let fileModeArray = CMDLineArgs.filter {
        // First lets filter the array by the element that contains --file-mode= or -f= in it
        $0.hasPrefix("--file-mode=") || $0.hasPrefix("-f=")
    }.map {
        // And now lets remove --file-mode=/-f= from the string
        $0.replacingOccurrences(of: "--file-mode=", with: "")
            .replacingOccurrences(of: "-f=", with: "")
    }.compactMap {
        // And now lets allow only Int64 in the array
        Int64($0)
    }
    
    if fileModeArray.isEmpty {
        return 0
    }
    return fileModeArray[0]
}

func getImageURLOfDisk(atPath path: String, completionHandler: (URL?, Error?) -> Void) {
    var ImageURLError: NSError?
    let url = URL(fileURLWithPath: path)
    do {
        let ImageURL = try DiskImages2.imageURL(
            fromDevice: url
        )
        return completionHandler(ImageURL as? URL, nil)
    } catch {
        return completionHandler(nil, error)
    }
}

let helpMessage = """
AttachDetachSW --- By Serena-io
A CommandLine Tool to attach and detach DMGs on iOS
Usage: attachdetachsw [--attach/-a | --detach/-d] [FILE], where FILE is a Disk Name to detach or a DMG to attach
Options:

    General Options:
        -a, --attach [DMGFILE]                  Attach the DMGFile specified
        -d, --detach [DISKNAME]                 Detach the Disk Name specified
        -i, --image-url [DISKNAME]              Prints the original image url of the specified Disk Name

    Attach Options:
        -f, --file-mode=FILE-MODE               Specify a FileMode to attach the DMG with, specified FileMode must be a number
        -s, --set-auto-mount                    Sets Auto-Mount to true while attaching
        -r, --reg-entry-id                      Prints the RegEntryID of the disk that the DMG was attached to
        -o, --all-dirs                          Prints all the directories to which the DMG was attached to
Example usage:
    attachdetachsw --attach randomDMG.dmg
    attachdetachsw --detach disk8
"""
