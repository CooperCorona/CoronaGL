//
//  GLSPolygonSprite.swift
//  CoronaGL
//
//  Created by Cooper Knaak on 5/5/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience

open class GLSPolygonSprite: GLSSprite {
    
    public init(points worldPoints:[CGPoint]) {
        let frame = CGRect(points: worldPoints)
        let points = worldPoints.map() { $0 - frame.origin }
        super.init(position: frame.center, size: frame.size, texture: nil)
        
        let center = points.reduce(CGPoint.zero) { $0 + $1 } / CGFloat(points.count)
        var vertices:[UVertex] = []
        var centerVertex = UVertex()
        centerVertex.position = center.getGLTuple()
        for (i, point) in points.enumerateSkipLast() {
            var v1 = UVertex()
            var v2 = UVertex()
            v1.position = point.getGLTuple()
            v2.position = points[i + 1].getGLTuple()
            vertices += [centerVertex, v1, v2]
        }
        var v1 = UVertex()
        var v2 = UVertex()
        if let v1pos = points.last?.getGLTuple() {
            v1.position = v1pos
        }
        if let v2pos = points.first?.getGLTuple() {
            v2.position = v2pos
        }
        vertices += [centerVertex, v1, v2]
        self.vertices = vertices
    }
    
    open override func contentSizeChanged() {
        //For now, do nothing.
        //Doesn't really make sense
        //to change the content size
        //of a sprite defined by points.
    }
    
}
