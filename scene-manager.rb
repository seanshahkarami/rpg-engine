class SceneManager
  
  def initialize(engine)
    @engine = engine
    @scenes = []
    @transitionState = 0
    @transitionOpacity = 0
    @transitionScene = nil
  end
  
  def changeScene(scene)
    @transitionState = 1
    @transitionOpacity = 0
    @transitionScene = scene
  end
  
  def buttonDown(id)
    @scenes.last.buttonDown(id) unless @scenes.empty?
  end
  
  def buttonUp(id)
    @scenes.last.buttonUp(id) unless @scenes.empty?
  end
  
  def update
    case @transitionState
    when 0
      updateTransitionNone
    when 1
      updateTransitionOut
    when 2
      updateTransitionIn
    end
  end
  
  def updateTransitionNone
    @scenes.last.update unless @scenes.empty?
  end
  
  def updateTransitionOut
    @transitionOpacity += 16
    
    if @transitionOpacity >= 255
      @transitionState = 2
      @transitionOpacity = 255
          
      @scenes.pop unless @scenes.empty?
      @scenes.push(@transitionScene)
    end
  end
  
  def updateTransitionIn
    @transitionOpacity -= 16
    @transitionState = 0 if @transitionOpacity <= 0
  end
  
  def draw
    @scenes.last.draw unless @scenes.empty?
    
    if @transitionState != 0
      overlay = Gosu::Color.new(@transitionOpacity, 0, 0, 0)
      @engine.draw_quad(0, 0, overlay, @engine.width, 0, overlay, 0, @engine.height, overlay, @engine.width, @engine.height, overlay)
    end
  end
  
end
