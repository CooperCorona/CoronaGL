//
//  SmoothingFunctions.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 6/18/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures

public func smoothstep(x:Float) -> Float {
    return x * x * (3.0 - 2.0 * x)
}

public func smoothstep(x:Double) -> Double {
    return x * x * (3.0 - 2.0 * x)
}

public func smoothstep(x:CGFloat) -> CGFloat {
    return x * x * (3.0 - 2.0 * x)
}

public func smoothstep(p:CGPoint) -> CGPoint {
    let x = smoothstep(p.x)
    let y = smoothstep(p.y)
    return CGPoint(x: x, y: y)
}

public func smoothstep(v:SCVector3) -> SCVector3 {
    let x = smoothstep(v.x)
    let y = smoothstep(v.y)
    let z = smoothstep(v.z)
    return SCVector3(x: x, y: y, z: z)
}

public func smoothstep(v:SCVector4) -> SCVector4 {
    let x = smoothstep(v.x)
    let y = smoothstep(v.y)
    let z = smoothstep(v.z)
    let w = smoothstep(v.w)
    return SCVector4(x: x, y: y, z: z, w: w)
}

// MARK: - Perlin Noise Smoothstep
//According to http://flafla2.github.io/2014/08/09/perlinnoise.html
//the equation is 6t^5 - 15t^4 + 10t^3

public func perlinStep(t:Float) -> Float {
    let t_3 = t * t * t
    return 6.0 * t_3 * t * t - 15.0 * t_3 * t + 10.0 * t_3
}

public func perlinStep(t:Double) -> Double {
    let t_3 = t * t * t
    return 6.0 * t_3 * t * t - 15.0 * t_3 * t + 10.0 * t_3
}

public func perlinStep(t:CGFloat) -> CGFloat {
    let t_3 = t * t * t
    return 6.0 * t_3 * t * t - 15.0 * t_3 * t + 10.0 * t_3
}

public func perlinStep(p:CGPoint) -> CGPoint {
    let x = perlinStep(p.x)
    let y = perlinStep(p.y)
    return CGPoint(x: x, y: y)
}

public func perlinStep(v:SCVector3) -> SCVector3 {
    let x = perlinStep(v.x)
    let y = perlinStep(v.y)
    let z = perlinStep(v.z)
    return SCVector3(x: x, y: y, z: z)
}

public func perlinStep(v:SCVector4) -> SCVector4 {
    let x = perlinStep(v.x)
    let y = perlinStep(v.y)
    let z = perlinStep(v.z)
    let w = perlinStep(v.w)
    return SCVector4(x: x, y: y, z: z, w: w)
}

