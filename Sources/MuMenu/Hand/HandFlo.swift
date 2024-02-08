// created by musesum on 1/22/24
#if os(visionOS)
import MuFlo
import ARKit
import MuVision // logger, script

public class HandFlo {
    /// each `Flo` joint has an `xyz` and `on`  value

    var time = TimeInterval.zero

    private var thumbKnuc  = FloXyzOn()
    private var thumbBase  = FloXyzOn()
    private var thumbNter  = FloXyzOn()
    private var thumbTip   = FloXyzOn()
    private var indexMeta  = FloXyzOn()
    private var indexKnuc  = FloXyzOn()
    private var indexBase  = FloXyzOn()
    private var indexNter  = FloXyzOn()
    private var indexTip   = FloXyzOn()
    private var middleMeta = FloXyzOn()
    private var middleKnuc = FloXyzOn()
    private var middleBase = FloXyzOn()
    private var middleNter = FloXyzOn()
    private var middleTip  = FloXyzOn()
    private var ringMeta   = FloXyzOn()
    private var ringKnuc   = FloXyzOn()
    private var ringBase   = FloXyzOn()
    private var ringNter   = FloXyzOn()
    private var ringTip    = FloXyzOn()
    private var littleMeta = FloXyzOn()
    private var littleKnuc = FloXyzOn()
    private var littleBase = FloXyzOn()
    private var littleNter = FloXyzOn()
    private var littleTip  = FloXyzOn()

    var joints = [HandJoints: FloXyzOn]()

    init() {

        joints = [

            .thumbKnuc  : thumbKnuc  ,
            .thumbBase  : thumbBase  ,
            .thumbNter  : thumbNter  ,
            .thumbTip   : thumbTip   ,
            .indexMeta  : indexMeta  ,
            .indexKnuc  : indexKnuc  ,
            .indexBase  : indexBase  ,
            .indexNter  : indexNter  ,
            .indexTip   : indexTip   ,
            .middleMeta : middleMeta ,
            .middleKnuc : middleKnuc ,
            .middleBase : middleBase ,
            .middleNter : middleNter ,
            .middleTip  : middleTip  ,
            .ringMeta   : ringMeta   ,
            .ringKnuc   : ringKnuc   ,
            .ringBase   : ringBase   ,
            .ringNter   : ringNter   ,
            .ringTip    : ringTip    ,
            .littleMeta : littleMeta ,
            .littleKnuc : littleKnuc ,
            .littleBase : littleBase ,
            .littleNter : littleNter ,
            .littleTip  : littleTip  ,
        ]
    }
    public func parseHand(_ flo: Flo) {
        for (floJoint, floPos) in joints {
            floPos.parse(flo, floJoint)
        }
    }

    public func setJoints(_ handJoints: [HandJoints], on: Bool) {
        for handJoint in handJoints {
            if let xyzOn = joints[handJoint] {
                xyzOn.on = on
            }
        }
    }

    func updateAnchor(_ anchor: HandAnchor) {

        guard let skeleton = anchor.handSkeleton else { return err("skeleton") }

        let transform = anchor.originFromAnchorTransform

        var newUpdate = false

        for (handJoint, xyzOn) in joints {
            if xyzOn.on,
               let arName = handJoint.arJoint {

                let joint = skeleton.joint(arName)
                xyzOn.xyz = matrix_multiply(transform, joint.anchorFromJointTransform).columns.3.xyz
                newUpdate = true
            }
        }
        if newUpdate {
            time = Date().timeIntervalSince1970
        }
        MuLog.NoLog("HandFlo", interval: 1.0) {
            var msg = ""
            for (handJoint, xyzOn) in self.joints {
                if xyzOn.on {
                    msg += handJoint.rawValue + xyzOn.xyz.script + " "
                }
            }
            if !msg.isEmpty {
                print("🖐️" + msg)
            }
        }
        func err(_ msg: String) { print("HandJoints::update err: \(msg)") }
    }

}

#endif
