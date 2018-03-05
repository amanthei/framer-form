_ = Framer._

require '../lib/OBJLoader.js'
require '../lib/MTLLoader.js'

require '../lib/FBXLoader.js'


window.Zlib = require('../lib/inflate.min.js').Zlib

{BaseClass} = require './BaseClass.coffee'
{Animation} = require './Animation.coffee'
{Mesh} = require './Mesh.coffee'

class exports.Model extends BaseClass
    constructor: (properties={}) ->
        super()

        switch @getExtension properties.path
            when 'obj'
                new OBJ properties, (model) =>
                    @mesh = model
                    @setupModel properties
            when 'fbx'
                new FBX properties, (model) =>
                    @mesh = model
                    @setupModel properties


    getExtension: (path) ->
        path.split('.').pop()

    setupModel: (properties) ->
        @boundingBox = new THREE.Box3().setFromObject @mesh
        @boundingBox.getCenter(@mesh.position)
        @mesh.position.multiplyScalar -1

        @pivot = new THREE.Group
        @pivot.add @mesh

        if properties.material
            @applyMaterial properties.material
        
        if properties.smoothShading
            @mesh.traverse (c) ->
                if c instanceof THREE.Mesh
                    c.material.shading = THREE.SmoothShading
        
        if properties.parent
            @addToRenderingInstance properties.parent

        @setScale properties.scale, properties.scaleX, properties.scaleY, properties.scaleZ
        @setPosition [properties.x, properties.y, properties.z]
        @setRotation [properties.rotationX, properties.rotationY, properties.rotationZ]
        
        if properties.visible
            @visible = properties.visible

        if properties.onLoad
            properties.onLoad @

    applyMaterial: (material) ->
        @mesh.traverse (c) ->
            if c instanceof THREE.Mesh
                c.material = material

    addToRenderingInstance: (parent) ->
        if parent.scene then parent.scene.add @pivot
        else parent.add @pivot
    
    on: (eventName, cb) ->
        @mesh.traverse (c) ->
            if c instanceof THREE.Mesh
                c.addEventListener eventName, cb


    setScale: (uniformScale, scaleX, scaleY, scaleZ) ->
        if uniformScale
            @scale = uniformScale || 1
        else
            @scaleX = scaleX || 1
            @scaleY = scaleY || 1
            @scaleZ = scaleZ || 1
    
    setPosition: (position) ->
        @x = position[0] || 0
        @y = position[1] || 0
        @z = position[2] || 0

    setRotation: (rotation) ->
        @rotationX = rotation[0] || 0
        @rotationY = rotation[1] || 0
        @rotationZ = rotation[2] || 0
    
    animate: (properties) ->
        new Animation @, properties

    @define 'scale',
        get: -> @pivot.scale.x,
        set: (scale) -> @pivot.scale.set(scale, scale, scale)
    
    @define 'scaleX',
        get: -> @pivot.scale.x,
        set: (scale) -> @pivot.scale.set(scale, @pivot.scale.y, @pivot.scale.z)

    @define 'scaleY',
        get: -> @pivot.scale.y,
        set: (scale) -> @pivot.scale.set(@pivot.scale.x, scale, @pivot.scale.z)
    
    @define 'scaleZ',
        get: -> @pivot.scale.z,
        set: (scale) -> @pivot.scale.set(@pivot.scale.x, @pivot.scale.y, scale)

    @define 'x',
        get: -> @pivot.position.x,
        set: (x) -> @pivot.position.x = x
    
    @define 'y',
        get: -> @pivot.position.y,
        set: (y) -> @pivot.position.y = y
    
    @define 'z',
        get: -> @pivot.position.z,
        set: (z) -> @pivot.position.z = z

    @define 'rotationX',
        get: -> THREE.Math.radToDeg(@pivot.rotation.x),
        set: (x) -> @pivot.rotation.x = THREE.Math.degToRad(x)
    
    @define 'rotationY',
        get: -> THREE.Math.radToDeg(@pivot.rotation.y),
        set: (y) -> @pivot.rotation.y = THREE.Math.degToRad(y)
    
    @define 'rotationZ',
        get: -> THREE.Math.radToDeg(@pivot.rotation.z),
        set: (z) -> @pivot.rotation.z = THREE.Math.degToRad(z)
    
    @define 'parent',
        get: -> @pivot.parent,
        set: (parent) -> @pivot.parent = parent
    
    @define 'visible',
        get: -> @pivot.visible
        set: (bool) -> @pivot.visible = bool
    
    @define 'children',
        get: -> @pivot.children
    
    @define 'size',
        get: -> {
            height: @boundingBox.max.y - @boundingBox.min.y
            width: @boundingBox.max.x - @boundingBox.min.x
            depth: @boundingBox.max.z - @boundingBox.min.z
        }





class OBJ
    constructor: (properties, cb) ->
        path = properties.path
        @dirPath = path.substring 0, path.indexOf(path.split('/').pop())
        @modelPath = path.split('/').pop()
        @materialPath = @modelPath.replace '.obj', '.mtl'
        
        @materialLoader = new THREE.MTLLoader
        @modelLoader = new THREE.OBJLoader

        @materialLoader.setPath @dirPath
        @materialLoader.load @materialPath, (materials) =>
            materials.preload()

            @modelLoader.setMaterials materials
            @modelLoader.setPath @dirPath
            @modelLoader.load @modelPath, (model) =>
                cb model

class FBX
    constructor: (properties, cb) ->
        path = properties.path
        @modelLoader = new THREE.FBXLoader
        @clock = new THREE.Clock

        @modelLoader.load path, (model) =>
            

            model.mixer = new THREE.AnimationMixer model

            action = model.mixer.clipAction model.animations[0]
            action.play()

            
            updateMixer = () =>
                requestAnimationFrame updateMixer
                model.mixer.update @clock.getDelta()
        
            updateMixer()

            cb model