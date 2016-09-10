//
//  GLSRecursivePropertyNode.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 10/27/15.
//  Copyright © 2015 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaStructures

/**
 A subclass of GLSNode that overrides property
 observers that recursively sets the
 properties same of children.
*/
public class GLSRecursivePropertyNode: GLSNode {
    
    override public var hidden:Bool {
        didSet {
            self.iterateChildrenRecursively() { [unowned self] in $0.hidden = self.hidden }
        }
    }
    
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
    
    override public var alpha:CGFloat {
        didSet {
            self.iterateChildrenRecursively() { [unowned self] in $0.alpha = self.alpha }
        }
    }
    
}
