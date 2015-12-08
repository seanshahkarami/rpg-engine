require 'gosu'
require 'script-manager'
require 'map-manager'
require 'music-manager'
require 'scene-manager'
require 'map-scene'
require 'input'

class Timer
  
  def initialize(delay, &block)
    @delay = delay
    @block = block
    @accum = 0.0
    @terminate = false
    $engine.addTimer(self)
  end
  
  def accumulateTime(amount)
    unless terminate?
      @accum += amount
      while @accum >= @delay
        @block.call
        @accum -= @delay
      end
    end
  end
  
  def terminate
    @terminate = true
  end
  
  def terminate?
    @terminate
  end
  
end

class Scene
  
  def initialize(engine)
    @engine = engine
    @onupdate = proc {}
    @ondraw = proc {}
  end
  
  def onupdate(&block)
    @onupdate = block
  end
  
  def ondraw(&block)
    @ondraw = block
  end
  
  def update
    @onupdate.call
  end
  
  def draw
    @ondraw.call
  end
  
end

class Engine < Gosu::Window
  
  attr_reader :mapManager
  attr_reader :musicManager
  attr_reader :sceneManager
  attr_reader :scriptManager
  attr_reader :input
  
  attr_reader :tilesetCache
  attr_reader :spritesetCache
  
  def initialize(config = {})
    super(config[:screenWidth], config[:screenHeight], false)
    
    $engine = self
    
    @timers = []
    
    @mapManager = MapManager.new(self)
    @musicManager = MusicManager.new
    @scriptManager = ScriptManager.new
    
    @mapManager.focus = @mapManager.addCharacter(0, 0, config[:startingSprite])

    @mapManager.changeMap(config[:startingMap],
                          config[:startingLink])
    
    @input = Input.new(self)
    @scene = Scene.new(self)
    
    @input.onButtonDown(Gosu::KbEscape) { exit }
    @input.onButtonHeld(Gosu::KbLeft) { @mapManager.focus.moveLeft }
    @input.onButtonHeld(Gosu::KbRight) { @mapManager.focus.moveRight }
    @input.onButtonHeld(Gosu::KbUp) { @mapManager.focus.moveUp }
    @input.onButtonHeld(Gosu::KbDown) { @mapManager.focus.moveDown }
    @input.onButtonDown(Gosu::KbReturn) { @mapManager.interact }
    
    @scene.onupdate { @mapManager.update }
    @scene.ondraw { @mapManager.draw }
  end
  
  def button_down(button)
    @input.buttonDown(button)
  end
  
  def button_up(button)
    @input.buttonUp(button)
  end
  
  def addTimer(timer)
    @timers.push(timer)
  end
  
  def update
    terminatingTimers, @timers = @timers.partition(&:terminate?)
    @timers.each { |timer| timer.accumulateTime(update_interval/ 1000.0) }
    
    @input.update
    @scene.update
  end
  
  def draw
    @scene.draw
  end
  
end
