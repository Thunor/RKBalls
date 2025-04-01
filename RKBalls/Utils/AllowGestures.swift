//
//  AllowGestures.swift
//  RKBalls
//
//  Created by Eric Freitas on 3/30/25.
//

import Foundation
@preconcurrency import RealityKit


/// An empty component we can use to tag entities that should support gestures.
public struct AllowGestures: Component, Codable {
    public init() {}
}
