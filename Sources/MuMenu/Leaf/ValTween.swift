// created by musesum on 3/27/24

import simd

public class ValTween: Codable  {

    var value: SIMD3<Double> = .zero
    var tween: SIMD3<Double> = .zero

    init (_ value: SIMD3<Double>,
          _ tween: SIMD3<Double>) {

        self.value = value
        self.tween = tween
    }

    enum CodingKeys: String, CodingKey { case value, tween }

    required public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try value = c.decode(SIMD3<Double>.self, forKey: .value )
        try tween = c.decode(SIMD3<Double>.self, forKey: .tween )
    }
}
