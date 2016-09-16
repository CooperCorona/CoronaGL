//
//  GLSFrameBuffer.swift
//  Fields and Forces
//
//  Created by Cooper Knaak on 1/9/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience
import CoronaStructures
import QuartzCore

#if os(iOS)
public typealias ImageType = UIImage
#else
public typealias ImageType = NSImage
#endif
open class GLSFrameBuffer: GLSNode {
    
    fileprivate var framebufferName:GLuint = 0
    open var framebuffer:GLuint { return self.framebufferName }
    fileprivate var internalTextureName:GLuint = 0
    //    var texture:GLuint { return self.texture }
    open var textureName:GLuint { return self.internalTextureName }
    #if os(OSX)
    fileprivate(set) open var renderBuffer:GLuint = 0
    open static let globalContext = NSOpenGLContext(format: NSOpenGLPixelFormat(attributes: [
        UInt32(NSOpenGLPFAAccelerated),
        UInt32(NSOpenGLPFAColorSize), UInt32(32),
        UInt32(NSOpenGLPFAOpenGLProfile),
        UInt32(NSOpenGLProfileVersion3_2Core),
        UInt32(0)
        ])!, share: nil)!
    #endif
    
    open let internalSize:CGSize
    open let internalScale:CGFloat
    open let size:CGSize
    
    open var clearColor = SCVector4()
    
    open let ccTexture:CCTexture
    open let sprite:GLSSprite
    /**
    If true, then framebuffer renders normally.
    If false, then you are responsible for rendering.
    The 'sprite' property is provided for you.
    */
    open var renderAutomatically = true
    /**
    If *true*, then framebuffer renders children to self in render method.
    If *false*, then contents of framebuffer do not change automatically.
    */
    open var renderChildren = true
    
    /**
    Texture Parameters must be *GL_LINEAR* and *GL_CLAMP_TO_EDGE*
    for non-power of 2 sizes to work
    */
    public convenience init(size:CGSize) {
        self.init(size: size, scale: GLSFrameBuffer.getRetinaScale())
    }//initialize
    
    ///Initializes a GLSFrameBuffer with a given size and retina scale.
    public init(size:CGSize, scale:CGFloat) {
        #if os(OSX)
        GLSFrameBuffer.globalContext.makeCurrentContext()
        #endif
        
        self.size = size
        self.internalScale = scale
        self.internalSize = self.size * self.internalScale
        
        glGenFramebuffers(1, &self.framebufferName)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.framebufferName)
        
        glGenTextures(1, &self.internalTextureName)
        
        let enumTex = GLenum(GL_TEXTURE_2D)
        glBindTexture(enumTex, self.internalTextureName)
        glTexParameteri(enumTex, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(enumTex, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(enumTex, GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(enumTex, GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        let width = GLsizei(self.internalSize.width)
        let height = GLsizei(self.internalSize.height)
        glTexImage2D(enumTex, 0, GLint(GL_RGBA), width, height, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), nil)
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), enumTex, self.internalTextureName, 0)
        
        #if os(OSX)
        glGenRenderbuffers(1, &self.renderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.renderBuffer)
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_RGBA8), width, height)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT1), GLenum(GL_RENDERBUFFER), self.renderBuffer)
        #endif
        
        let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
        if (status != GLenum(GL_FRAMEBUFFER_COMPLETE)) {
            print("Framebuffer binding failed.")
            
            let statusAsHex = NSString(format: "%x", status)
            let errorAsHex  = NSString(format: "%x", glGetError())
            print("Status:\(statusAsHex) Error code:\(errorAsHex)")
            print("Size:\(self.size) Internal:\(self.internalSize)")
            print("Width:\(width) Height:\(height)")
        }
 
        let ccSize = self.size * self.internalScale / self.internalSize
        self.ccTexture = CCTexture(name: self.internalTextureName, frame: CGRect(x: 0.0, y: 0.0, width: ccSize.width, height: ccSize.height))
        self.sprite = GLSSprite(position: CGPoint.zero, size: self.size, texture: self.ccTexture)
 
        super.init(position:CGPoint.zero, size: self.size)
        
        self.vertices = self.sprite.vertices
        self.texture = self.ccTexture
    }
    
    override open func render(_ model: SCMatrix4) {
        
        let childModel = self.modelMatrix() * model
        
        if self.renderChildren {
            self.framebufferStack?.pushGLSFramebuffer(buffer: self)
            
            self.bindClearColor()
            //        super.render(SCMatrix4())
            let identityMatrix = SCMatrix4()
            for cur in self.children {
                cur.render(identityMatrix)
            }
            
            self.framebufferStack?.popFramebuffer()
        }
        //If 'renderAutomatically' is false, then framebuffer
        //does not handle rendering to screen, but it does
        //handle rendering to framebuffer
        if (!self.renderAutomatically) {
            return
        }
        
        //Make sure sprite's values are equal to framebuffer's values
        self.sprite.position = self.contentSize.center
        self.sprite.anchor = self.anchor
        self.sprite.alpha = self.alpha
        self.sprite.scaleX = self.scaleX
        self.sprite.scaleY = self.scaleY
        self.sprite.rotation = self.rotation
        self.sprite.projection = self.projection
        self.sprite.render(childModel)
    }//render
    
    open func bindClearColor() {
        
        glClearColor(GLfloat(self.clearColor.r), GLfloat(self.clearColor.g), GLfloat(self.clearColor.b), GLfloat(self.clearColor.a))
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
    }//bind clear color
    
    open func getImage() -> ImageType {
    
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.framebufferName)
        glReadBuffer(GLenum(GL_COLOR_ATTACHMENT0))
        
        let width = Int(ceil(self.internalSize.width))
        let height = Int(ceil(self.internalSize.height))
        
        //(width * height) pixels times 4 bytes per pixel
        let dataLength = width * height * 4
        
        var buffer:[GLubyte] = Array<GLubyte>(repeating: 2, count: dataLength)
        
        while (glGetError() != GLenum(GL_NO_ERROR)) {
            
        }
        
//        glPixelStorei(GLenum(GL_PACK_ALIGNMENT), 1)
//        glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT), 1)
        glReadPixels(0, 0, GLsizei(width), GLsizei(height), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &buffer)
        /*
        //OpenGL has origin at bottom left
        //UIImage wants origin at top left
        //So I swap the pixels vertically
        for jjj in 0..<(height / 2) {
            for iii in 0..<(width * 4) {
                
                let index1 = jjj * width * 4 + iii
                let index2 = (height - jjj - 1) * width * 4 + iii
                
                let swapValue = buffer[index1]
                buffer[index1] = buffer[index2]
                buffer[index2] = swapValue
                
            }
            
        }
        */
        
        let dProvider = CGDataProvider(dataInfo: nil, data: buffer, size: Int(dataLength), releaseData: { _ in })!
        let bitsPerComponent = 8
        let bitsPerPixel = bitsPerComponent * 4
        let bytesPerRow = width * 4
        let cSpace = CGColorSpaceCreateDeviceRGB()
//        let bInfo = CGBitmapInfo(CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.Last.rawValue)
        let bInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let rIntent = CGColorRenderingIntent.defaultIntent
        
        let cgIm = CGImage(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: cSpace, bitmapInfo: bInfo, provider: dProvider, decode: nil, shouldInterpolate: false, intent: rIntent)
        
//        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, self.internalScale)
//        let context = UIGraphicsGetCurrentContext()
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: cSpace, bitmapInfo: bInfo.rawValue)
        context?.saveGState()
        
        context?.setBlendMode(CGBlendMode.copy)
        context?.draw(cgIm!, in: CGRect(width: CGFloat(width), height: CGFloat(height), centered: false))
        
//        let im = UIGraphicsGetImageFromCurrentImageContext()
        let cgIm2 = context?.makeImage()
        context?.restoreGState()
//        UIGraphicsEndImageContext()
        #if os(iOS)
        let im = UIImage(cgImage: cgIm2!, scale: self.internalScale, orientation: .up)
        #else
        let im = NSImage(cgImage: cgIm2!, size: self.contentSize)
        #endif
        return im
    }//get framebuffer as image
    
    #if os(iOS)
    /**
    Saves contents of framebuffer to png file.

    - parameter name: Name of file to save.

    - returns: Total path of png file in Documents directory.
    */
    public func saveWithName(name:String) -> URL {
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectory = paths[0]
        
//        var filePath = documentDirectory.stringByAppendingPathComponent(name)
//        filePath = filePath.stringByAppendingPathExtension("png")!
        var filePath:URL = URL(string: documentDirectory)!
        filePath = filePath.appendingPathComponent(name)
        filePath = filePath.appendingPathExtension("png")
        
        let im = self.getImage()
        let data = UIImagePNGRepresentation(im)
        
        try? data?.write(to: filePath, options: Data.WritingOptions.atomic)
        
        return filePath
    }//save with name
    #endif
    
    override open func clone() -> GLSFrameBuffer {
        
        let copiedBuffer = GLSFrameBuffer(size: self.size)
        
        copiedBuffer.copyFromFrameBuffer(self)
        
        return copiedBuffer
        
    }//clone
    
    open func copyFromFrameBuffer(_ buffer:GLSFrameBuffer) {
        
        self.copyFromNode(buffer)
        
        self.clearColor = buffer.clearColor
        
        self.sprite.copyFromSprite(buffer.sprite)
    }//copy from buffer
    
    deinit {
        glDeleteFramebuffers(1, &framebufferName)
        glDeleteTextures(1, &internalTextureName)
    }
    
    
    //Override Properties
    
    override open var position:CGPoint {
        didSet {
            self.sprite.position = self.position
        }
    }
    override open var rotation:CGFloat {
        didSet {
            self.sprite.rotation = self.rotation
        }
    }
    override open var scaleX:CGFloat {
        didSet {
            self.sprite.scaleX = self.scaleX
        }
    }
    override open var scaleY:CGFloat {
        didSet {
            self.sprite.scaleX = self.scaleY
        }
    }
    override open var alpha:CGFloat {
        didSet {
            self.sprite.alpha = self.alpha
        }
    }
    override open var anchor:CGPoint {
        didSet {
            self.sprite.anchor = self.anchor
        }
    }
    override open var tintColor:SCVector3 {
        didSet {
            self.sprite.tintColor = self.tintColor
        }
    }
    override open var tintIntensity:SCVector3 {
        didSet {
            self.sprite.tintIntensity = self.tintIntensity
        }
    }
    override open var shadeColor:SCVector3 {
        didSet {
            self.sprite.shadeColor = self.shadeColor
        }
    }
}

//Convenience
public extension GLSFrameBuffer {
    /*
    public var shadeColor:SCVector3 {
    get { return self.sprite.shadeColor }
    set { self.sprite.shadeColor = newValue }
    }
    
    public var tintColor:SCVector3 {
    get { return self.sprite.tintColor }
    set { self.sprite.tintColor = newValue }
    }
    
    public var tintIntensity:SCVector3 {
    get { return self.sprite.tintIntensity }
    set { self.sprite.tintIntensity = newValue }
    }
    */
}//Access 'sprite's properties conveniently

//Getters / public class Functions
public extension GLSFrameBuffer {
    
    public class func isPowerOf2(_ value:Int) -> Bool {
        return (value & (value - 1)) == 0
    }
    
    public class func getValidPowerOf2(_ value:Int) -> Int {
        
        if (GLSFrameBuffer.isPowerOf2(value)) {
            return value
        }
        
        let bitCount = 8 * MemoryLayout<Int>.size
        var bitShift = 0
        for iii in 1..<bitCount {
            if (value & (1 << iii) != 0) {
                bitShift = iii
            }
        }
        
        //Add 1 to bitShift because bitShift
        //finds highest bit, so you must
        //go one higher to get a higher
        //power of 2
        return 1 << (bitShift + 1)
    }
    
    public class func getValidSize(_ size:CGSize) -> CGSize {
        return size
        /*
         *  DEPRECATED
         *
         *  Framebuffers no longer need to be powers of 2.
         *
        var width = GLSFrameBuffer.getValidPowerOf2(Int(size.width))
        var height = GLSFrameBuffer.getValidPowerOf2(Int(size.height))
        
        return CGSize(width: width, height: height)
        */
    }//check if size is valid
    
    public class func getRetinaScale() -> CGFloat {
        #if os(iOS)
            if (UIScreen.main.responds(to: #selector(getter: UIScreen.nativeScale))) {
            let nativeScale = UIScreen.main.nativeScale
            return (nativeScale > 0.0) ? nativeScale : 1.0
        } else if (UIScreen.main.responds(to: #selector(UIScreen.displayLink))) {
            //'scale' property only works correctly
            //after 'displayLinkWithTarget:selector:
            //was introduced
            return UIScreen.main.scale
        }
        return 1.0
        #else
            //Don't really know how to check for
            //retina scale value on a Mac.
            return 1.0
        #endif
    }//get retina scale
    
}
