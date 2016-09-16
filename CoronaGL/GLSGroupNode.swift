//
//  GLSGroupNode.swift
//  Gravity
//
//  Created by Cooper Knaak on 4/3/15.
//  Copyright (c) 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaStructures

/** Defines a node that exists only
to have other nodes as children. It
is optimized to not calculate its
model matrix, etc. so you don't lose
performance.
*/
open class GLSGroupNode: GLSNode {
    /* Also overrides tintColor,
    tintIntensity, and shadeColor setters
    to recursively set children when
    the properties change.
    override public var tintColor:SCVector3 {
        didSet {
            self.iterateChildrenRecursively() { [unowned self] in $0.tintColor = self.tintColor }
        }
    }
    override public var tintIntensity:SCVector3 {
        didSet {
            self.iterateChildrenRecursively() { [unowned self] in $0.tintIntensity = self.tintIntensity }
        }
    }
    override public var shadeColor:SCVector3 {
        didSet {
            self.iterateChildrenRecursively() { [unowned self] in $0.shadeColor = self.shadeColor }
        }
    }
    */
    public init(title:String = "") {
        
        super.init(position: CGPoint.zero, size: CGSize.zero)
        
        self.title = title
        
    }//initialize
    
    override open func modelMatrix(_ renderingSelf: Bool = true) -> SCMatrix4 {
        return SCMatrix4()
    }
    
    override open func recursiveModelMatrix(_ renderingSelf: Bool = true) -> SCMatrix4 {
        return super.recursiveModelMatrix(renderingSelf)
    }//recursive model matrix
    
}
