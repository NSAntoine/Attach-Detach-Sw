import Foundation

let CMDLineArgs = Array(CommandLine.arguments.dropFirst())

let doDetach = CMDLineArgs.contains("--detach") || CMDLineArgs.contains("-d")
let doAttach = CMDLineArgs.contains("--attach") || CMDLineArgs.contains("-a")

if doDetach {
    let arrOfDiskPathsSpecified = CMDLineArgs.filter() { $0.contains("disk") }
    for DiskName in arrOfDiskPathsSpecified {
        var diskNameToUse = DiskName
        diskNameToUse.hasPrefix("/dev/") ? nil : diskNameToUse.insert(contentsOf: "/dev/", at: diskNameToUse.startIndex)
        
        let fd = open(diskNameToUse, O_RDONLY)
        guard fd != -1 else {
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
            fatalError("Error encountered while ejecting \(diskNameToUse): \(String(cString: strerror(errno)))")
        }
    }
}
