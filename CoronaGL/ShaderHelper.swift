//
//  ShaderHelper.swift
//  InverseKinematicsTest
//
//  Created by Cooper Knaak on 10/13/14.
//  Copyright (c) 2014 Cooper Knaak. All rights reserved.
//

import GLKit

open class ShaderHelper : NSObject {

    // MARK: - Shared Instance
    open class var sharedInstance : ShaderHelper {
        struct Static {
            static let instance:ShaderHelper = ShaderHelper()
        }//static instance
        return Static.instance
    }//shared instance class
    
    // MARK: - Properties
    
    open var programs:[String:GLuint] = [:]
    fileprivate(set) open var programDictionaries:[String:GLProgramDictionary] = [:]
    fileprivate(set) open var isLoaded = false
    
    // MARK: - Setup
    
    override init() {

    }
    
    // MARK: - Logic
    
    open func loadPrograms(_ dict:[String:String]) {
        
        for (key, file) in dict {
            if let vshURL = Bundle.main.url(forResource: file, withExtension: "vsh"),
            let fshURL = Bundle.main.url(forResource: file, withExtension: "fsh") {
                let program = buildProgramVertexURL(vshURL, fragmentURL: fshURL)
                programs[key] = program
                programDictionaries[key] = self.createProgramDictionary(program, vertexURL: vshURL, fragmentURL: fshURL)
            }
        }//create shaders
        
        self.isLoaded = true
    }//load programs
    
    ///Gets all *.vsh* and *.fsh* files from the OmniSwift bundle and loads them.
    open func loadProgramsFromBundle() {
        /*
        var vshDict:[String:NSURL] = [:]
        var fshDict:[String:NSURL] = [:]
        */
        #if os(iOS)
        EAGLContext.setCurrent(CCTextureOrganizer.sharedContext)
        #else
//        GLSFrameBuffer.globalContext.makeCurrentContext()
        #endif
        var basePaths:[String:String] = [:]
        var vshURLs:[String:URL] = [:]
        var fshURLs:[String:URL] = [:]
        if let resourcePath = Bundle.main.resourcePath,
        let enumerator = FileManager.default.enumerator(atPath: resourcePath) {
            while let currentPath = enumerator.nextObject() as? String {
                if let (key, path) = self.keyAndPathForPath(currentPath) {
                    basePaths[key] = path
                    if currentPath.hasSuffix(".vsh") {
                        vshURLs[key] = URL(fileURLWithPath: "\(resourcePath)/\(currentPath)")
                    } else if currentPath.hasSuffix(".fsh") {
                        fshURLs[key] = URL(fileURLWithPath: "\(resourcePath)/\(currentPath)")
                    }
                }
            }
                
        }
        for (key, path) in basePaths {
//            let vshURL = NSURL(fileURLWithPath: resourcePath + "/\(path).vsh")
//            let fshURL = NSURL(fileURLWithPath: resourcePath + "/\(path).fsh")
            guard let vshURL = vshURLs[key], let fshURL = fshURLs[key] else {
                print("Error: Failed to load shader (\(key)).")
                continue
            }
            let program = self.buildProgramVertexURL(vshURL, fragmentURL: fshURL)
            self.programs[key] = program
            
            self.programDictionaries[key] = self.createProgramDictionary(program, vertexURL: vshURL, fragmentURL: fshURL)
        }
        /*
        let frames = NSBundle.allFrameworks().filter() { $0.bundlePath.hasSuffix(("CoronaGL.framework")) }
        for frame in [frames[0], NSBundle.mainBundle()] {
            var basePaths:[String:String] = [:]
            guard let resourcePath = frame.resourcePath else {
                return
            }
            print(resourcePath)
            if let enumerator = NSFileManager.defaultManager().enumeratorAtPath(resourcePath) {
                while let currentPath = enumerator.nextObject() as? String {
                    if currentPath.containsString("Frameworks/") {
                        //Since the main bundle's enumerator includes the CoronaGL framework as
                        //a subdirectory, it tries to load all the shaders again, but the
                        //keyAndPathForPath method strips all the extra information, so
                        //it tries to load them from the project's own resource path, crashing
                        //the app. We just ignore the CoronaGL framework (and other frameworks,
                        //in case they contain shaders
                        continue
                    }
                    print("\t\(currentPath)")
                    if let (key, path) = self.keyAndPathForPath(currentPath) {
                        print("\t\(currentPath)")
                        basePaths[key] = path
                    }
                }
                
            }
            for (key, path) in basePaths {
                let vshURL = NSURL(fileURLWithPath: resourcePath + "/\(path).vsh")
                let fshURL = NSURL(fileURLWithPath: resourcePath + "/\(path).fsh")
                let program = self.buildProgramVertexURL(vshURL, fragmentURL: fshURL)
                self.programs[key] = program
                
                self.programDictionaries[key] = self.createProgramDictionary(program, vertexURL: vshURL, fragmentURL: fshURL)
            }
        }
        */
        /*
        let bundle = NSBundle(forClass: ShaderHelper.self)
        
        let frames = NSBundle.allFrameworks().filter() { $0.bundlePath.hasSuffix(("OmniSwift.framework")) }
        guard let resourcePath = frames.objectAtIndex(0)?.resourcePath else {
            return
        }
        for (key, path) in basePaths {
            let vshURL = NSURL(fileURLWithPath: resourcePath + "/\(path).vsh")
            let fshURL = NSURL(fileURLWithPath: resourcePath + "/\(path).fsh")
            let program = self.buildProgramVertexURL(vshURL, fragmentURL: fshURL)
            self.programs[key] = program
            self.programDictionaries[key] = self.createProgramDictionary(program, vertexURL: vshURL, fragmentURL: fshURL)
        }
        */
    }
    
    fileprivate func keyAndPathForPath(_ path:String) -> (key:String, path:String)? {
        let baseFilePaths = path.components(separatedBy: "/").last!.components(separatedBy: ".")
        guard baseFilePaths.count >= 2 && (baseFilePaths[1] == "vsh" || baseFilePaths[1] == "fsh") else {
            return nil
        }
        let filePath = baseFilePaths[0]
        let key = filePath.convertCamelCaseToSpaces()
        return (key, filePath)
    }
    
    open func buildProgramVertexURL(_ vshURL:URL, fragmentURL fshURL:URL) -> GLuint {
        let program = glCreateProgram()

        let vertexShader = self.buildShader(vshURL, shaderType: GLenum(GL_VERTEX_SHADER))
        let fragmentShader = self.buildShader(fshURL, shaderType: GLenum(GL_FRAGMENT_SHADER))
        
        glAttachShader(program, vertexShader)
        glAttachShader(program, fragmentShader)
        
        glLinkProgram(program)
    
        return program
    }//create program
    
    open func buildShader(_ url:URL, shaderType:GLenum) -> GLuint {
        
        #if os(iOS)
        let data = try? String(contentsOf: url, encoding: String.Encoding.utf8)
        var text:UnsafePointer<GLchar>? = (data! as NSString).utf8String!

        let source = withUnsafePointer(to: &text) { (pointer:UnsafePointer<UnsafePointer<GLchar>?>) -> GLuint in
            let sourceValue = glCreateShader(shaderType)
            glShaderSource(sourceValue, 1, pointer, nil)
            glCompileShader(sourceValue)
            return sourceValue
        }
        #else
        let data = try? String(contentsOf: url, encoding: String.Encoding.ascii)
        let cSource = data!.cString(using: String.Encoding.ascii)
        var text:UnsafePointer<GLchar>? = UnsafePointer<GLchar> (cSource!)
        let source = glCreateShader(shaderType)
        var length = GLint(data!.characters.count)
        glShaderSource(source, 1, &text, &length)
        glCompileShader(source)
        #endif
        
        var logLength:GLint = 0
        glGetShaderiv(source, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if (logLength > 0)
        {//valid log
            var ump = Array<GLchar>(repeating: 0, count: Int(logLength))
            glGetShaderInfoLog(source, logLength, &logLength, &ump)
            let str = String(validatingUTF8: ump)
            print("Shader Log:\(str!)")
        }//valid log
        
        var status:GLint = 0
        glGetShaderiv(source, GLenum(GL_COMPILE_STATUS), &status)
        if (status != GL_TRUE)
        {//invalid
            let error = glGetError()
            print("\(url)--Error:\(error)--Status:\(status)")
        }//invalid
        
        return source
    }//create shader
    
    fileprivate func createProgramDictionary(_ program:GLuint, vertexURL vshURL:URL, fragmentURL fshURL:URL) -> GLProgramDictionary? {
        guard let vshData = try? String(contentsOf: vshURL, encoding: String.Encoding.ascii),
            let fshData = try? String(contentsOf: fshURL, encoding: String.Encoding.ascii) else {
                return nil
        }
        return GLProgramDictionary(program: program, vertexShader: vshData, fragmentShader: fshData)
    }
    
    open class func programDictionaryForString(_ key:String) -> GLProgramDictionary? {
        return ShaderHelper.sharedInstance.programDictionaries[key]
    }
    
    open subscript(index:String) -> GLuint? {
        if let program = self.programs[index] {
            return program
        } else {
            print("ShaderHelper: \(index) does not exist!")
            return nil
        }
    }//get program for string
    
    open class func programForString(_ key:String) -> GLuint? {
        return ShaderHelper.sharedInstance[key]
    }//get program for string
    
//Logic
    
    
}//shader helper
