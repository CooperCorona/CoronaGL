//
//  GLSBoolList2DSprite.swift
//  CoronaPathfinding
//
//  Created by Cooper Knaak on 12/5/15.
//  Copyright © 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import CoronaStructures

/**
Originally a class that allowed a visual representation of a BoolList2D, I realized that the only necessary information is the texture. Otherwise, a regular sprite works just fine. I still wanted to group these methods on a class, though, so I just made the only constructor private.
*/
open class GLSBoolList2DSprite: GLSSprite {

    // MARK: - Types
    
    public struct ColorSet {
        public fileprivate(set) var colorArray:[GLubyte] = [255, 255, 255, 255]
        public var color:SCVector3 {
            get {
                return SCVector3(x: CGFloat(self.colorArray[0]) / 255.0, y: CGFloat(self.colorArray[1]) / 255.0, z: CGFloat(self.colorArray[2]) / 255.0)
            }
            set {
                self.colorArray[0] = GLubyte(newValue.x * 255.0)
                self.colorArray[1] = GLubyte(newValue.y * 255.0)
                self.colorArray[2] = GLubyte(newValue.z * 255.0)
            }
        }
        public var points  = Set<IntPoint>()
        
        public init() {
            
        }
        
        public init(array:[GLubyte], points:Set<IntPoint>) {
            self.colorArray = array
            self.points     = points
        }
        
        public init(color:SCVector3, points:Set<IntPoint>) {
            self.color  = color
            self.points = points
        }
        
    }
    
    ///Wrapper for the colors different positions should be.
    public struct ColorData {
        public fileprivate(set) var validColorArray:[GLubyte]   = [170, 170, 170, 255]
        public fileprivate(set) var invalidColorArray:[GLubyte] = [85, 85, 85, 255]
        var validColor:SCVector3 {
            get {
                return SCVector3(x: CGFloat(self.validColorArray[0]) / 255.0, y: CGFloat(self.validColorArray[1]) / 255.0, z: CGFloat(self.validColorArray[2]) / 255.0)
            }
            set {
                self.validColorArray[0] = GLubyte(newValue.x * 255.0)
                self.validColorArray[1] = GLubyte(newValue.y * 255.0)
                self.validColorArray[2] = GLubyte(newValue.z * 255.0)
            }
        }
        var invalidColor:SCVector3 {
            get {
                return SCVector3(x: CGFloat(self.invalidColorArray[0]) / 255.0, y: CGFloat(self.invalidColorArray[1]) / 255.0, z: CGFloat(self.invalidColorArray[2]) / 255.0)
            }
            set {
                self.invalidColorArray[0] = GLubyte(newValue.x * 255.0)
                self.invalidColorArray[1] = GLubyte(newValue.y * 255.0)
                self.invalidColorArray[2] = GLubyte(newValue.z * 255.0)
            }
        }
        var colors:[ColorSet]   = []
        
        public init() {
            
        }
        
        public init(valid:SCVector3, invalid:SCVector3, colors:[ColorSet]) {
            self.validColor     = valid
            self.invalidColor   = invalid
            self.colors         = colors
        }
        
        public mutating func addColor(_ color:SCVector3, forPoints points:Set<IntPoint>) {
            self.colors.append(ColorSet(color: color, points: points))
        }
        
        public func colorForPoint(_ point:IntPoint) -> [GLubyte]? {
            for colorSet in self.colors {
                if colorSet.points.contains(point) {
                    return colorSet.colorArray
                }
            }
            return nil
        }
        
    }
    
    // MARK: - Setup
    
    ///Made private so you can't actually instantiate one. MWA-HA-HA!
    fileprivate override init(position: CGPoint, size: CGSize, texture: CCTexture?) {
        super.init(position: position, size: size, texture: texture)
    }
    
    /**
     Generates a 1D array (modelling a 2D array) containing color data to be turned into an OpenGL texture.
     
     - parameter values: The valid / invalid state values for each position.
     - parameter colors: The colors that specific positions should be.
     */
    open class func getTextureArray(_ values:BoolList2D, colors:ColorData) -> [GLubyte] {
        var bytes:[GLubyte] = []
        for j in 0..<values.height {
            for i in 0..<values.width {
                if let color = colors.colorForPoint(IntPoint(x: i, y: j)) {
                    bytes += color
                } else if values[i, j] {
                    bytes += colors.validColorArray
                } else {
                    bytes += colors.invalidColorArray
                }
            }
        }
        return bytes
    }
    
    /**
     Converts an array of color values into an OpenGL texture. You are responsible for making sure that the dimensions are correct.
     
     - parameter array: The colors values.
     - parameter width: The width of the texture.
     - parameter height: The height of the texture.
     - returns: A GLuint corresponding to an OpenGL texture.
    */
    open class func convertArrayToTexture(_ array:[GLubyte], width:Int, height:Int) -> GLuint {
        var textureName:GLuint = 0
        glGenTextures(1, &textureName)
        glBindTexture(GLenum(GL_TEXTURE_2D), textureName)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GLint(GL_RGBA), GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), array)
        return textureName
    }
    
    /**
     Creates a GLSSprite containing the BoolList2D's information on a background thread. Calls the completion handler on the main thread.
     
     - parameter queue: The queue to create the color array on.
     - parameter values: The BoolList2D to get the valid/invalid values from.
     - parameter colors: The data determining the color of each point.
     - parameter size: The size of the sprite.
     - parameter handler: A handler invoked on the main thread once the sprite is created.
    */
    open class func initializeAsync(_ queue:DispatchQueue, values:BoolList2D, colors:ColorData, size:CGSize, handler:@escaping (GLSSprite) -> Void) {
        queue.async {
            let bytes = GLSBoolList2DSprite.getTextureArray(values, colors: colors)
            DispatchQueue.main.async {
                let texture = GLSBoolList2DSprite.convertArrayToTexture(bytes, width: values.width, height: values.height)
                let sprite = GLSSprite(size: size, texture: CCTexture(name: texture))
                handler(sprite)
            }
        }
    }
    
}
