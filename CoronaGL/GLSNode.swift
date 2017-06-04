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

open class GLSNode: NSObject, GLSAnimatable {
    
    open var position:CGPoint = CGPoint(x: 0.0, y: 0.0) {
        
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
    
    open var velocity:CGPoint = CGPoint(x: 0.0, y: 0.0) {
        
        didSet {
            if (inAnimationBlock) {
                add2Animation(oldValue, end: velocity) { [unowned self] in self.velocity = $0 }
                self.velocity = oldValue
            }//animate
            
        }//did set
        
    }//velocity observers
    
    open var rotation:CGFloat = 0.0 {
        
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
    
    open var rotationVelocity:CGFloat = 0.0 {
        
        didSet {
            if (inAnimationBlock) {
                add1Animation(oldValue, end: rotationVelocity) { [unowned self] in self.rotationVelocity = $0 }
                self.rotationVelocity = oldValue
            }//animate
            
        }//did set
        
    }//rotation velocity observers
    
    open var anchor:CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            if (!(oldValue ~= self.anchor)) {
                self.modelMatrixIsDirty = true
            }
        }
    }
    
    open var scaleX:CGFloat = 1.0 {
        
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
    
    open var scaleY:CGFloat = 1.0 {
        
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
    
    open var scale:CGFloat {
        
        get {
            scaleY = scaleX
            return scaleX
        }//get
        
        set {
            scaleX = newValue
            scaleY = newValue
        }//set
        
    }//scale observers
    
    open var alpha:CGFloat = 1.0 {
        
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
    
    open var textureTitle:String? = "" {
        didSet {
            if let title = textureTitle {
                texture = CCTextureOrganizer.textureForString(title)
            }
        }
    }
    
    open var tintColor:SCVector3 = SCVector3() {
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
    open var tintIntensity:SCVector3 = SCVector3() {
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
    open var shadeColor:SCVector3 = SCVector3(xValue: 1.0, yValue: 1.0, zValue: 1.0) {
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
    
    open var contentSize = CGSize(width: 0.0, height: 0.0) {
        didSet {
            self.contentSizeChanged()
        }
    }
    open var frame:CGRect {
        let realSize = self.contentSize * CGSize(width: self.scaleX, height: self.scaleY)
        let xpos:CGFloat = self.position.x - realSize.width * self.anchor.x
        let ypos:CGFloat = self.position.y - realSize.height * self.anchor.y
        return CGRect(origin: CGPoint(x: xpos, y: ypos), size: realSize)
    }
    
    open var texture:CCTexture? = nil
    
    open var vertices:[UVertex] = []
    
    open static var universalProjection = SCMatrix4()
    fileprivate var internalProjection:SCMatrix4? = nil
    open var projection:SCMatrix4 {
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
    
    open var children:[GLSNode] = []
    open weak var superNode:GLSNode? = nil
    open weak var framebufferStack:GLSFramebufferStack? = nil {
        didSet {
            self.iterateChildrenRecursively() { $0.framebufferStack = self.framebufferStack }
        }
    }
//    public var framebufferReference = GLSFramebufferReference()
    open var removeAtUpdate = false
    open var hidden = false
    open var modelMatrixAlwaysUsesRenderSelf = false
    
    open var modelMatrixIsDirty:Bool =   false { didSet { if (self.modelMatrixIsDirty) {
        //        if (!oldValue) { self.calculateRecursiveModelMatrix() }
        self.iterateChildrenRecursively() { $0.modelMatrixIsDirty = true }
        } } }
    open var alphaIsDirty:Bool =         false
    open var tintColorIsDirty:Bool =     false
    open var tintIntensityIsDirty:Bool = false
    open var shadeColorIsDirty:Bool =    false
    open var verticesAreDirty:Bool =     false
    
    open var animations:[GLSAnimator] = []
    
    open var title = ""
    
    open class var wrangleEmitters:Bool { return true }
    
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
    
    open func loadProgram() {
        //Subclasses should override
    }//load program
    
    //Ignores children
    open func clone() -> GLSNode {
        
        let copiedNode = GLSNode(position: self.position, size: self.contentSize)
        
        copiedNode.copyFromNode(self)
        
        //Ignore children
        
        return copiedNode
    }
    
    open func copyFromNode(_ node:GLSNode) {
        
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
    
    open func modelMatrix(_ renderingSelf:Bool = true) -> SCMatrix4 {
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
    
    open func recursiveModelMatrix(_ renderingSelf:Bool = true) -> SCMatrix4 {
        
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
    
    open var storedRecursiveModelMatrix = SCMatrix4()
    open var storedRecursiveModelMatrixFalse = SCMatrix4()
    open func calculateRecursiveModelMatrix() {
        
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
    open func bind(_ model:SCMatrix4) {
        
    }//bind
    
    open func unbind() {
        
    }//unbind
    
    open func render(_ model:SCMatrix4) {
        
        if (self.hidden) {
            return
        }//hidden: don't render
        
        let childModel = modelMatrix(false) * model
        //        let childModel = model * modelMatrix(renderingSelf: false)
        
        for cur in children {
            cur.render(childModel)
        }//render children
        
    }//render
    
    open func render() {
        self.render(SCMatrix4())
    }
    
    open func update(_ dt:CGFloat) {
        
        self.position += velocity * dt
        self.rotation += rotationVelocity * dt
        
        var childrenToRemove:[GLSNode] = []
        for (_, cur) in self.children.enumerated() {
            
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
    
    open func contentSizeChanged() {
        
    }
    
    // MARK: - Children
    open func addChild(_ child:GLSNode) {
        self.children.append(child)
        child.superNode = self
        
        child.framebufferStack = self.framebufferStack
    }//add child
    
    open func removeChild(_ child:GLSNode) -> GLSNode? {
        child.superNode = nil
        return removeObject(child, fromArray:&self.children)
    }//remove child
    
    open func insertChild(_ child:GLSNode, atIndex index:Int) {
        
        if (index < 0 || index > self.children.count) {
            return
        }
        
        self.children.insert(child, at: index)
        
        child.superNode = self
        child.framebufferStack = self.framebufferStack
        
//        self.nodeInsertedAsChild(child, atIndex: index)
    }//insert child
    
    open func bringChildToFront(_ child:GLSNode) {
        
        //If child is found, remove child removes
        //it and returns that child
        if let validChild = self.removeChild(child) {
            self.addChild(validChild)
        }
        
    }//bring child to front
    
    open func sendChildToBack(_ child:GLSNode) {
        
        //If child is found, remove child removes
        //it and returns that child
        if let validChild = self.removeChild(child) {
            self.insertChild(validChild, atIndex: 0)
        }
        
    }//send child to back
    
    // MARK: - Recursives
    
    open func iterateChildrenRecursively(_ closureFunction:(_ node:GLSNode) -> ()) {
        
        for cur in self.children {
            closureFunction(cur)
            cur.iterateChildrenRecursively(closureFunction)
        }//iterate through children
        
    }//iterate through all children & children's children, etc.
    
    open func iterateChildrenRecursivelyWithDepth(_ function:(_ node:GLSNode, _ depth:Int) -> ()) {
        self.iterateChildrenRecursivelyAtDepth(0, function: function)
    }
    
    fileprivate func iterateChildrenRecursivelyAtDepth(_ depth:Int, function:(_ node:GLSNode, _ depth:Int) -> ()) {
        
        for child in self.children {
            function(child, depth)
            child.iterateChildrenRecursivelyAtDepth(depth + 1, function: function)
        }
    }
    
    open func iterateSupernodesRecursively(_ closureFunction:(_ node:GLSNode) -> ()) {
        
        closureFunction(self)
        
        var currentSupernode = self.superNode
        while (currentSupernode != nil) {
            closureFunction(currentSupernode!)
            currentSupernode = currentSupernode?.superNode
        }//loop through supernodes
        
    }//iterate through node and node's supernode and supernode's supernode, etc.
    
    ///Iterates recursively, finding last child of last child, etc., until finding the final child.
    open func recursiveLastChild() -> GLSNode? {
        
        if let lastChild = self.children.last {
            return lastChild.recursiveLastChild() ?? lastChild
        } else {
            return nil
        }
        
    }
    
    ///Finds total number of children, children's children, etc.
    open func recursiveChildrenCount() -> Int {
        var count = self.children.count
        self.iterateChildrenRecursively() { count += $0.children.count }
        
        return count
    }
    
    //Setters
    /*
    public func setFramebufferView(view:GLKView) {
        self.framebufferReference = GLSFramebufferReference(view: view)
    }
    
    public func setGLSFramebuffer(buffer:GLSFrameBuffer) {
        self.framebufferReference = GLSFramebufferReference(framebuffer: buffer)
    }
    */
    open func setTintIntensityScalar(_ value:CGFloat) {
        self.tintIntensity = SCVector3(x: value, y: value, z: value)
    }
    
    open func setTintColor(_ color:SCVector3, intensity:CGFloat) {
        self.tintColor = color
        self.setTintIntensityScalar(intensity)
    }
    
    /**
    Changes the anchor and the position such that
    the sprite will appear unmoved.
     - parameter anchor: The new anchor.
     */
    open func move(anchor:CGPoint) {
        let origin = self.position - self.anchor * self.contentSize
        self.position = origin + anchor * self.contentSize
        self.anchor = anchor
    }
    
    // MARK: - GPU Bridges
    
    fileprivate var currentTextureIndex = 0
    open func pushTexture(_ tex:GLuint, atLocation:GLint) {
        glUniform1i(atLocation, GLint(self.currentTextureIndex))
        glActiveTexture(GLenum(GL_TEXTURE0 + Int32(self.currentTextureIndex)))
        glBindTexture(GLenum(GL_TEXTURE_2D), tex)
        self.currentTextureIndex += 1
    }
    
    open func popTextures() {
        glActiveTexture(GLenum(GL_TEXTURE0))
        self.currentTextureIndex = 0
    }
    
    // MARK: - Handling Animations
    
    public func updateAnimations(_ dt:CGFloat) {
        
        var indicesToRemove:[Int] = []
        
        for iii in 0..<self.animations.count {
            
            self.animations[iii].update(dt)
            
            if (self.animations[iii].isFinished) {
                self.animations[iii].endAnimation()
                indicesToRemove.append(iii)
            }//finished
            
        }//check if finished
        
        let count = indicesToRemove.count
        for i in 0..<count {
            let j = count - i - 1
            self.animations.remove(at: indicesToRemove[j])
        }//remove animations
        
    }//update animations
    
    public func stopAnimations() {
        self.animations.removeAll(keepingCapacity: false)
    }//stop animations from animating
    
    
}//GLSNode

/*
*  Since many types need to be manually converted to OpenGL,
*  it's easier just to invoke these methods
*/
public extension GLSNode {
    
    public func bridgeUniform3f(_ location:GLint, vector:SCVector3) {
        
        glUniform3f(location, GLfloat(vector.x), GLfloat(vector.y), GLfloat(vector.z))
        
    }//glUniform3f
    
    public func bridgeUniform4f(_ location:GLint, vector:SCVector4) {
        
        glUniform4f(location, GLfloat(vector.x), GLfloat(vector.y), GLfloat(vector.z), GLfloat(vector.w))
        
    }//glUniform4f
    
    public func bridgeAttribute(_ location:GLint, size:Int, stride:Int, position:Int) {
        
        glEnableVertexAttribArray(GLuint(location))
        
        let pointer = UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * position)
        glVertexAttribPointer(GLuint(location), GLint(size), GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(stride), pointer)
        
    }//bridge attribute
    
}// OpenGL + Convenience

 extension GLSNode {
    // MARK: - CustomStringConvertible
    
    open override var description:String {
        return "\(super.description) (\(self.title))"
    }
}
