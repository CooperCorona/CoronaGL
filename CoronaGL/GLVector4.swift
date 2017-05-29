//
//  GLVector4.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/28/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import CoronaConvenience
import CoronaStructures
import OpenGL

/**
 Represents a 4-component vector using
 GLfloat as the underlying stores. See
 GLPoint comment for further reasoning.
 */
public struct GLVector4 {
    public var x:GLfloat = 0.0
    public var y:GLfloat = 0.0
    public var z:GLfloat = 0.0
    public var w:GLfloat = 0.0
    
    public init() {
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        self.w = 0.0
    }
    
    public init(x:GLfloat, y:GLfloat, z:GLfloat, w:GLfloat) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    public init(vector:SCVector4) {
        self.init(x: GLfloat(vector.x), y: GLfloat(vector.y), z: GLfloat(vector.z), w: GLfloat(vector.w))
    }
    
    public init(rect:CGRect) {
        self.init(x: GLfloat(rect.origin.x), y: GLfloat(rect.origin.y), z: GLfloat(rect.size.width), w: GLfloat(rect.size.height))
    }
    
    public func getSCVector() -> SCVector4 {
        return SCVector4(x: CGFloat(self.x), y: CGFloat(self.y), z: CGFloat(self.z), w: CGFloat(self.w))
    }
    
    public func getCGRect() -> CGRect {
        return CGRect(x: CGFloat(self.x), y: CGFloat(self.y), width: CGFloat(self.z), height: CGFloat(self.w))
    }
}

extension SCVector4 {
    
    public func getGLVector() -> GLVector4 {
        return GLVector4(vector: self)
    }
    
}
