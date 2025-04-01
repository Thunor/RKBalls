//
//  OnyxRandomGen.swift
//  RKBalls
//
//  Created by Eric Freitas on 3/8/25.
//

import GameKit

struct OnyxRandomGen: RandomNumberGenerator {
    // use this version for release, or a version that allows loading and saving the seed
//    static let randGen = OnyxRandomGen(seed: Int.random(in: Int.min...Int.max))
    static var randGen = OnyxRandomGen(seed: 0)
    
    init(seed: Int) { srand48(seed) }
    func next() -> UInt64 { return UInt64(drand48() * Double(UInt64.max)) }
}
