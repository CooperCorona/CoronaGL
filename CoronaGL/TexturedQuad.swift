//
//  TexturedQuad.swift
//  Fields and Forces
//
//  Created by Cooper Knaak on 12/12/14.
//  Copyright (c) 2014 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience

open class TexturedQuadVertices<T>: ExpressibleByArrayLiteral {
    
    public typealias Element = T
    
    // MARK: - Properties
    
    open var vertices:[T] = []
    open var stride:Int  { return MemoryLayout<T>.size }
    open var count:Int   { return self.vertices.count }
    open var size:Int    { return self.stride * self.count }
    
    public init(vertices:[T] = []) {
        self.vertices = vertices
    }
    
    public convenience init(vertex:T, count:Int = TexturedQuad.verticesPerQuad) {
        var vertices = [vertex]
        for _ in 1..<count {
            vertices.append(vertex)
        }
        
        self.init(vertices: vertices)
    }
    
    /// Create an instance initialized with `elements`.
    public required convenience init(arrayLiteral elements: Element...) {
        self.init(vertices: elements)
    }
    // MARK: - Setup
    
    open func generateVerticesWithHandler(_ handler:(Int) -> T) {
        
        for iii in 0..<TexturedQuad.verticesPerQuad {
            self.vertices.append(handler(iii))
        }
        
    }//generate vertices with handler
    
    open func generateVerticesWithSize(_ size:CGSize, handler:(_ index:Int, _ position:(GLfloat, GLfloat), _ texture:(GLfloat, GLfloat)) -> T) {
        
        //Size as a CGPoint
        let sap = size.getCGPoint()
        for iii in 0..<TexturedQuad.verticesPerQuad {
            let curTex = TexturedQuad.pointForIndex(iii)
            let curPos = (curTex * sap)
            let vertex = handler(iii, curPos.getGLTuple(), curTex.getGLTuple())
            self.vertices.append(vertex)
        }
        
    }//generate vertices with convenience handler
    
    // MARK: - Logic
    
    open func iterateWithHandler(_ handler:(Int, inout T) -> ()) {
        
        for iii in 0..<TexturedQuad.verticesPerQuad {
            handler(iii, &self.vertices[iii])
        }
        
    }//iterate vertices with handler
    
    open func alterVertex(_ vertex:TexturedQuad.VertexName, withHandler handler:(inout T) -> ()) {
        
        let indices = vertex.getVertexIndices()
        for curIndex in indices {
            handler(&self.vertices[curIndex])
        }
        
    }//alter vertex with handler
    
    /**
    Applies 'frame' accurately to each vertex.
    Iterates through each set (4 // 6) of vertices, so you
    can store multiple quads in the same TexturedQuadVertices<T> object.
    
    - parameter frame: The frame to use. Uses the top left, bottom right, etc.
    - parameter handler: A closure that takes the current point (top left, etc.) and an inout *T*. You should set the appropriate property of the *T* to supplied point value.
    */
    open func alterWithFrame(_ frame:CGRect, handler:(CGPoint, inout T) -> Void) {
        
        let tl = frame.topLeftGL
        let bl = frame.bottomLeftGL
        let tr = frame.topRightGL
        let br = frame.bottomRightGL
        if TexturedQuad.verticesPerQuad == 4 {
            
            for iii in 0..<self.vertices.count {
                switch iii % 4 {
                case 0:
                    handler(tl, &self.vertices[iii])
                case 1:
                    handler(bl, &self.vertices[iii])
                case 2:
                    handler(tr, &self.vertices[iii])
                case 3:
                    handler(br, &self.vertices[iii])
                default:
                    //Will never happen!
                    break
                }
            }//Loop through vertices
            
        } else /* 6 */ {
            
            for iii in 0..<self.vertices.count {
                switch iii % 6 {
                case 0:
                    handler(tl, &self.vertices[iii])
                case 1, 3:
                    handler(bl, &self.vertices[iii])
                case 2, 4:
                    handler(tr, &self.vertices[iii])
                case 5:
                    handler(br, &self.vertices[iii])
                default:
                    //Will never happen!
                    break
                }
            }//Loop through vertices
            
        }// 6
        
    }
    
    open func append(_ vertex:T) {
        self.vertices.append(vertex)
    }
    
    open subscript(index:Int) -> T {
        get {
            return self.vertices[index]
        }
        set {
            self.vertices[index] = newValue
        }
    }
    
    
    open func bufferDataWithVertexBuffer(_ vertexBuffer:GLuint, usage:GLenum = GLenum(GL_STATIC_DRAW)) {
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), self.size, self.vertices, usage)
    }
    
    /**
    Calls glBufferData.
    
      glBufferData(GLenum(GL_ARRAY_BUFFER), self.size, self.vertices, GLenum(usage))
    */
    open func bufferData(_ usage:Int32) {
        glBufferData(GLenum(GL_ARRAY_BUFFER), self.size, self.vertices, GLenum(usage))
    }
    
    /**
    Calls glDrawArrays.
    
      glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.count))
    */
    open func drawArrays() {
        glDrawArrays(TexturedQuad.drawingMode, 0, GLsizei(self.count))
    }
    
    /**
    Calls glDrawArrays.
    
      glDrawArrays(TexturedQuad.drawingMode, GLsizei(start), GLsizei(count))
    */
    open func drawArraysWithStart(_ start:Int, count:Int) {
        glDrawArrays(TexturedQuad.drawingMode, GLsizei(start), GLsizei(count))
    }
    
}

open class TexturedQuad {
    
    // MARK: - Defined Types
    
    public enum VertexName: String {
        case TopLeft        = "TopLeft"
        case BottomLeft     = "BottomLeft"
        case TopRight       = "TopRight"
        case BottomRight    = "BottomRight"
        
        ///Guarunteed to contain at least one element.
        public func getVertexIndices() -> [Int] {
            if (TexturedQuad.verticesPerQuad == 6) {
                switch self {
                case .TopLeft:
                    return [0]
                case .BottomLeft:
                    return [1, 3]
                case .TopRight:
                    return [2, 4]
                case .BottomRight:
                    return [5]
                }
            } else {
                switch self {
                case .TopLeft:
                    return [0]
                case .BottomLeft:
                    return [1]
                case .TopRight:
                    return [2]
                case .BottomRight:
                    return [3]
                }
            }
        }
        
        public static func getAllValues() -> [VertexName] {
            return [.TopLeft, .BottomLeft, .TopRight, .BottomRight]
        }
        
        init?(index:Int) {
            
            if TexturedQuad.verticesPerQuad == 4 {
                
                switch index {
                case 0:
                    self = .TopLeft
                case 1:
                    self = .BottomLeft
                case 2:
                    self = .TopRight
                case 3:
                    self = .BottomRight
                default:
                    return nil
                }
                
            } else /* 6 */ {
                
                switch index {
                case 0:
                    self = .TopLeft
                case 1, 3:
                    self = .BottomLeft
                case 2, 4:
                    self = .TopRight
                case 5:
                    self = .BottomRight
                default:
                    return nil
                }
            }
            
        }
        
    }
    
    // MARK: - Static Methods
    
    open class func setPosition(_ position:CGRect, ofVertices vertices: inout [UVertex]) {
        
        if (TexturedQuad.verticesPerQuad == 6) {
            
            vertices[0].position = position.topLeftGL.getGLTuple()
            vertices[1].position = position.bottomLeftGL.getGLTuple()
            vertices[2].position = position.topRightGL.getGLTuple()
            vertices[3].position = vertices[1].position
            vertices[4].position = vertices[2].position
            vertices[5].position = position.bottomRightGL.getGLTuple()
            
        } else /* 4 */ {
            
            vertices[0].position = position.topLeftGL.getGLTuple()
            vertices[1].position = position.bottomLeftGL.getGLTuple()
            vertices[2].position = position.topRightGL.getGLTuple()
            vertices[3].position = position.bottomRightGL.getGLTuple()
            
        }
        
    }//set texture of vertices
    
    open class func setTexture(_ texture:CGRect, ofVertices vertices: inout [UVertex]) {
        
        if (TexturedQuad.verticesPerQuad == 6) {
            
            vertices[0].texture = texture.topLeftGL.getGLTuple()
            vertices[1].texture = texture.bottomLeftGL.getGLTuple()
            vertices[2].texture = texture.topRightGL.getGLTuple()
            vertices[3].texture = vertices[1].texture
            vertices[4].texture = vertices[2].texture
            vertices[5].texture = texture.bottomRightGL.getGLTuple()
            
        } else /* 4 */ {
            
            vertices[0].texture = texture.topLeftGL.getGLTuple()
            vertices[1].texture = texture.bottomLeftGL.getGLTuple()
            vertices[2].texture = texture.topRightGL.getGLTuple()
            vertices[3].texture = texture.bottomRightGL.getGLTuple()
            
        }
        
    }//set texture of vertices
    
    open class func pointForIndex(_ index:Int) -> CGPoint {
        
        //If the number of vertices per quad is 4,
        //then I am using GL_TRIANGLE_STRIPS
        //If it is 6, then I'm using GL_TRIANGLES
        
        if (TexturedQuad.verticesPerQuad == 6) {
            
            switch (index) {
                
            case 0:
                return CGPoint(x: 0.0, y: 1.0)
                
            case 1, 3:
                return CGPoint(x: 0.0, y: 0.0)
                
            case 2, 4:
                return CGPoint(x: 1.0, y: 1.0)
                
            case 5:
                return CGPoint(x: 1.0, y: 0.0)
                
            default:
                return CGPoint.zero
            }
            
        } else {
            switch (index) {
                
            case 0:
                return CGPoint(x: 0.0, y: 1.0)
                
            case 1:
                return CGPoint(x: 0.0, y: 0.0)
                
            case 2:
                return CGPoint(x: 1.0, y: 1.0)
                
            case 3:
                return CGPoint(x: 1.0, y: 0.0)
                
            default:
                return CGPoint.zero
            }
        }
        
        
    }//point for index
    
    open class func generateVertices() -> [UVertex] {
        
        var verts:[UVertex] = []
        for _ in 0..<TexturedQuad.verticesPerQuad {
            verts.append(UVertex())
        }
        
        return verts
    }//generate vertices
    
    open class func generateVerticesWithHandler(_ handler:(Int, inout UVertex) -> ()) -> [UVertex] {
        
        var verts:[UVertex] = []
        for iii in 0..<TexturedQuad.verticesPerQuad {
            var vertex = UVertex()
            
            handler(iii, &vertex)
            
            verts.append(vertex)
        }
        
        return verts
    }//generate vertices (and configure them with handler)

    /*
    public class var verticesPerQuad:Int { return 4 }
    public class var drawingMode:GLenum { return GLenum(GL_TRIANGLE_STRIP) }
    */
    open class var verticesPerQuad:Int { return 6 }
    open class var drawingMode:GLenum { return GLenum(GL_TRIANGLES) }
    
}
