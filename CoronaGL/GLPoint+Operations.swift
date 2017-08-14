//
//  GLPoint+Operations.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/28/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaConvenience
#if os(iOS)
    import UIKit
    import OpenGLES
#else
    import OpenGL
#endif

public func +(lhs:GLPoint, rhs:GLPoint) -> GLPoint {
    return GLPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func -(lhs:GLPoint, rhs:GLPoint) -> GLPoint {
    return GLPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public func *(lhs:GLPoint, rhs:GLPoint) -> GLPoint {
    return GLPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
}

public func /(lhs:GLPoint, rhs:GLPoint) -> GLPoint {
    return GLPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
}

public func +=(lhs: inout GLPoint, rhs:GLPoint) {
    lhs = lhs + rhs
}

public func -=(lhs: inout GLPoint, rhs:GLPoint) {
    lhs = lhs - rhs
}

public func *=(lhs: inout GLPoint, rhs:GLPoint) {
    lhs = lhs * rhs
}

public func /=(lhs: inout GLPoint, rhs:GLPoint) {
    lhs = lhs / rhs
}

public func +(lhs:GLPoint, rhs:CGFloat) -> GLPoint {
    return GLPoint(x: lhs.x + GLfloat(rhs), y: lhs.y + GLfloat(rhs))
}

public func -(lhs:GLPoint, rhs:CGFloat) -> GLPoint {
    return GLPoint(x: lhs.x - GLfloat(rhs), y: lhs.y - GLfloat(rhs))
}

public func *(lhs:GLPoint, rhs:CGFloat) -> GLPoint {
    return GLPoint(x: lhs.x * GLfloat(rhs), y: lhs.y * GLfloat(rhs))
}

public func /(lhs:GLPoint, rhs:CGFloat) -> GLPoint {
    return GLPoint(x: lhs.x / GLfloat(rhs), y: lhs.y / GLfloat(rhs))
}

public func +(lhs:CGFloat, rhs:GLPoint) -> GLPoint {
    return GLPoint(x: GLfloat(lhs) + rhs.x, y: GLfloat(lhs) + rhs.y)
}

public func -(lhs:CGFloat, rhs:GLPoint) -> GLPoint {
    return GLPoint(x: GLfloat(lhs) - rhs.x, y: GLfloat(lhs) - rhs.y)
}

public func *(lhs:CGFloat, rhs:GLPoint) -> GLPoint {
    return GLPoint(x: GLfloat(lhs) * rhs.x, y: GLfloat(lhs) * rhs.y)
}

public func /(lhs:CGFloat, rhs:GLPoint) -> GLPoint {
    return GLPoint(x: GLfloat(lhs) / rhs.x, y: GLfloat(lhs) / rhs.y)
}

public func +=(lhs: inout GLPoint, rhs:CGFloat) {
    lhs = lhs + rhs
}

public func -=(lhs: inout GLPoint, rhs:CGFloat) {
    lhs = lhs - rhs
}

public func *=(lhs: inout GLPoint, rhs:CGFloat) {
    lhs = lhs * rhs
}

public func /=(lhs: inout GLPoint, rhs:CGFloat) {
    lhs = lhs / rhs
}

public func +(lhs:GLPoint, rhs:CGPoint) -> GLPoint {
    return lhs + GLPoint(point: rhs)
}

public func -(lhs:GLPoint, rhs:CGPoint) -> GLPoint {
    return lhs - GLPoint(point: rhs)
}

public func *(lhs:GLPoint, rhs:CGPoint) -> GLPoint {
    return lhs * GLPoint(point: rhs)
}

public func /(lhs:GLPoint, rhs:CGPoint) -> GLPoint {
    return lhs / GLPoint(point: rhs)
}

public func +(lhs:CGPoint, rhs:GLPoint) -> GLPoint {
    return GLPoint(point: lhs) + rhs
}

public func -(lhs:CGPoint, rhs:GLPoint) -> GLPoint {
    return GLPoint(point: lhs) - rhs
}

public func *(lhs:CGPoint, rhs:GLPoint) -> GLPoint {
    return GLPoint(point: lhs) * rhs
}

public func /(lhs:CGPoint, rhs:GLPoint) -> GLPoint {
    return GLPoint(point: lhs) / rhs
}

public func +=(lhs: inout GLPoint, rhs:CGPoint) {
    lhs = lhs + rhs
}

public func -=(lhs: inout GLPoint, rhs:CGPoint) {
    lhs = lhs - rhs
}

public func *=(lhs: inout GLPoint, rhs:CGPoint) {
    lhs = lhs * rhs
}

public func /=(lhs: inout GLPoint, rhs:CGPoint) {
    lhs = lhs / rhs
}

public func +=(lhs: inout CGPoint, rhs:GLPoint) {
    lhs += rhs.getCGPoint()
}

public func -=(lhs: inout CGPoint, rhs:GLPoint) {
    lhs -= rhs.getCGPoint()
}

public func *=(lhs: inout CGPoint, rhs:GLPoint) {
    lhs *= rhs.getCGPoint()
}

public func /=(lhs: inout CGPoint, rhs:GLPoint) {
    lhs /= rhs.getCGPoint()
}




