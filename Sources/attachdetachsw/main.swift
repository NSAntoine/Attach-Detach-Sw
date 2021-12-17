import Foundation

/// Array of command line arguments given by the user
let CMDLineArgs = Array(CommandLine.arguments.dropFirst())

/// DMGs specified by the user to attach
let DMGSInputted = CMDLineArgs.map {
    // Resolve the symlinks first
    resolveSymlinks(ofPath: $0)
}.filter {
    // Then filter by DMG files that exist only
    NSString(string: $0).pathExtension == "dmg" && fm.fileExists(atPath: $0)
}

/// The `disk` or `/dev/disk` directories inputted by the user
let DevDiskPathsInputted = CMDLineArgs.filter {
    $0.contains("disk") && NSString(string: $0).pathExtension != "dmg"
}

let shouldDetach = CMDLineArgs.contains("--detach") || CMDLineArgs.contains("-d")
let shouldAttach = CMDLineArgs.contains("--attach") || CMDLineArgs.contains("-a")
let shouldPrintImageURL = CMDLineArgs.contains("--image-url") || CMDLineArgs.contains("-i")

let shouldPrintAllAttachedDirs = CMDLineArgs.contains("--all-dirs") || CMDLineArgs.contains("-o")
let shouldPrintRegEntryID = CMDLineArgs.contains("--reg-entry-id") || CMDLineArgs.contains("-r")

if CMDLineArgs.isEmpty {
    print(helpMessage)
    exit(0)
}

// Support for --image-url / -i
if shouldPrintImageURL {
    var optToParse: String {
        // if the user used the long option, return the long opt, otherwise
        // otherwise return the shortopt
        return CMDLineArgs.contains("--image-url") ? "--image-url" : "-i"
    }
    guard let index = CMDLineArgs.firstIndex(of: optToParse), CMDLineArgs.indices.contains(index + 1) else {
        print("User used \(optToParse) but did not specify a image URL.")
        exit(EXIT_FAILURE)
    }
    var disk = CMDLineArgs[index + 1]
    if !disk.hasPrefix("/dev/") {
        disk.insert(contentsOf: "/dev/", at: disk.startIndex)
    }
    getImageURLOfDisk(atPath: disk) { url, error in
        guard let url = url, error == nil else {
            print("Error encountered while getting original image URL of \(disk): \(error?.localizedDescription ?? "Unknown Error")")
            exit(EXIT_FAILURE)
        }
        print("Original Image URL of \(disk): \(url.path)")
    }
}

if shouldDetach {
    guard !DevDiskPathsInputted.isEmpty else {
        fatalError("User used --detach / -d however did not specify a disk to detach.")
    }
    
    for var diskName in DevDiskPathsInputted {
        detachDisk(diskName: &diskName)
    }
}

if shouldAttach {
    guard !DMGSInputted.isEmpty else {
        fatalError("User used --attach / -a however did not specify a DMG to attach.")
    }
    
    for DMG in DMGSInputted {
        AttachDMG(atPath: DMG) { Handler, error in
            // Make sure we encountered no issues
            guard let Handler = Handler, let BSDName = Handler.bsdName, error == nil else {
                print("Error encountered while attaching DMG \(DMG): \(error?.localizedDescription ?? "Unknown Error")")
                exit(EXIT_FAILURE)
            }
            
            print("Attached \(DMG) as \(BSDName)")
            
            // If the user specified to print all the directories that the DMG was attached to
            // Print them
            if shouldPrintAllAttachedDirs {
                let attachedDirsThatExist = ["/dev/\(BSDName)", "/dev/\(BSDName)s1", "/dev/\(BSDName)s1s1"].filter {
                    fm.fileExists(atPath: $0)
                }
                print(attachedDirsThatExist.joined(separator: ", "))
            }
            
            if shouldPrintRegEntryID {
                print("\(BSDName) RegEntryID: \(Handler.regEntryID)")
            }
        }
    }
}
