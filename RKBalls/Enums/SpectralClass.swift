//
//  SpectralClass.swift
//  RKBalls
//
//  Created by Eric Freitas on 4/24/25.
//

import Foundation

enum SpectralClass: Int, Codable, Equatable, CaseIterable {
    case D = 3
    case M = 4
    case K = 5
    case G = 6
    case F = 7
    case A = 8
    case B = 9
    case O = 10
    
    func spectralToString() -> String {
        if self.rawValue == 3 { return "D" }
        if self.rawValue == 4 { return "M" }
        if self.rawValue == 5 { return "K" }
        if self.rawValue == 6 { return "G" }
        if self.rawValue == 7 { return "F" }
        if self.rawValue == 8 { return "A" }
        if self.rawValue == 9 { return "B" }
        if self.rawValue == 10 { return "O" }
        
        return "D"
    }
}


