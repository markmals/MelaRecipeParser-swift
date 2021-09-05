import Foundation

extension FileManager {
    func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    func pathExtension(_ filePath: String) -> String {
        return NSString(string: filePath).pathExtension
    }
}
