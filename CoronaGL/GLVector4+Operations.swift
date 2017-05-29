//
//  GLVector4+Operations.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/28/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaConvenience
import CoronaStructures
import OpenGL

public func +(lhs:GLVector4, rhs:GLVector4) -> GLVector4 {
    return GLVector4(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z, w: lhs.w + rhs.w)
}

public func -(lhs:GLVector4, rhs:GLVector4) -> GLVector4 {
    return GLVector4(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z, w: lhs.w - rhs.w)
}

public func *(lhs:GLVector4, rhs:GLVector4) -> GLVector4 {
    return GLVector4(x: lhs.x * rhs.x, y: lhs.y * rhs.y, z: lhs.z * rhs.z, w: lhs.w * rhs.w)
}

public func /(lhs:GLVector4, rhs:GLVector4) -> GLVector4 {
    return GLVector4(x: lhs.x / rhs.x, y: lhs.y / rhs.y, z: lhs.z / rhs.z, w: lhs.w / rhs.w)
}

public func +=(lhs:inout GLVector4, rhs:GLVector4) {
    lhs = lhs + rhs
}

public func -=(lhs:inout GLVector4, rhs:GLVector4) {
    lhs = lhs - rhs
}

public func *=(lhs:inout GLVector4, rhs:GLVector4) {
    lhs = lhs * rhs
}

public func /=(lhs:inout GLVector4, rhs:GLVector4) {
    lhs = lhs / rhs
}

public func +(lhs:GLVector4, rhs:CGFloat) -> GLVector4 {
    return GLVector4(x: lhs.x + GLfloat(rhs), y: lhs.y + GLfloat(rhs), z: lhs.z + GLfloat(rhs), w: lhs.w + GLfloat(rhs))
}

public func -(lhs:GLVector4, rhs:CGFloat) -> GLVector4 {
    return GLVector4(x: lhs.x - GLfloat(rhs), y: lhs.y - GLfloat(rhs), z: lhs.z - GLfloat(rhs), w: lhs.w - GLfloat(rhs))
}

public func *(lhs:GLVector4, rhs:CGFloat) -> GLVector4 {
    return GLVector4(x: lhs.x * GLfloat(rhs), y: lhs.y * GLfloat(rhs), z: lhs.z * GLfloat(rhs), w: lhs.w * GLfloat(rhs))
}

public func /(lhs:GLVector4, rhs:CGFloat) -> GLVector4 {
    return GLVector4(x: lhs.x / GLfloat(rhs), y: lhs.y / GLfloat(rhs), z: lhs.z / GLfloat(rhs), w: lhs.w / GLfloat(rhs))
}

public func +(lhs:CGFloat, rhs:GLVector4) -> GLVector4 {
    return GLVector4(x: GLfloat(lhs) + rhs.x, y: GLfloat(lhs) + rhs.y, z: GLfloat(lhs) + rhs.z, w: GLfloat(lhs) + rhs.w)
}

public func -(lhs:CGFloat, rhs:GLVector4) -> GLVector4 {
    return GLVector4(x: GLfloat(lhs) - rhs.x, y: GLfloat(lhs) - rhs.y, z: GLfloat(lhs) - rhs.z, w: GLfloat(lhs) - rhs.w)
}

public func *(lhs:CGFloat, rhs:GLVector4) -> GLVector4 {
    return GLVector4(x: GLfloat(lhs) * rhs.x, y: GLfloat(lhs) * rhs.y, z: GLfloat(lhs) * rhs.z, w: GLfloat(lhs) * rhs.w)
}

public func /(lhs:CGFloat, rhs:GLVector4) -> GLVector4 {
    return GLVector4(x: GLfloat(lhs) / rhs.x, y: GLfloat(lhs) / rhs.y, z: GLfloat(lhs) / rhs.z, w: GLfloat(lhs) / rhs.w)
}

public func +=(lhs:inout GLVector4, rhs:CGFloat) {
    lhs = lhs + rhs
}

public func -=(lhs:inout GLVector4, rhs:CGFloat) {
    lhs = lhs - rhs
}

public func *=(lhs:inout GLVector4, rhs:CGFloat) {
    lhs = lhs * rhs
}

public func /=(lhs:inout GLVector4, rhs:CGFloat) {
    lhs = lhs / rhs
}

public func +(lhs:GLVector4, rhs:SCVector4) -> GLVector4 {
    return lhs + GLVector4(vector: rhs)
}

public func -(lhs:GLVector4, rhs:SCVector4) -> GLVector4 {
    return lhs - GLVector4(vector: rhs)
}

public func *(lhs:GLVector4, rhs:SCVector4) -> GLVector4 {
    return lhs * GLVector4(vector: rhs)
}

public func /(lhs:GLVector4, rhs:SCVector4) -> GLVector4 {
    return lhs / GLVector4(vector: rhs)
}

public func +(lhs:SCVector4, rhs:GLVector4) -> GLVector4 {
    return GLVector4(vector: lhs) + rhs
}

public func -(lhs:SCVector4, rhs:GLVector4) -> GLVector4 {
    return GLVector4(vector: lhs) - rhs
}

public func *(lhs:SCVector4, rhs:GLVector4) -> GLVector4 {
    return GLVector4(vector: lhs) * rhs
}

public func /(lhs:SCVector4, rhs:GLVector4) -> GLVector4 {
    return GLVector4(vector: lhs) / rhs
}

public func +=(lhs:inout GLVector4, rhs:SCVector4) {
    lhs = lhs + rhs
}

public func -=(lhs:inout GLVector4, rhs:SCVector4) {
    lhs = lhs - rhs
}

public func *=(lhs:inout GLVector4, rhs:SCVector4) {
    lhs = lhs * rhs
}

public func /=(lhs:inout GLVector4, rhs:SCVector4) {
    lhs = lhs / rhs
}

public func +=(lhs:inout SCVector4, rhs:GLVector4) {
    lhs = lhs + rhs.getSCVector()
}

public func -=(lhs:inout SCVector4, rhs:GLVector4) {
    lhs = lhs - rhs.getSCVector()
}

public func *=(lhs:inout SCVector4, rhs:GLVector4) {
    lhs = lhs * rhs.getSCVector()
}

public func /=(lhs:inout SCVector4, rhs:GLVector4) {
    lhs = lhs / rhs.getSCVector()
}
