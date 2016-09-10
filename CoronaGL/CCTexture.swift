//
//  CCTexture.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 12/10/14.
//  Copyright (c) 2014 Cooper Knaak. All rights reserved.
//

import GLKit

public class CCTexture: NSObject, StringLiteralConvertible {
    
    // MARK: - Properties
    
    public let name:GLuint
    public let frame:CGRect
    
    // MARK: - Setup
    
    public convenience init(name:GLuint) {
        self.init(name:name, frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
    }//initialize
    
    public init(name:GLuint, frame:CGRect) {
        
        self.name = name
        self.frame = frame
        
        super.init()
        
    }//initialize
    
    // MARK: - StringLiteralConvertible
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType
    
    public required convenience init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: "\(value)")
    }
    
    public required convenience init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: "\(value)")
    }
    
    public required convenience init(stringLiteral value:StringLiteralType) {
        let copiedTex = CCTextureOrganizer.textureForString(value)!
        self.init(name: copiedTex.name, frame: copiedTex.frame)
    }
    
    // MARK: - Logic
    
    public func makeRepeating() {
        glBindTexture(GLenum(GL_TEXTURE_2D), self.name)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
    }
    
    // MARK: - CustomStringConvertible
    
    override public var description:String {
        return "\(name)-\(frame)"
    }
    
}
