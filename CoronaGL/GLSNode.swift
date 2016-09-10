//
//  GLSNode.swift
//  InverseKinematicsTest
//
//  Created by Cooper Knaak on 10/11/14.
//  Copyright (c) 2014 Cooper Knaak. All rights reserved.
//

import GLKit
import CoronaConvenience
import CoronaStructures

public struct UVertex: CustomStringConvertible {
    
    public var position:(GLfloat, GLfloat) = (0.0, 0.0)
    public var texture:(GLfloat, GLfloat)  = (0.0, 0.0)
    public var index:GLfloat = 0.0
    
    public var description:String {
        return "[\(index)]:\(position)-\(texture)"
    }
    public init() {
        
    }
}

public class GLSNode: NSObject {
    
    public var position:CGPoint = CGPoint(x: 0.0, y: 0.0) {
        
        didSet {
            
            if (inAnimationBlock) {
                add2Animation(oldValue, end: position) { [unowned self] in self.position = $0 }
                self.position = oldValue
            }//animate
                
            else {
                //                if (!(oldValue ~= self.position)) {
                self.modelMatrixIsDirty = true
                /*} else if (self.contentSize.width ~= 0.0 && self.contentSize.height ~= 0.0) {
                print("Old:\(oldValue) New:\(self.position) [\(self.title)]")
                }*/
            }
        }//did set
        
    }//property observers
    
    public var velocity:CGPoint = CGPoint(x: 0.0, y: 0.0) {
        
        didSet {
            if (inAnimationBlock) {
                add2Animation(oldValue, end: velocity) { [unowned self] in self.velocity = $0 }
                self.velocity = oldValue
            }//animate
            
        }//did set
        
    }//velocity observers
    
    public var rotation:CGFloat = 0.0 {
        
        didSet {
            if (inAnimationBlock) {
                add1Animation(oldValue, end: rotation) { [unowned self] in self.rotation = $0 }
                self.rotation = oldValue
            }//animate
                
            else {
                if (!(oldValue ~= self.rotation)) {
                    self.modelMatrixIsDirty = true
                }
            }
            
        }//did set
        
    }//rotation observors
    
    public var rotationVelocity:CGFloat = 0.0 {
        
        didSet {
            if (inAnimationBlock) {
                add1Animation(oldValue, end: rotationVelocity) { [unowned self] in self.rotationVelocity = $0 }
                self.rotationVelocity = oldValue
            }//animate
            
        }//did set
        
    }//rotation velocity observers
    
    public var anchor:CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            if (!(oldValue ~= self.anchor)) {
                self.modelMatrixIsDirty = true
            }
        }
    }
    
    public var scaleX:CGFloat = 1.0 {
        
        didSet {
            if (inAnimationBlock) {
                add1Animation(oldValue, end: scaleX) { [unowned self] in self.scaleX = $0 }
                self.scaleX = oldValue
            }//animate
                
            else {
                if (!(oldValue ~= self.scaleX)) {
                    self.modelMatrixIsDirty = true
                }
            }
        }//did set
        
    }//scale x observers
    
    public var scaleY:CGFloat = 1.0 {
        
        didSet {
            if (inAnimationBlock) {
                add1Animation(oldValue, end: scaleY) { [unowned self] in self.scaleY = $0 }
                self.scaleY = oldValue
            }//animate
                
            else {
                if (!(oldValue ~= self.scaleY)) {
                    self.modelMatrixIsDirty = true
                }
            }
        }//did set
        
    }//scale y observers
    
    public var scale:CGFloat {
        
        get {
            scaleY = scaleX
            return scaleX
        }//get
        
        set {
            scaleX = newValue
            scaleY = newValue
        }//set
        
    }//scale observers
    
    public var alpha:CGFloat = 1.0 {
        
        didSet {
            if (inAnimationBlock) {
                add1Animation(oldValue, end: alpha) { [unowned self] in self.alpha = $0 }
                self.alpha = oldValue
            }//animate
                
            else {
                if (!(oldValue ~= self.alpha)) {
                    self.alphaIsDirty = true
                }
            }
            
        }//did set
        
    }//alpha observors
    
    public var textureTitle:String? = "" {
        didSet {
            if let title = textureTitle {
                texture = CCTextureOrganizer.textureForString(title)
            }
        }
    }
    
    public var tintColor:SCVector3 = SCVector3() {
        didSet {
            if (inAnimationBlock) {
                add3Animation(oldValue, end: tintColor) { [unowned self] in self.tintColor = $0 }
                self.tintColor = oldValue
            } else {
                if (!(oldValue ~= self.tintColor)) {
                    self.tintColorIsDirty = true
                }
            }
        }
    }
    public var tintIntensity:SCVector3 = SCVector3() {
        didSet {
            if (inAnimationBlock) {
                add3Animation(oldValue, end: tintIntensity) { [unowned self] in self.tintIntensity = $0 }
                self.tintIntensity = oldValue
            } else {
                if (!(oldValue ~= self.tintIntensity)) {
                    self.tintIntensityIsDirty = true
                }
            }
        }
    }
    public var shadeColor:SCVector3 = SCVector3(xValue: 1.0, yValue: 1.0, zValue: 1.0) {
        didSet {
            
            if (inAnimationBlock) {
                add3Animation(oldValue, end: shadeColor) { [unowned self] in self.shadeColor = $0 }
                self.shadeColor = oldValue
            } else {
                if (!(oldValue ~= self.shadeColor)) {
                    self.shadeColorIsDirty = true
                }
            }
        }
    }
    
    public var contentSize = CGSize(width: 0.0, height: 0.0) {
        didSet {
            self.contentSizeChanged()
        }
    }
    public var frame:CGRect {
        let realSize = self.contentSize * CGSize(width: self.scaleX, height: self.scaleY)
        let xpos:CGFloat = self.position.x - realSize.width * self.anchor.x
        let ypos:CGFloat = self.position.y - realSize.height * self.anchor.y
        return CGRect(origin: CGPoint(x: xpos, y: ypos), size: realSize)
    }
    
    public var texture:CCTexture? = nil
    
    public var vertices:[UVertex] = []
    
    public static var universalProjection = SCMatrix4()
    private var internalProjection:SCMatrix4? = nil
    public var projection:SCMatrix4 {
        get {
            if let proj = self.internalProjection {
                return proj
            } else {
//                print("Invalid Projection!")
                return GLSNode.universalProjection
            }
        }
        set {
            self.internalProjection = newValue
        }
    }
    
    public var children:[GLSNode] = []
    public weak var superNode:GLSNode? = nil
    public weak var framebufferStack:GLSFramebufferStack? = nil {
        didSet {
            self.iterateChildrenRecursively() { $0.framebufferStack = self.framebufferStack }
        }
    }
    public var framebufferReference = GLSFramebufferReference()
    
    public var removeAtUpdate = false
    public var hidden = false
    public var modelMatrixAlwaysUsesRenderSelf = false
    
    public var modelMatrixIsDirty:Bool =   false { didSet { if (self.modelMatrixIsDirty) {
        //        if (!oldValue) { self.calculateRecursiveModelMatrix() }
        self.iterateChildrenRecursively() { $0.modelMatrixIsDirty = true }
        } } }
    public var alphaIsDirty:Bool =         false
    public var tintColorIsDirty:Bool =     false
    public var tintIntensityIsDirty:Bool = false
    public var shadeColorIsDirty:Bool =    false
    public var verticesAreDirty:Bool =     false
    
    public var animations:[GLSAnimator] = []
    
    public var title = ""
    
    public class var wrangleEmitters:Bool { return true }
    
    //Initialization
    override convenience init() {
        self.init(position:CGPoint(x: 0.0, y: 0.0), size:CGSize(width: 0.0, height: 0.0))
    }//default initialization
    
    public init(position:CGPoint, size:CGSize) {
        
        self.position = position
        self.contentSize = size
        
        super.init()
        
        self.loadProgram()
    }//initialize with position and size
    
    public convenience init(frame:CGRect, projection:SCMatrix4) {
        
        self.init(position:frame.center, size:frame.size)
        
    }//initialize with rectangle
    
    public func loadProgram() {
        //Subclasses should override
    }//load program
    
    //Ignores children
    public func clone() -> GLSNode {
        
        let copiedNode = GLSNode(position: self.position, size: self.contentSize)
        
        copiedNode.copyFromNode(self)
        
        //Ignore children
        
        return copiedNode
    }
    
    public func copyFromNode(node:GLSNode) {
        
        self.velocity = node.velocity
        self.rotation = node.rotation
        self.rotationVelocity = node.rotationVelocity
        self.anchor = node.anchor
        self.hidden = node.hidden
        self.alpha = node.alpha
        self.scaleX = node.scaleX
        self.scaleY = node.scaleY
        
    }//copy so 'self' is the same as 'node'
    
    //Logic
    
    public func modelMatrix(renderingSelf:Bool = true) -> SCMatrix4 {
        if (renderingSelf || self.modelMatrixAlwaysUsesRenderSelf) {
            return SCMatrix4(translation: self.position, rotation: self.rotation, scaleX: self.scaleX, scaleY: self.scaleY, anchor: self.anchor, size: self.contentSize)
        } else {
            return SCMatrix4(translation: self.position, rotation: self.rotation, scaleX: self.scaleX, scaleY: self.scaleY)
        }
        /*
        var mat = SCMatrix4()
        
        if (renderingSelf) {
        mat = mat.translateByX(-self.anchor.x * self.contentSize.width, byY: -self.anchor.y * self.contentSize.height)
        }//rendering self
        
        mat = mat.scaleByX(self.scaleX, byY: self.scaleY)
        
        mat = mat.rotate2D(self.rotation)
        
        mat = mat.translateByX(self.position.x, byY: self.position.y)
        
        return mat
        */
    }//get model matrix
    
    public func recursiveModelMatrix(renderingSelf:Bool = true) -> SCMatrix4 {
        
        if let superNode = self.superNode {
            return self.modelMatrix(renderingSelf) * superNode.recursiveModelMatrix(false)
            //            return superNode.recursiveModelMatrix(renderingSelf: false) * self.modelMatrix(renderingSelf: renderingSelf)
        } else {
            return self.modelMatrix(renderingSelf)
        }
        //        return self.storedRecursiveModelMatrix
        //        return (renderingSelf ? self.storedRecursiveModelMatrix : self.storedRecursiveModelMatrixFalse)
        /*
        var mod = self.modelMatrix(renderingSelf: renderingSelf)
        
        var currentSupernode = self.superNode
        while (currentSupernode !== nil) {
        if let cur = currentSupernode {
        mod *= cur.modelMatrix(renderingSelf: false)
        } else {
        break
        }
        
        currentSupernode = currentSupernode?.superNode
        }
        
        return mod
        */
    }//get combined model matrix
    
    public var storedRecursiveModelMatrix = SCMatrix4()
    public var storedRecursiveModelMatrixFalse = SCMatrix4()
    public func calculateRecursiveModelMatrix() {
        
        var mod = self.modelMatrix()
        //        var modFalse = self.modelMatrix(renderingSelf: false)
        
        if let superModel = self.superNode?.recursiveModelMatrix(false) {
            mod *= superModel
            //            modFalse *= superModel
        }
        
        /*
        var currentSupernode = self.superNode
        while (currentSupernode !== nil) {
        if let cur = currentSupernode {
        mod *= cur.modelMatrix(renderingSelf: false)
        } else {
        break
        }
        
        currentSupernode = currentSupernode?.superNode
        }
        */
        self.storedRecursiveModelMatrix = mod
        //        self.storedRecursiveModelMatrixFalse = modFalse
        
    }//calculate recursive model matrix
    
    //Invoke bind/unbind during rendering process
    //to allow subclasses to bind/unbind any
    //cpu-gpu bridges
    public func bind(model:SCMatrix4) {
        
    }//bind
    
    public func unbind() {
        
    }//unbind
    
    public func render(model:SCMatrix4) {
        
        if (self.hidden) {
            return
        }//hidden: don't render
        
        let childModel = modelMatrix(false) * model
        //        let childModel = model * modelMatrix(renderingSelf: false)
        
        for cur in children {
            cur.render(childModel)
        }//render children
        
    }//render
    
    public func render() {
        self.render(SCMatrix4())
    }
    
    public func update(dt:CGFloat) {
        
        self.position += velocity * dt
        self.rotation += rotationVelocity * dt
        
        var childrenToRemove:[GLSNode] = []
        for (_, cur) in self.children.enumerate() {
            
            cur.update(dt)
            
            if (cur.removeAtUpdate) {
                childrenToRemove.append(cur)
                cur.removeAtUpdate = false
            }//remove
            
        }//update children
        
        for cur in childrenToRemove {
            self.removeChild(cur)
        }//remove children
        
        self.updateAnimations(dt)
    }//update
    
    public func contentSizeChanged() {
        
    }
    
    //Children
    public func addChild(child:GLSNode) {
        self.children.append(child)
        child.superNode = self
        
        child.framebufferStack = self.framebufferStack
    }//add child
    
    public func removeChild(child:GLSNode) -> GLSNode? {
        child.superNode = nil
        return removeObject(child, fromArray:&self.children)
    }//remove child
    
    public func insertChild(child:GLSNode, atIndex index:Int) {
        
        if (index < 0 || index > self.children.count) {
            return
        }
        
        self.children.insert(child, atIndex: index)
        
        child.superNode = self
        child.framebufferStack = self.framebufferStack
        
//        self.nodeInsertedAsChild(child, atIndex: index)
    }//insert child
    
    public func bringChildToFront(child:GLSNode) {
        
        //If child is found, remove child removes
        //it and returns that child
        if let validChild = self.removeChild(child) {
            self.addChild(validChild)
        }
        
    }//bring child to front
    
    public func sendChildToBack(child:GLSNode) {
        
        //If child is found, remove child removes
        //it and returns that child
        if let validChild = self.removeChild(child) {
            self.insertChild(validChild, atIndex: 0)
        }
        
    }//send child to back
    
    // MARK: - Recursives
    
    public func iterateChildrenRecursively(closureFunction:(node:GLSNode) -> ()) {
        
        for cur in self.children {
            closureFunction(node: cur)
            cur.iterateChildrenRecursively(closureFunction)
        }//iterate through children
        
    }//iterate through all children & children's children, etc.
    
    public func iterateChildrenRecursivelyWithDepth(function:(node:GLSNode, depth:Int) -> ()) {
        self.iterateChildrenRecursivelyAtDepth(0, function: function)
    }
    
    private func iterateChildrenRecursivelyAtDepth(depth:Int, function:(node:GLSNode, depth:Int) -> ()) {
        
        for child in self.children {
            function(node: child, depth: depth)
            child.iterateChildrenRecursivelyAtDepth(depth + 1, function: function)
        }
    }
    
    public func iterateSupernodesRecursively(closureFunction:(node:GLSNode) -> ()) {
        
        closureFunction(node: self)
        
        var currentSupernode = self.superNode
        while (currentSupernode != nil) {
            closureFunction(node: currentSupernode!)
            currentSupernode = currentSupernode?.superNode
        }//loop through supernodes
        
    }//iterate through node and node's supernode and supernode's supernode, etc.
    
    ///Iterates recursively, finding last child of last child, etc., until finding the final child.
    public func recursiveLastChild() -> GLSNode? {
        
        if let lastChild = self.children.last {
            return lastChild.recursiveLastChild() ?? lastChild
        } else {
            return nil
        }
        
    }
    
    ///Finds total number of children, children's children, etc.
    public func recursiveChildrenCount() -> Int {
        var count = self.children.count
        self.iterateChildrenRecursively() { count += $0.children.count }
        
        return count
    }
    
    //Setters
    
    public func setFramebufferView(view:GLKView) {
        self.framebufferReference = GLSFramebufferReference(view: view)
    }
    
    public func setGLSFramebuffer(buffer:GLSFrameBuffer) {
        self.framebufferReference = GLSFramebufferReference(framebuffer: buffer)
    }
    
    public func setTintIntensityScalar(value:CGFloat) {
        self.tintIntensity = SCVector3(x: value, y: value, z: value)
    }
    
    public func setTintColor(color:SCVector3, intensity:CGFloat) {
        self.tintColor = color
        self.setTintIntensityScalar(intensity)
    }
    
    // MARK: - GPU Bridges
    
    private var currentTextureIndex = 0
    public func pushTexture(tex:GLuint, atLocation:GLint) {
        glUniform1i(atLocation, GLint(self.currentTextureIndex))
        glActiveTexture(GLenum(GL_TEXTURE0 + self.currentTextureIndex))
        glBindTexture(GLenum(GL_TEXTURE_2D), tex)
        self.currentTextureIndex += 1
    }
    
    public func popTextures() {
        glActiveTexture(GLenum(GL_TEXTURE0))
        self.currentTextureIndex = 0
    }
    
    
}//GLSNode

/*
*  Since many types need to be manually converted to OpenGL,
*  it's easier just to invoke these methods
*/
public extension GLSNode {
    
    public func bridgeUniform3f(location:GLint, vector:SCVector3) {
        
        glUniform3f(location, GLfloat(vector.x), GLfloat(vector.y), GLfloat(vector.z))
        
    }//glUniform3f
    
    public func bridgeUniform4f(location:GLint, vector:SCVector4) {
        
        glUniform4f(location, GLfloat(vector.x), GLfloat(vector.y), GLfloat(vector.z), GLfloat(vector.w))
        
    }//glUniform4f
    
    public func bridgeAttribute(location:GLint, size:Int, stride:Int, position:Int) {
        
        glEnableVertexAttribArray(GLuint(location))
        
        let pointer = UnsafePointer<Void>(bitPattern: sizeof(GLfloat) * position)
        glVertexAttribPointer(GLuint(location), GLint(size), GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(stride), pointer)
        
    }//bridge attribute
    
}// OpenGL + Convenience

 extension GLSNode {
    // MARK: - CustomStringConvertible
    
    public override var description:String {
        return "\(super.description) (\(self.title))"
    }
}