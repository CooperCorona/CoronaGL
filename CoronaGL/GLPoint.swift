//
//  GLPoint.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/28/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Foundation
import OpenGL

public struct GLPoint {
    public var x:GLfloat = 0.0
    public var y:GLfloat = 0.0
    
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
