//
//  StellarColors.swift
//  RKBalls
//
//  Created by Eric Freitas on 4/24/25.
//

import Foundation
import AppKit

func spectralClassToColor(spectralClass: SpectralClass, subClass: Int) -> NSColor {
    var colorVal = NSColor.green // the error color
    
    let sClass = "\(spectralClass)\(subClass)"
    
    if let hexColor = ColorBySpectral.filter({ $0.key == sClass }).first {
        colorVal = NSColor(hex: hexColor.value)
    }
    return colorVal
}

func randomColor() -> NSColor {
    return NSColor(red: CGFloat.random(in: 0...1, using: &OnyxRandomGen.randGen),
                   green: CGFloat.random(in: 0...1, using: &OnyxRandomGen.randGen),
                   blue: CGFloat.random(in: 0...1, using: &OnyxRandomGen.randGen),
                   alpha: 1.0)
}


