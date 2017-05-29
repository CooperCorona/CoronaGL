//
//  GLVector3+Operations.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/28/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaConvenience
import CoronaStructures
import OpenGL

public func +(lhs:GLVector3, rhs:GLVector3) -> GLVector3 {
    return GLVector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
}

public func -(lhs:GLVector3, rhs:GLVector3) -> GLVector3 {
    return GLVector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
}

public func *(lhs:GLVector3, rhs:GLVector3) -> GLVector3 {
    return GLVector3(x: lhs.x * rhs.x, y: lhs.y * rhs.y, z: lhs.z * rhs.z)
}

public func /(lhs:GLVector3, rhs:GLVector3) -> GLVector3 {
    return GLVector3(x: lhs.x / rhs.x, y: lhs.y / rhs.y, z: lhs.z / rhs.z)
}

public func +=(lhs:inout GLVector3, rhs:GLVector3) {
    lhs = lhs + rhs
}

public func -=(lhs:inout GLVector3, rhs:GLVector3) {
    lhs = lhs - rhs
}

public func *=(lhs:inout GLVector3, rhs:GLVector3) {
    lhs = lhs * rhs
}

public func /=(lhs:inout GLVector3, rhs:GLVector3) {
    lhs = lhs / rhs
}

public func +(lhs:GLVector3, rhs:CGFloat) -> GLVector3 {
    return GLVector3(x: lhs.x + GLfloat(rhs), y: lhs.y + GLfloat(rhs), z: lhs.z + GLfloat(rhs))
}

public func -(lhs:GLVector3, rhs:CGFloat) -> GLVector3 {
    return GLVector3(x: lhs.x - GLfloat(rhs), y: lhs.y - GLfloat(rhs), z: lhs.z - GLfloat(rhs))
}

public func *(lhs:GLVector3, rhs:CGFloat) -> GLVector3 {
    return GLVector3(x: lhs.x * GLfloat(rhs), y: lhs.y * GLfloat(rhs), z: lhs.z * GLfloat(rhs))
}

public func /(lhs:GLVector3, rhs:CGFloat) -> GLVector3 {
    return GLVector3(x: lhs.x / GLfloat(rhs), y: lhs.y / GLfloat(rhs), z: lhs.z / GLfloat(rhs))
}

public func +(lhs:CGFloat, rhs:GLVector3) -> GLVector3 {
    return GLVector3(x: GLfloat(lhs) + rhs.x, y: GLfloat(lhs) + rhs.y, z: GLfloat(lhs) + rhs.z)
}

public func -(lhs:CGFloat, rhs:GLVector3) -> GLVector3 {
    return GLVector3(x: GLfloat(lhs) - rhs.x, y: GLfloat(lhs) - rhs.y, z: GLfloat(lhs) - rhs.z)
}

public func *(lhs:CGFloat, rhs:GLVector3) -> GLVector3 {
    return GLVector3(x: GLfloat(lhs) * rhs.x, y: GLfloat(lhs) * rhs.y, z: GLfloat(lhs) * rhs.z)
}

public func /(lhs:CGFloat, rhs:GLVector3) -> GLVector3 {
    return GLVector3(x: GLfloat(lhs) / rhs.x, y: GLfloat(lhs) / rhs.y, z: GLfloat(lhs) / rhs.z)
}

public func +=(lhs:inout GLVector3, rhs:CGFloat) {
    lhs = lhs + rhs
}

public func -=(lhs:inout GLVector3, rhs:CGFloat) {
    lhs = lhs - rhs
}

public func *=(lhs:inout GLVector3, rhs:CGFloat) {
    lhs = lhs * rhs
}

public func /=(lhs:inout GLVector3, rhs:CGFloat) {
    lhs = lhs / rhs
}

public func +(lhs:GLVector3, rhs:SCVector3) -> GLVector3 {
    return lhs + GLVector3(vector: rhs)
}

public func -(lhs:GLVector3, rhs:SCVector3) -> GLVector3 {
    return lhs - GLVector3(vector: rhs)
}

public func *(lhs:GLVector3, rhs:SCVector3) -> GLVector3 {
    return lhs * GLVector3(vector: rhs)
}

public func /(lhs:GLVector3, rhs:SCVector3) -> GLVector3 {
    return lhs / GLVector3(vector: rhs)
}

public func +(lhs:SCVector3, rhs:GLVector3) -> GLVector3 {
    return GLVector3(vector: lhs) + rhs
}

public func -(lhs:SCVector3, rhs:GLVector3) -> GLVector3 {
    return GLVector3(vector: lhs) - rhs
}

public func *(lhs:SCVector3, rhs:GLVector3) -> GLVector3 {
    return GLVector3(vector: lhs) * rhs
}

public func /(lhs:SCVector3, rhs:GLVector3) -> GLVector3 {
    return GLVector3(vector: lhs) / rhs
}

public func +=(lhs:inout GLVector3, rhs:SCVector3) {
    lhs = lhs + rhs
}

public func -=(lhs:inout GLVector3, rhs:SCVector3) {
    lhs = lhs - rhs
}

public func *=(lhs:inout GLVector3, rhs:SCVector3) {
    lhs = lhs * rhs
}

public func /=(lhs:inout GLVector3, rhs:SCVector3) {
    lhs = lhs / rhs
}

public func +=(lhs:inout SCVector3, rhs:GLVector3) {
    lhs = lhs + rhs.getSCVector()
}

public func -=(lhs:inout SCVector3, rhs:GLVector3) {
    lhs = lhs - rhs.getSCVector()
}

public func *=(lhs:inout SCVector3, rhs:GLVector3) {
    lhs = lhs * rhs.getSCVector()
}

public func /=(lhs:inout SCVector3, rhs:GLVector3) {
    lhs = lhs / rhs.getSCVector()
}
