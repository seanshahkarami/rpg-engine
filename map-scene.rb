require 'scene'

class MapScene < Scene
  
  def initialize(engine)
    @engine = engine
  end
  
  def buttonDown(id)
    exit if id == Gosu::KbEscape
  end
  
  def update
    @engine.mapManager.update
    @engine.scriptManager.update
  end
  
  def draw
    @engine.mapManager.draw
  end
  
end