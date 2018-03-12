{Scene, Studio, Model, MeshPhongMaterial} = require '../form.coffee'

scene = new Studio
	width: Screen.width
	height: Screen.height
	camera:
		orbitControls: true

new Model
	path: './models/flamingo/flamingo.json'
	parent: scene
	scale: 1
	rotationY: -40
	material: new MeshPhongMaterial
		color: 0xffffff
		specular: 0xffffff
		shininess: 20
		morphTargets: true
		vertexColors: FORM.FaceColors
		flatShading: true
	onLoad: (model) ->

		scene.camera.controls.target = model.position
		scene.camera.controls.autoRotate = true
		
		clock = new FORM.Clock

		scene.on Events.Pan, (e) ->
			model.rotationY += e.deltaX * 0.3

		scene.animationLoop = () ->
			model.y = Math.sin(clock.getElapsedTime()) * 20 + 110