// created by musesum on 3/27/24

import simd

public class ValTween: Codable  {

    var val: SIMD3<Double> = .zero
    var twe: SIMD3<Double> = .zero

    init (_ val: SIMD3<Double>,
          _ twe: SIMD3<Double>) {

        self.val = val
        self.twe = twe
    }

    enum CodingKeys: String, CodingKey { case val, twe }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try val = container.decode(SIMD3<Double>.self, forKey: .val )
        try twe = container.decode(SIMD3<Double>.self, forKey: .twe )
    }
}
