###*
 # Visualizer Object
 # Represents the Object used to manage data (Modules), and the way that the data's viewed.
 #
 # The visualization of data is a combined effort of all components contained in this project,
 # accessed through this Object.
 #
 # @class Visualizer
 # @extends Ember.Object
###
@Visualizer = Visualizer = Ember.Object.extend
  ###*
   # world is a reference to a Visualizer.World Object,
   # representing the main (overview) viewport.
   # Further details/documentation can be found in the vis_world file
   #
   # @property world
   # @type Object
  ###
  world: null

  ###*
   # scenes is a reference to a collection of Visualizer.Scene Objects,
   # each representing a Visualization (one or many views, on one or many datasets).
   # Further details/documentation can be found in the vis_scene file
   #
   # @property scenes
   # @type Object
  ###
  scenes: Ember.computed -> {}

  ###*
   # modules is a reference to a collection of Visualizer.Module Objects,
   # which in turn are responsible for modelling the data collections
   # and their relevant views.
   # Further details/documentation can be found in the _visualizer_module file.
   #
   # @property modules
   # @type Object
  ###
  modules: (Ember.computed ()-> Ember.Object.create() ).property()

  ###*
   # associations is a reference to a collective Object datastore for cross-Module
   # data.
   #
   # Currently this is implemented as a simple Object, but eventually it
   # may make sense to create standardized Visualizer.Association objects
   # similar to Visualizer.Modules...
   #
   # @property associations
   # @type Object
  ###
  associations: (Ember.computed ()-> Ember.Object.create() ).property()

  ###*
   # timers is a reference to an Object collection of Timeouts where
   # keys are names given, and values are Timeout ids (as natively generated by setTimeout).
   # This set is used to keep track of actions on a per-Visualizer level when
   # preventing multiple exectution via Visualizer.Utils.waitForRepeatingEvents.
   # Further details/documentation can be found in Visualizer.Utils
   #
   # @property timers
   # @type Object
  ###
  timers: Ember.computed -> {}

  ###*
   # init is called upon creation of a Visualizer Object.
   # It is responsible for the initial processing and setup of the Object.
   #
   # @param world Used for setting up the Visualizer.World Object
   # @constructor
  ###
  init: (world) ->
    @useWorld world
    @set("color", Visualizer.Colorer.create({visualizer: this}))


  ###*
   # useWorld creates a Visualizer.World object, using the a JQuery Object
   # created with the sent parameter. This created object is set as the
   # Visualizer Object's world property.
   #
   # @method useWorld
   # @param world Used for setting up the Visualizer.World Object
   # @return {void}
  ###
  useWorld: (world) ->
    @set 'world', Visualizer.World.create
      worldObj: $ world
      visualizer: this

  ###*
   # Alias for Visualizer.World method: injectDefaultWorld
   # @deprecated Use (visualizer).get('world').injectDefaultWorld()
  ###
  injectWorld: () -> @get('world').injectDefaultWorld()

  ###*
   # addModule creates a Visualizer.Module object specified by the moduleClass parameter,
   # using a provided key (to allow differentiation and access). If (optional) content
   # parameter is provided, it will be set as the module's content.
   #
   # After the module's creation, the Visualizer object is refreshed.
   #
   # @method addModule
   # @param {Module} moduleClass Class of a Visualizer.Module Object to be created
   # @param {String} moduleKey Key used by the Visualizer and module for access and differentiation
   # @param {Array} [content] (Optional) Collection of data to use immediately with the module
   # @return {void}
  ###
  addModule: (moduleClass, moduleKey, content) ->
    module = moduleClass.create({visualizer: this, key: moduleKey})
    @set("modules.#{moduleKey}", module)
    @set("modules.#{moduleKey}.content", content) if content?
    module.requestRedraw()

  ###*
   # refresh sends a request to the current scene to update the visualization
   # based on all current dimensions.
   #
   # The scene will not be drawn unless the Visualizer's World is loaded (has a viewport).
   #
   # refresh observes the world's state, and the current scene - it should automatically
   # be triggered when any of these things change to ensure an up-to-date Visualization.
   #
   # Note: because Ember Observers currently only watch Array collections (@each), not Object-maps,
   # This will (sadly) not currently watch 'modules.@each.dataset'...
   #
   # @method refresh
   # @return {void}
  ###
  refresh: (() ->
    @get('currentScene')?.reload() if @get('world.loaded')
  ).observes('currentScene', 'world.worldObj', 'world.loaded', 'world.width', 'world.height')

  ###*
   # useScenes updates the Visualizer's scenes collection with the inputScenes parameter.
   # For each item in inputScenes , a Visualizer.Scene object is created, with a
   # reference to this instance of Visualizer as its visualizer parameter.
   #
   # @method useScenes
   # @param {Array} inputScenes A set of scenes to create and use for Visualization.
   # @return {void}
  ###
  useScenes: (inputScenes=[]) ->
    unless Visualizer.Utils.isArray(inputScenes)
      console?.log? "Object({})-type input for useScenes is deprecated - please pass an Array instead..."
      inputScenes = inputScenes.visualizer_scenes
    for scene in (inputScenes)
      scene.visualizer = this
      @set "scenes.#{scene.identifier}", Visualizer.Scene.create(scene)

  ###*
   # setScene updates the Visualizer's currentScene property to reference the
   # scene relevant to the method's _identifier parameter.
   #
   # @method setScene
   # @param {String} _identifier The key identifier of a scene to use.
   # @return {void}
  ###
  setScene: (_identifier) ->
    @set 'currentScene', @get("scenes.#{_identifier}")

  ###*
   # destroy cleans up the Visualizer (asking each Module to remove its Views, etc.)
   #
   # @method destroy
   # @return {void}
  ###
  destroy: ->
    for own moduleName, module of @get('modules')
      module.destroy?()
