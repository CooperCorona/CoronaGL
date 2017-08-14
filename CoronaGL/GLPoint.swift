//
//  GLPoint.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/28/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
import OpenGLES
#else
import OpenGL
#endif
/**
 Represents a point in a cartesian plane, but
 instead of storing the x and y coordinates as
 CGFloats, they're stored as GLfloats. This way,
 OpenGL vertex structs can use GLPoint instead
 of (GLfloat, GLfloat) tuples. This lets them
 leverage operator overloading, which is much
 more convenient / intuitive than having to
 do the calculations component-wise. No other
 functionality is provided; it is intended that
 users do all their calculations using CGPoint and
 then convert to GLPoint right before setting the
 values in the vertex.
 */
public struct GLPoint {
    public var x:GLfloat = 0.0
    public var y:GLfloat = 0.0
    
    public init() {
        self.x = 0.0
        self.y = 0.0
    }
    
    public init(x:GLfloat, y:GLfloat) {
        self.x = x
        self.y = y
    }
    
    public init(point:CGPoint) {
        self.init(x: GLfloat(point.x), y: GLfloat(point.y))
    }
    
    public func getCGPoint() -> CGPoint {
        return CGPoint(x: CGFloat(self.x), y: CGFloat(self.y))
    }
}

extension CGPoint {
    
    public func getGLPoint() -> GLPoint {
        return GLPoint(point: self)
    }
    
}
