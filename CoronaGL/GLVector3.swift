//
//  GLVector3.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/28/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaConvenience
import CoronaStructures
import OpenGL

/**
 Represents a 3-component vector using
 GLfloat as the underlying stores. See
 GLPoint comment for further reasoning.
 */
public struct GLVector3 {
    public var x:GLfloat = 0.0
    public var y:GLfloat = 0.0
    public var z:GLfloat = 0.0
    
    public init() {
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
    }
    
    public init(x:GLfloat, y:GLfloat, z:GLfloat) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(vector:SCVector3) {
        self.init(x: GLfloat(vector.x), y: GLfloat(vector.y), z: GLfloat(vector.z))
    }
    
    public func getSCVector() -> SCVector3 {
        return SCVector3(x: CGFloat(self.x), y: CGFloat(self.y), z: CGFloat(self.z))
    }
}

extension SCVector3 {
    
    public func getGLVector() -> GLVector3 {
        return GLVector3(vector: self)
    }
    
}
