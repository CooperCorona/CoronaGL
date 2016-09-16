//
//  GLSTileSprite.swift
//  OmniSwift
//
//  Created by Cooper Knaak on 3/26/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import CoronaConvenience

///Tiles a texture across the entire sprite.
///Does not (cannot) take into account textures in atlases.
///Thus, it assumes the texture is mapped 0.0 - 1.0 on x and y.
open class GLSTileSprite: GLSSprite {

    // MARK: - Properties
    
    open var textureSize:CGSize = CGSize(square: 1.0) {
        didSet {
            self.setTextureOfVertices()
        }
    }
    
    // MARK: - Setup
    
    public init(size:CGSize, textureSize:CGSize, texture:CCTexture?) {
        self.textureSize = textureSize
        super.init(position: CGPoint.zero, size: size, texture: texture)
        self.setTextureOfVertices()
    }
    
    // MARK: - Logic
    
    open override func contentSizeChanged() {
        super.contentSizeChanged()
        self.setTextureOfVertices()
    }
    
    open func setTextureOfVertices() {

        let verts = TexturedQuadVertices(vertices: self.vertices)
        verts.iterateWithHandler() { index, vertex in
            let point = TexturedQuad.pointForIndex(index)
            vertex.texture = (point * (self.contentSize / self.textureSize)).getGLTuple()
        }
        self.vertices = verts.vertices
    }
}
