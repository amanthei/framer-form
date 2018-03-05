require '../lib/OBJLoader.js'
require '../lib/MTLLoader.js'
{BaseClass} = require './BaseClass.coffee'
{Animation} = require './Animation.coffee'
{Mesh} = require './Mesh.coffee'

class exports.Model extends BaseClass
    constructor: (properties={}) ->
        super()
        switch @getExtension properties.path
            when 'obj'
                @loadObj properties, (model) =>
                    @mesh = model

                    @boundingBox = new THREE.Box3().setFromObject @mesh
                    @boundingBox.getCenter(@mesh.position)
                    @mesh.position.multiplyScalar -1

                    @pivot = new THREE.Group
                    @pivot.add @mesh

                    @setupModel properties

    getExtension: (path) ->
        path.split('.').pop()

    loadObj: (properties, cb) ->
        @loader = new THREE.OBJLoader
        # @loader.setMaterials materials
        @loader.load properties.path, (obj) ->
            cb obj

    setupModel: (properties) ->
        if properties.material
            @applyMaterial properties.material
        
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
        get: -> @pivot.scale,
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
        get: -> @pivot.rotation.x,
        set: (x) -> @pivot.rotation.x = THREE.Math.degToRad(x)
    
    @define 'rotationY',
        get: -> @pivot.rotation.y,
        set: (y) -> @pivot.rotation.y = THREE.Math.degToRad(y)
    
    @define 'rotationZ',
        get: -> @pivot.rotation.z,
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