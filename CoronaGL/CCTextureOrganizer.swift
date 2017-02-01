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

open class CCTextureOrganizer: NSObject, XMLFileHandlerDelegate {
    
    open let identifier:String
    
    open var textures:[String:CCTexture] = [:]
    
    open var files:[String] = []
    open var directory:String? = nil
    open var parser:XMLFileHandler? = nil
    open var usingAtlases = true
    open var individualTextures:[String:GLuint] = [:]
    
    open var defaultCCTexture:CCTexture! = nil
    
    public init(identifier:String, files:[String], directory:String? = nil) {
        self.identifier = identifier
        
        self.files = files
        self.directory = directory
        
        super.init()
        
        let orgDict = CCTextureOrganizer.organizerDictionary
        orgDict.setObject(self, forKey: identifier as NSCopying)
    }//initialize
    
    public convenience init(files:[String], directory:String? = nil) {
        self.init(identifier:"", files:files, directory:directory)
    }//initialize
    
    
    open func loadTextures() {
        
        self.parser = XMLFileHandler(files: self.files, directory: self.directory, delegate: self)
        
        if let validParser = self.parser {
            #if os(iOS)
            EAGLContext.setCurrent(CCTextureOrganizer.sharedContext)
            #endif
            validParser.loadFile()
        }//valid to load
        else {
            
        }
        
    }//load textures
    
    
    open func startElement(_ elementName: String, attributes: XMLDictionary) {

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
    
    open func endElement(_ elementName: String) {
        
        if (elementName == "Atlas") {
            
            usingAtlases = true
            
        }//end atlas
        
    }//end element

    open func finishedParsing() {
        
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
    
    open func processAtlasBatch(_ attributes:[AnyHashable: Any]) {
        
        let dataStr = attributes["data"] as! NSString
        let dataComps = dataStr.components(separatedBy: ", ")
        
        let size = CGSize(width: dataComps[2].getCGFloatValue(), height: dataComps[3].getCGFloatValue())
        
        #if os(iOS)
        let tSize = CGSizeFromString(attributes["size"] as! String)
        #else
        let tSize = NSSizeFromString(attributes["size"] as! String)
        #endif
        let keyStr = attributes["keys"] as! NSString
        let keyComps = keyStr.components(separatedBy: ", ") 
        
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
    
    open func processIndividualAtlas(_ elementName:String, attributes:[AnyHashable: Any]) {
        
        if let name = individualTextures[elementName] {
            
            processPreviousIndividualAtlas(name, attributes: attributes)
            
        } else {
            
            processNewIndividualAtlas(elementName, attributes: attributes)
            
        }
        
    }//process individual texture in atlas
    
    open func processPreviousIndividualAtlas(_ name:GLuint, attributes:[AnyHashable: Any]) {
        
        let key = attributes["key"]! as! String
        #if os(iOS)
        let frame = CGRectFromString(attributes["frame"]! as! String)
        #else
        let frame = NSRectFromString(attributes["frame"]! as! String)
        #endif
        
        textures[key] = CCTexture(name: name, frame: frame)
    }//process texture that's previously been created
    
    open func processNewIndividualAtlas(_ elementName:String, attributes:[AnyHashable: Any]) {
        
        let texture = CCTextureOrganizer.createTextureWithAttributes(attributes)
        individualTextures[elementName] = texture.name
        
        /*let frame = CGRectFromString(attributes["frame"]! as String)
        let key = attributes["key"]! as String
        
        textures[key] = CCTexture(name: texture.name, frame: frame)*/
        processPreviousIndividualAtlas(texture.name, attributes: attributes)
        
    }//process texture that needs to be created
    
    
    open class func createTextureWithAttributes(_ attributes:[AnyHashable: Any]) -> GLKTextureInfo {
        
        let dataStr = attributes["data"] as! NSString
        let dataComps = dataStr.components(separatedBy: ", ")
        
        let size = CGSize(width: dataComps[2].getCGFloatValue(), height: dataComps[3].getCGFloatValue())
        
        return CCTextureOrganizer.createTexture(dataComps[0] as String, fileExtension: dataComps[1] as String, size: size)
    }//create texture with attribute dictionary
    
    open class func createTexture(_ file:String, fileExtension:String, size:CGSize) -> GLKTextureInfo {
        
        if (fileExtension == "pdf") {
            
            return createPDFTexture(file, size: size)
            
        } else/* if (fileExtension == "png")*/ {
            
            return createPNGTexture(file, size: size)
            
        }
        
    }//create texture
    
    open class func createPDFTexture(_ file:String, size:CGSize) -> GLKTextureInfo {
        #if os(iOS)
        let image = UIImage.imageWithPDFFile(file, size: size)
        let data = UIImagePNGRepresentation(image!)!
        
        let tex: GLKTextureInfo!
        do {
            tex = try GLKTextureLoader.texture(withContentsOf: data, options: [GLKTextureLoaderOriginBottomLeft:true])
        } catch {
            print(error)
            tex = nil
        }
        
        CCTextureOrganizer.configureTexture(tex)
        
        return tex
        #else
        let image = NSImage.imageWithPDFFile(file, size: size)!
        let data = image.tiffRepresentation!
        return try! GLKTextureLoader.texture(withContentsOf: data, options: [GLKTextureLoaderOriginBottomLeft:true])
        #endif
    }//create pdf texture with size
    
    open class func createPNGTexture(_ file:String, size:CGSize) -> GLKTextureInfo {
        let path:String
        if let bundlePath = Bundle.main.path(forResource: file, ofType: "png") {
            path = bundlePath
        } else {
            path = "\(file).png"
        }
        
        //Fixes crash on OS X where GLKTextureLoader
        //fails if the OpenGL error flags are still set.
        while glGetError() != GLenum(GL_NO_ERROR) {
        }
        let tex = (try? GLKTextureLoader.texture(withContentsOfFile: path, options: [GLKTextureLoaderOriginBottomLeft:true]))!
        CCTextureOrganizer.configureTexture(tex)
        
        return tex
    }//create png texture with size
    
    open class func configureTexture(_ texture:GLKTextureInfo) {
        /*
        let enumTex = GLenum(GL_TEXTURE_2D)
        glBindTexture(enumTex, texture.name)
        glTexParameteri(enumTex, GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glTexParameteri(enumTex, GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
        */
    }//configure texture so it repeats
    
    fileprivate class func pathForPNG(_ file:String) -> String? {
        let retinaFactor = GLSFrameBuffer.getRetinaScale()
        let retinaModifier:String
        if retinaFactor ~= 3.0 {
            retinaModifier = "@3x"
        } else if retinaFactor ~= 2.0 {
            retinaModifier = "@2x"
        } else {
            retinaModifier = ""
        }
        return Bundle.main.path(forResource: "\(file)\(retinaModifier)", ofType: "png")
    }
    
    open func textureForString(_ key:String) -> CCTexture? {
        return self.textures[key]
    }//get texture for string
    
    fileprivate class var organizerDictionary:NSMutableDictionary {
        struct StaticInstance {
            static let instance:NSMutableDictionary = NSMutableDictionary()
        }
        return StaticInstance.instance
    }//get dictionary that encapsulates all 'CCTextureOrganizer' instances
    
    #if os(iOS)
    open static let sharedContext:EAGLContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
    #endif
    open static let sharedInstance = CCTextureOrganizer(identifier:"Shared Instance", files: [], directory: nil)
    
    open class func textureForString(_ key:String) -> CCTexture? {
        
        let keyComponents = key.components(separatedBy: "/")
        
        if (keyComponents.count > 1) {
            
            let orgDict = CCTextureOrganizer.organizerDictionary
            
            if let textureOrganizer = orgDict.object(forKey: keyComponents[0]) as? CCTextureOrganizer {
                
                return textureOrganizer.textureForString(keyComponents[1])
                
            }//valid texture organizer
            
        } else if (keyComponents.count == 1) {
            
            return CCTextureOrganizer.sharedInstance.textureForString(keyComponents[0])
            
        }
        
        return nil
        
    }//get texture for string
    
    open class var defaultTexture:CCTexture  { return CCTextureOrganizer.sharedInstance.defaultCCTexture }
    open class var defaultName:GLuint        { return CCTextureOrganizer.defaultTexture.name }
    open class func setDefaultTexture(_ key:String) -> Bool {
        
        if let validTexture = CCTextureOrganizer.textureForString(key) {
            CCTextureOrganizer.sharedInstance.defaultCCTexture = validTexture
            return true
        } else {
            return false
        }
        
    }//set default texture
    
}//CCTextureOrganizer
