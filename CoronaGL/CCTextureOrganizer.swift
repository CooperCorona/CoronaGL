//
//  CCTextureOrganizer.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 12/10/14.
//  Copyright (c) 2014 Cooper Knaak. All rights reserved.
//

import GLKit
import CoronaConvenience
import CoronaStructures

public class CCTextureOrganizer: NSObject, XMLFileHandlerDelegate {
    
    public let identifier:String
    
    public var textures:[String:CCTexture] = [:]
    
    public var files:[String] = []
    public var directory:String? = nil
    public var parser:XMLFileHandler? = nil
    public var usingAtlases = true
    public var individualTextures:[String:GLuint] = [:]
    
    public var defaultCCTexture:CCTexture! = nil
    
    public init(identifier:String, files:[String], directory:String? = nil) {
        self.identifier = identifier
        
        self.files = files
        self.directory = directory
        
        super.init()
        
        let orgDict = CCTextureOrganizer.organizerDictionary
        orgDict.setObject(self, forKey: identifier)
    }//initialize
    
    public convenience init(files:[String], directory:String? = nil) {
        self.init(identifier:"", files:files, directory:directory)
    }//initialize
    
    
    public func loadTextures() {
        
        self.parser = XMLFileHandler(files: self.files, directory: self.directory, delegate: self)
        
        if let validParser = self.parser {
            #if os(iOS)
            EAGLContext.setCurrentContext(CCTextureOrganizer.sharedContext)
            #endif
            validParser.loadFile()
        }//valid to load
        else {
            
        }
        
    }//load textures
    
    
    public func startElement(elementName: String, attributes: XMLDictionary) {

        if (elementName == "Atlas") {
            
            usingAtlases = false
            
        } else if (elementName == "Atlases") {
            
            
            
        } else {
            
            
            if (self.usingAtlases) {
                
                self.processAtlasBatch(attributes)
                
            } else {
                
                self.processIndividualAtlas(elementName, attributes: attributes)
                
            }
            
        }
        
        
        
    }//start element
    
    public func endElement(elementName: String) {
        
        if (elementName == "Atlas") {
            
            usingAtlases = true
            
        }//end atlas
        
    }//end element

    public func finishedParsing() {
        
        for (_, texture) in self.textures {
            self.defaultCCTexture = texture
            
            //All I want is a single texture to be
            //considered default. Breaking after a
            //single iteration of a loop is the
            //easiest way to achieve this independently
            //of what the actual textures are
            break
        }
        
    }//finished parsing
    
    public func processAtlasBatch(attributes:[NSObject : AnyObject]) {
        
        let dataStr = attributes["data"] as! NSString
        let dataComps = dataStr.componentsSeparatedByString(", ")
        
        let size = CGSize(width: dataComps[2].getCGFloatValue(), height: dataComps[3].getCGFloatValue())
        
        #if os(iOS)
        let tSize = CGSizeFromString(attributes["size"] as! String)
        #else
        let tSize = NSSizeFromString(attributes["size"] as! String)
        #endif
        let keyStr = attributes["keys"] as! NSString
        let keyComps = keyStr.componentsSeparatedByString(", ") 
        
        let texture = CCTextureOrganizer.createTextureWithAttributes(attributes)
        
//        let buffer = (attributes["buffer")?.getCGFloatValue() ?? 0.0
        
        let xIterations = Int(size.width / tSize.width)
        let yIterations = Int(size.height / tSize.height)
        
        let width:CGFloat = tSize.width / size.width
        let height:CGFloat = tSize.height / size.height
        
        //Loop backwards because coordinates are flipped
        //You specify keys starting at top left
        //OpenGL starts at bottom left
        for jjj in 0..<yIterations {
            
            for iii in 0..<xIterations {
                
                let inverted_jjj = yIterations - jjj - 1
                let index = inverted_jjj * xIterations + iii
                
                if (index >= keyComps.count) {
                    break;
                }//too far
                
                let key = keyComps[index]
                
                //let frame = CGRect(x: width * iii, y: height * jjj, width: width, height: height)
                let frame = CGRect(x: width * CGFloat(iii), y: height * CGFloat(jjj), width: width, height: height)
                self.textures[key] = CCTexture(name: texture.name, frame: frame)
                
            }//loop horizontally
            
        }//loop vertically
    }//process atlas batch
    
    public func processIndividualAtlas(elementName:String, attributes:[NSObject : AnyObject]) {
        
        if let name = individualTextures[elementName] {
            
            processPreviousIndividualAtlas(name, attributes: attributes)
            
        } else {
            
            processNewIndividualAtlas(elementName, attributes: attributes)
            
        }
        
    }//process individual texture in atlas
    
    public func processPreviousIndividualAtlas(name:GLuint, attributes:[NSObject : AnyObject]) {
        
        let key = attributes["key"]! as! String
        #if os(iOS)
        let frame = CGRectFromString(attributes["frame"]! as! String)
        #else
        let frame = NSRectFromString(attributes["frame"]! as! String)
        #endif
        
        textures[key] = CCTexture(name: name, frame: frame)
    }//process texture that's previously been created
    
    public func processNewIndividualAtlas(elementName:String, attributes:[NSObject : AnyObject]) {
        
        let texture = CCTextureOrganizer.createTextureWithAttributes(attributes)
        individualTextures[elementName] = texture.name
        
        /*let frame = CGRectFromString(attributes["frame"]! as String)
        let key = attributes["key"]! as String
        
        textures[key] = CCTexture(name: texture.name, frame: frame)*/
        processPreviousIndividualAtlas(texture.name, attributes: attributes)
        
    }//process texture that needs to be created
    
    
    public class func createTextureWithAttributes(attributes:[NSObject : AnyObject]) -> GLKTextureInfo {
        
        let dataStr = attributes["data"] as! NSString
        let dataComps = dataStr.componentsSeparatedByString(", ")
        
        let size = CGSize(width: dataComps[2].getCGFloatValue(), height: dataComps[3].getCGFloatValue())
        
        return CCTextureOrganizer.createTexture(dataComps[0] as String, fileExtension: dataComps[1] as String, size: size)
    }//create texture with attribute dictionary
    
    public class func createTexture(file:String, fileExtension:String, size:CGSize) -> GLKTextureInfo {
        
        if (fileExtension == "pdf") {
            
            return createPDFTexture(file, size: size)
            
        } else/* if (fileExtension == "png")*/ {
            
            return createPNGTexture(file, size: size)
            
        }
        
    }//create texture
    
    public class func createPDFTexture(file:String, size:CGSize) -> GLKTextureInfo {
        #if os(iOS)
        let image = UIImage.imageWithPDFFile(file, size: size)
        let data = UIImagePNGRepresentation(image!)!
        
        let tex: GLKTextureInfo!
        do {
            tex = try GLKTextureLoader.textureWithContentsOfData(data, options: [GLKTextureLoaderOriginBottomLeft:true])
        } catch {
            tex = nil
        }
        
        CCTextureOrganizer.configureTexture(tex)
        
        return tex
        #else
        let image = NSImage.imageWithPDFFile(file, size: size)!
        let data = image.TIFFRepresentation!
        return try! GLKTextureLoader.textureWithContentsOfData(data, options: [GLKTextureLoaderOriginBottomLeft:true])
        #endif
    }//create pdf texture with size
    
    public class func createPNGTexture(file:String, size:CGSize) -> GLKTextureInfo {
        let path:String
        if let bundlePath = NSBundle.mainBundle().pathForResource(file, ofType: "png") {
            path = bundlePath
        } else {
            path = "\(file).png"
        }
        
        let tex = (try? GLKTextureLoader.textureWithContentsOfFile(path, options: [GLKTextureLoaderOriginBottomLeft:true]))!
        
        CCTextureOrganizer.configureTexture(tex)
        
        return tex
    }//create png texture with size
    
    public class func configureTexture(texture:GLKTextureInfo) {
        /*
        let enumTex = GLenum(GL_TEXTURE_2D)
        glBindTexture(enumTex, texture.name)
        glTexParameteri(enumTex, GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glTexParameteri(enumTex, GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
        */
    }//configure texture so it repeats
    
    private class func pathForPNG(file:String) -> String? {
        let retinaFactor = GLSFrameBuffer.getRetinaScale()
        let retinaModifier:String
        if retinaFactor ~= 3.0 {
            retinaModifier = "@3x"
        } else if retinaFactor ~= 2.0 {
            retinaModifier = "@2x"
        } else {
            retinaModifier = ""
        }
        return NSBundle.mainBundle().pathForResource("\(file)\(retinaModifier)", ofType: "png")
    }
    
    public func textureForString(key:String) -> CCTexture? {
        return self.textures[key]
    }//get texture for string
    
    private class var organizerDictionary:NSMutableDictionary {
        struct StaticInstance {
            static let instance:NSMutableDictionary = NSMutableDictionary()
        }
        return StaticInstance.instance
    }//get dictionary that encapsulates all 'CCTextureOrganizer' instances
    
    #if os(iOS)
    public class var sharedContext:EAGLContext {
        
        struct StaticInstance {
            //            static let instance = EAGLContext(API:EAGLRenderingAPI.OpenGLES2)
            static var instance:EAGLContext! = nil
            static var onceToken:dispatch_once_t = 0
        }
        
        dispatch_once(&StaticInstance.onceToken) {
            StaticInstance.instance = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        }
        
        return StaticInstance.instance
    }//get main context
    #endif
    public class var sharedInstance:CCTextureOrganizer {
        struct StaticInstance {
            static let instance:CCTextureOrganizer = CCTextureOrganizer(identifier:"Shared Instance", files: [], directory: nil)
        }
        return StaticInstance.instance
    }//get singleton
    
    public class func textureForString(key:String) -> CCTexture? {
        
        let keyComponents = key.componentsSeparatedByString("/")
        
        if (keyComponents.count > 1) {
            
            let orgDict = CCTextureOrganizer.organizerDictionary
            
            if let textureOrganizer = orgDict.objectForKey(keyComponents[0]) as? CCTextureOrganizer {
                
                return textureOrganizer.textureForString(keyComponents[1])
                
            }//valid texture organizer
            
        } else if (keyComponents.count == 1) {
            
            return CCTextureOrganizer.sharedInstance.textureForString(keyComponents[0])
            
        }
        
        return nil
        
    }//get texture for string
    
    public class var defaultTexture:CCTexture  { return CCTextureOrganizer.sharedInstance.defaultCCTexture }
    public class var defaultName:GLuint        { return CCTextureOrganizer.defaultTexture.name }
    public class func setDefaultTexture(key:String) -> Bool {
        
        if let validTexture = CCTextureOrganizer.textureForString(key) {
            CCTextureOrganizer.sharedInstance.defaultCCTexture = validTexture
            return true
        } else {
            return false
        }
        
    }//set default texture
    
}//CCTextureOrganizer
