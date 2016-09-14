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

public class GLProgramDictionary: GLAttributeBridger {
    
    // MARK: - Properties
    
    private var dict:[String:GLint] = [:]
    public let locations:[String]
    
    public var attributeSizes:[Int]? = nil
    
    #if os(OSX)
    private(set) public var vertexArray:GLuint = 0
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
    
    public convenience init?(program:GLuint, vertexShader:String, fragmentShader:String) {
        var uniforms:[String]       = []
        var attributes:[String]     = []
        var attributeSizes:[Int]    = []
        let vertexLocations = GLProgramDictionary.bridgeLocationsForFile(vertexShader, shaderType: GLenum(GL_VERTEX_SHADER))
        uniforms += vertexLocations.uniforms
        attributes += vertexLocations.attributes
        attributeSizes += vertexLocations.attributeSizes
        let fragmentLocations = GLProgramDictionary.bridgeLocationsForFile(fragmentShader, shaderType: GLenum(GL_FRAGMENT_SHADER))
        uniforms += fragmentLocations.uniforms
        // Fragment shader doesn't have attributes
        self.init(program: program, locations: uniforms + attributes)
        self.attributeSizes = attributeSizes
    }
    
    private class func bridgeLocationsForFile(file:String, shaderType:GLenum) -> (uniforms:[String], attributes:[String], attributeSizes:[Int]) {
        
        func isUniform(line:String) -> Bool {
            return line.hasPrefix("uniform")
        }
        
        func isAttribute(line:String) -> Bool {
            return line.hasPrefix("attribute") || (line.hasPrefix("in") && shaderType == GLenum(GL_VERTEX_SHADER))
        }
        
        guard let uniformRegex = NSRegularExpression(regex: "u_.*[^;]"),
            attributeRegex = NSRegularExpression(regex: "a_.*[^;]"),
            varyingRegex = NSRegularExpression(regex: "v_.*[^;]") else {
                return ([], [], [])
        }
        var uniforms:[String] = []
        var attributes:[String] = []
        var attributeSizes:[Int] = []
        let lines = file.componentsSeparatedByString("\n")
        for (i, line) in lines.enumerate() {
            if let uniform = uniformRegex.matchedStringsInString(line).first where isUniform(line) {
                uniforms.append(uniform)
            } else if let attribute = attributeRegex.matchedStringsInString(line).first where isAttribute(line) {
                attributes.append(attribute)
                if line.containsString("float") {
                    attributeSizes.append(1)
                } else if line.containsString("vec2") {
                    attributeSizes.append(2)
                } else if line.containsString("vec3") {
                    attributeSizes.append(3)
                } else if line.containsString("vec4") {
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
        #if os(OSX)
        glBindVertexArray(self.vertexArray)
        #endif
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
   
    public func uniformMatrix4fv(location:String, matrix:SCMatrix4) {
        glUniformMatrix4fv(self[location], 1, 0, matrix.values)
    }

    #if os(OSX)
    public func disable() {
        super.disableAttributes()
        glUseProgram(0)
        glBindVertexArray(0)
    }
    #endif
}
