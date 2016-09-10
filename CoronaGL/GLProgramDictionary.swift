//
//  GLProgramDictionary.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 7/7/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaStructures

public class GLProgramDictionary: GLAttributeBridger {
    
    // MARK: - Properties
    
    private var dict:[String:GLint] = [:]
    public let locations:[String]
    
    public var attributeSizes:[Int]? = nil
    
    // MARK: - Setup
    
    /**
    Initializes a *GLProgramDictionary* object with a program and a list of locations.
    
    - parameter program: The OpenGL shader program.
    - parameter locations: The names of the locations. They must all match a name in the vertex
    or fragment shader. Uniforms must start with *u_*, attributes with *a_*.
    */
    public init(program:GLuint, locations:[String]) {
        
        self.locations = locations
        
        var attributes:[GLint] = []
        
        for name in locations {
            let value:GLint
            if name.hasPrefix("u_") {
                value = glGetUniformLocation(program, name)
            } else /* a_ */ {
                value = glGetAttribLocation(program, name)
                if value < 0 {
                    print("Error: \(name) location is \(value).")
                    print("Is the value used in the shader?")
                    continue
                }
                
                attributes.append(value)
            }
            self.dict[name] = value
        }
        
        super.init(program: program)
        
        self.addAttributes(attributes)
    }
    
    // MARK: - Logic
    
    /**
    Access internal dictionary.
    
    - parameter key: The key for the desired value.
    - returns: The value corresponding to the key, if it exists.
    */
    public func locationForKey(key:String) -> GLint? {
        return self.dict[key]
    }
    
    /**
    Accesses internal dictionary, force unwraps value. Only use when you know value will exist.
    
    - parameter key: The key for the desired value.
    - returns: The value corresponding to the key. Crashes if it doesn't exist.
    */
    public subscript(key:String) -> GLint {
        return self.dict[key]!
    }
    
    /**
    Calls glUseProgram and glBindBuffer
    
        glUseProgram(self.program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.vertexBuffer)
    */
    public func use() {
        glUseProgram(self.program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.vertexBuffer)
    }
    
    
    ///Invokes glUniform2f with the given location and value.
    public func uniform2f(location:String, value:CGPoint) {
        glUniform2f(self[location], GLfloat(value.x), GLfloat(value.y))
    }
    
    ///Invokes glUniform3f with the given location and value.
    public func uniform3f(location:String, value:SCVector3) {
        glUniform3f(self[location], GLfloat(value.x), GLfloat(value.y), GLfloat(value.z))
    }
    
    ///Invokes glUniform4f with the given location and value.
    public func uniform4f(location:String, value:SCVector4) {
        glUniform4f(self[location], GLfloat(value.x), GLfloat(value.y), GLfloat(value.z), GLfloat(value.w))
    }
    
}
