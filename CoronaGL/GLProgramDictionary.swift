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
import CoronaConvenience
import CoronaStructures

open class GLProgramDictionary: GLAttributeBridger {
    
    // MARK: - Properties
    
    fileprivate var dict:[String:GLint] = [:]
    open let locations:[String]
    
    open var attributeSizes:[Int]? = nil
    
    #if os(OSX)
    fileprivate(set) open var vertexArray:GLuint = 0
    #endif
    
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
        
        #if os(OSX)
        glGenVertexArrays(1, &self.vertexArray)
        glBindVertexArray(self.vertexArray)
        glBindVertexArray(0)
        #endif
    }
    
    public convenience init?(program:GLuint, vertexShader:String, fragmentShader:String, geometryShader:String? = nil) {
        var uniforms:[String]       = []
        var attributes:[String]     = []
        var attributeSizes:[Int]    = []
        let vertexLocations = GLProgramDictionary.bridgeLocationsForFile(vertexShader, shaderType: GLenum(GL_VERTEX_SHADER))
        uniforms += vertexLocations.uniforms
        attributes += vertexLocations.attributes
        attributeSizes += vertexLocations.attributeSizes
        let fragmentLocations = GLProgramDictionary.bridgeLocationsForFile(fragmentShader, shaderType: GLenum(GL_FRAGMENT_SHADER))
        uniforms += fragmentLocations.uniforms
#if os(OSX)
        if let geometryShader = geometryShader {
            let geometryLocations = GLProgramDictionary.bridgeLocationsForFile(geometryShader, shaderType: GLenum(GL_GEOMETRY_SHADER))
            uniforms += geometryLocations.uniforms
        }
#endif
        // Fragment (and geometry) shader doesn't have attributes.
        // (it has varyings, but they're input from
        // the vertex shader, so the program dictionary
        // doesn't need to know about them).
        self.init(program: program, locations: uniforms + attributes)
        self.attributeSizes = attributeSizes
    }
    
    fileprivate class func bridgeLocationsForFile(_ file:String, shaderType:GLenum) -> (uniforms:[String], attributes:[String], attributeSizes:[Int]) {
        
        func isUniform(_ line:String) -> Bool {
            return line.hasPrefix("uniform")
        }
        
        func isAttribute(_ line:String) -> Bool {
            return line.hasPrefix("attribute") || (line.hasPrefix("in") && shaderType == GLenum(GL_VERTEX_SHADER))
        }
        
        guard let uniformRegex = NSRegularExpression(regex: "u_.*[^;]"),
            let attributeRegex = NSRegularExpression(regex: "a_.*[^;]"),
            let varyingRegex = NSRegularExpression(regex: "v_.*[^;]") else {
                return ([], [], [])
        }
        var uniforms:[String] = []
        var attributes:[String] = []
        var attributeSizes:[Int] = []
        let lines = file.components(separatedBy: "\n")
        for (i, line) in lines.enumerated() {
            if let uniform = uniformRegex.matchedStringsInString(line).first , isUniform(line) {
                uniforms.append(uniform)
            } else if let attribute = attributeRegex.matchedStringsInString(line).first , isAttribute(line) {
                attributes.append(attribute)
                if line.contains("float") {
                    attributeSizes.append(1)
                } else if line.contains("vec2") {
                    attributeSizes.append(2)
                } else if line.contains("vec3") {
                    attributeSizes.append(3)
                } else if line.contains("vec4") {
                    attributeSizes.append(4)
                } else {
                    print("Error: invalid attribute size for line #\(i) \"\(line)\"")
                }
            }
            
        }
        return (uniforms, attributes, attributeSizes)
    }
    // MARK: - Logic
    
    /**
    Access internal dictionary.
    
    - parameter key: The key for the desired value.
    - returns: The value corresponding to the key, if it exists.
    */
    open func locationForKey(_ key:String) -> GLint? {
        return self.dict[key]
    }
    
    /**
    Accesses internal dictionary, force unwraps value. Only use when you know value will exist.
    
    - parameter key: The key for the desired value.
    - returns: The value corresponding to the key. Crashes if it doesn't exist.
    */
    open subscript(key:String) -> GLint {
        return self.dict[key]!
    }
    
    /**
    Calls glUseProgram and glBindBuffer
    
        glUseProgram(self.program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.vertexBuffer)
    */
    open func use() {
        glUseProgram(self.program)
        #if os(OSX)
        glBindVertexArray(self.vertexArray)
        #endif
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.vertexBuffer)
    }
    
    
    ///Invokes glUniform1f with the given location and value, casting to GLfloat.
    open func uniform1f(_ location:String, value:CGFloat) {
        glUniform1f(self[location], GLfloat(value))
    }
    
    ///Invokes glUniform2f with the given location and value.
    open func uniform2f(_ location:String, value:CGPoint) {
        glUniform2f(self[location], GLfloat(value.x), GLfloat(value.y))
    }
    
    ///Invokes glUniform3f with the given location and value.
    open func uniform3f(_ location:String, value:SCVector3) {
        glUniform3f(self[location], GLfloat(value.x), GLfloat(value.y), GLfloat(value.z))
    }
    
    ///Invokes glUniform4f with the given location and value.
    open func uniform4f(_ location:String, value:SCVector4) {
        glUniform4f(self[location], GLfloat(value.x), GLfloat(value.y), GLfloat(value.z), GLfloat(value.w))
    }
   
    open func uniformMatrix4fv(_ location:String, matrix:SCMatrix4) {
        glUniformMatrix4fv(self[location], 1, 0, matrix.values)
    }

    open func disable() {
        super.disableAttributes()
        glUseProgram(0)
        #if os(OSX)
            glBindVertexArray(0)
        #endif
    }
}
