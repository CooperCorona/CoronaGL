//
//  GLAttributeBridger.swift
//  Gravity
//
//  Created by Cooper Knaak on 5/22/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif


public class GLAttributeBridger: NSObject {
    
    public private(set) var vertexBuffer:GLuint = 0
    public let program:GLuint
    
    private(set) var attributes:[GLuint] = []
    
    public init(program:GLuint) {
        
        self.program = program
        glGenBuffers(1, &self.vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.vertexBuffer)
        
    }//initialize with program
    
    public func addAttribute(location:GLint) {
        if location < 0 {
            print("Error: Attribute location \(location) is invalid!")
            print("")
        }
        self.attributes.append(GLuint(location))
    }
    
    public func addAttributes(locations:[GLint]) {
        for cur in locations {
            self.addAttribute(cur)
        }
    }
    
    public func enableAttributes() {
        for cur in self.attributes {
            glEnableVertexAttribArray(cur)
        }
    }
    
    /**
    Convenience method to invoke glVertexAttribPointer multiple times.
    
    - parameter sizes: The sizes (in # of GLfloat components) of each successive property in corresponding Vertex Struct.
    
    - parameter stride: The size of the Vertex Struct.
    */
    public func bridgeAttributesWithSizes(sizes:[Int], stride:Int) {
        
        var position = 0
        for index in 0..<self.attributes.count {
            if (index >= sizes.count) {
                break
            }
            
            let size = sizes[index]
            let pointer = UnsafePointer<Void>(bitPattern: sizeof(GLfloat) * position)
            glVertexAttribPointer(self.attributes[index], GLint(size), GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(stride), pointer)
            
            position += size
        }
    }
    
    public func disableAttributes() {
        
        for cur in self.attributes {
            glDisableVertexAttribArray(cur)
        }
    }

    deinit {
        glDeleteBuffers(1, &self.vertexBuffer)
        self.vertexBuffer = 0
    }
}
