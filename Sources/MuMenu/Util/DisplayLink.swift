import UIKit
import QuartzCore
import Tr3

public protocol DisplayLinkDelegate {
    func nextFrame() -> Bool
}

public class DisplayLink: NSObject {

    public static let shared = DisplayLink()
    static var goAppBlock = false
    static var goAppCount = 0

    var link: CADisplayLink?
   
    var fps = 60

    public var delegates = [Int: DisplayLinkDelegate]()

    public override init() {
        
        super.init()
        
        link = UIScreen.main.displayLink(withTarget: self, selector: #selector(drawFrame))
        link?.preferredFramesPerSecond = fps
        link?.add(to: RunLoop.current, forMode: .default)
        //tr3Osc = Tr3Osc(sky)
    }

    public func updateFps(_ newFps: Int?) {
        if let newFps,
            fps != newFps {
            fps = newFps
            link?.preferredFramesPerSecond = fps
        }
    }

    @objc func drawFrame() -> Bool  {

        for (key,delegate) in delegates {
            if delegate.nextFrame() == false {
                delegates.removeValue(forKey: key)
            }
        }
        goApp()
        return true
    }

    func goApp() {

        if  DisplayLink.goAppBlock == false {
            DisplayLink.goAppBlock = true

            // tr3Osc?.oscReceiverLoop()
            DisplayLink.goAppCount += 1
            DisplayLink.goAppBlock = false
            
        }
    }
}
