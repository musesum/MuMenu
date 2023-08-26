//  Created by warren on 4/20/23.

import Foundation
import MuPeer

open class MuMenu {

    public static let bundle = Bundle.module
    
    public static func read(_ filename: String,
                            _ ext: String) -> String? {

        guard let path = Bundle.module.path(forResource: filename, ofType: ext)  else {
            print("⁉️ MuMenu couldn't find file: \(filename).\(ext)")
            return nil
        }
        do {
            return try String(contentsOfFile: path) }
        catch {
            print("⁉️ MuMenuSky:: error:\(error) loading contents of:\(path)")
        }
        return nil
    }
}
