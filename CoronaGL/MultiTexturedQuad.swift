//
//  MultiTexturedQuad.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 7/23/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

/**
A class in the same vein as *TexturedQuad* that allows multiple,
distinct sets of vertices to be used and accessed.
*/
public class MultiTexturedQuad<T>: ArrayLiteralConvertible {
    
    public typealias Element = T
    
    // MARK: - Properties
    
    public var vertices:[T] = []
    public var stride:Int  { return sizeof(T) }
    public var count:Int   { return self.vertices.count }
    public var size:Int    { return self.stride * self.count }
    public var quadCount:Int { return self.count / TexturedQuad.verticesPerQuad }
    
    // MARK: - Setup
    
    /**
    Initialize with an array.
    
    - parameter vertices: An array of vertices to use.
    */
    public init(vertices:[T] = []) {
        self.vertices = vertices
    }
    
    /**
    Initializes a MultiTexturedQuad object with a vertex (T) repeated *count* times.
    
    - parameter vertex: The vertex to repeat.
    - parameter count: The number of times to repeat
    */
    public convenience init(vertex:T, count:Int = TexturedQuad.verticesPerQuad) {
        var vertices = [vertex]
        for _ in 1..<count {
            vertices.append(vertex)
        }
        
        self.init(vertices: vertices)
    }
    
    /**
    Initialize with a default vertex repeated to form multiple quads.
    
    - parameter vertex: The vertex to repeat.
    - parameter The: number of quads to have.
    */
    public convenience init(vertex:T, quads:Int) {
        self.init(vertex: vertex, count: quads * TexturedQuad.verticesPerQuad)
    }
    
    /// Create an instance initialized with `elements`.
    public required convenience init(arrayLiteral elements: Element...) {
        self.init(vertices: elements)
    }
    
    // MARK: - Logic
    
    /**
    Iterates through all vertices, invoking handler for each one.
    
    - parameter handler: A closure with 3 parameters. The first is which quad you are currently in. The second is the index of the current vertex, relative to the quad. The third is the vertex.
    */
    public func iterateWithHandler(handler:(Int, Int, inout T) -> Void) {
        
        for iii in 0..<self.count {
            let quadIndex = iii / TexturedQuad.verticesPerQuad
            let vertexIndex = iii % TexturedQuad.verticesPerQuad
            handler(quadIndex, vertexIndex, &self.vertices[iii])
        }
        
    }
    
    /**
    Iterates through all vertices in a given quad, invoking handler for each one.
    
    - parameter quad: Which quad to iterate the vertices of.
    - parameter handler: A closure with 2 parameters. The first is the index of the current vertex, relative to the quad. The second is the vertex.
    */
    public func iterateQuad(quad:Int, withHandler handler:(Int, inout T) -> Void) {
        
        if quad < 0 || quad >= self.quadCount {
            return
        }
        
        let start = quad * TexturedQuad.verticesPerQuad
        let end = start + TexturedQuad.verticesPerQuad
        for iii in start..<end {
            handler(iii - start, &self.vertices[iii])
        }
    }
    
    /**
    Iterates through all vertices in a given quad, supplying the correct vertex of a rectangle for each vertex.
    
    - parameter quad: The quad to iterate through.
    - parameter rect: The rect to get the vertices from.
    - parameter handler: A closure with 2 parameters. The first is the given vertex of *rect*. The second is the vertex.
    */
    public func iterateQuad(quad:Int, forRect rect:CGRect, withHandler handler:(CGPoint, inout T) -> Void) {
        
        if quad < 0 || quad >= self.quadCount {
            return
        }
        
        let tl = rect.topLeftGL
        let bl = rect.bottomLeftGL
        let tr = rect.topRightGL
        let br = rect.bottomRightGL
        
        let start = quad * TexturedQuad.verticesPerQuad
        
        if TexturedQuad.verticesPerQuad == 6 {
            handler(tl, &self.vertices[start + 0])
            handler(bl, &self.vertices[start + 1])
            handler(tr, &self.vertices[start + 2])
            handler(bl, &self.vertices[start + 3])
            handler(tr, &self.vertices[start + 4])
            handler(br, &self.vertices[start + 5])
        } else /* 4 */ {
            handler(tl, &self.vertices[start + 0])
            handler(bl, &self.vertices[start + 1])
            handler(tr, &self.vertices[start + 2])
            handler(br, &self.vertices[start + 3])
        }
        
    }
    
    /**
    Iterates through all quads, supplying the correct vertex of the rect for each vertex.
    
    - parameter rect: The rect to get the vertices from.
    - parameter A: closure with 2 parameters. The first is the given vertex of *rect*. The second is the vertex.
    */
    public func iterateForRect(rect:CGRect, withHandler handler:(CGPoint, inout T) -> Void) {
        
        for quad in 0..<self.quadCount {
            self.iterateQuad(quad, forRect: rect, withHandler: handler)
        }
        
    }
}
