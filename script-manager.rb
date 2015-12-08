require 'fiber'

class ScriptManager
  
  def initialize
    @scripts = []
  end
  
  def runScript(fileName)
    @scripts.push(Script.new('resource/scripts/' + fileName + '.rb'))
    @scripts.last.resume
  end
  
  def update
    @scripts.each do |script|
      script.resume if script.running?
    end
  end
  
end

class Script
  
  def initialize(fileName)
    @fiber = Fiber.new { instance_eval(File.read(fileName)) }
  end
  
  def running?
    @fiber.alive?
  end
  
  def resume
    @fiber.resume
  end
  
  def message(text)
    $engine.input.onButtonHeld(Gosu::KbLeft) {}
    $engine.input.onButtonHeld(Gosu::KbRight) {}
    $engine.input.onButtonHeld(Gosu::KbUp) {}
    $engine.input.onButtonHeld(Gosu::KbDown) {}
    
    $engine.input.onButtonDown(Gosu::KbReturn) {
      $engine.input.onButtonHeld(Gosu::KbLeft) { $engine.mapManager.focus.moveLeft }
      $engine.input.onButtonHeld(Gosu::KbRight) { $engine.mapManager.focus.moveRight }
      $engine.input.onButtonHeld(Gosu::KbUp) { $engine.mapManager.focus.moveUp }
      $engine.input.onButtonHeld(Gosu::KbDown) { $engine.mapManager.focus.moveDown }
      $engine.input.onButtonDown(Gosu::KbReturn) { $engine.mapManager.interact }
      $engine.mapManager.endMessage
    }
    
    $engine.mapManager.showMessage(text) { @fiber.resume }
    Fiber.yield
  end

  def choose(text, &block)
    @choiceLabels = []
    @choiceBlocks = []
    
    instance_eval(&block)

    $engine.input.onButtonHeld(Gosu::KbLeft) {}
    $engine.input.onButtonHeld(Gosu::KbRight) {}
    $engine.input.onButtonHeld(Gosu::KbUp) {}
    $engine.input.onButtonHeld(Gosu::KbDown) {}
    
    $engine.input.onButtonDown(Gosu::KbUp) { $engine.mapManager.prevDialog }
    $engine.input.onButtonDown(Gosu::KbDown) { $engine.mapManager.nextDialog }
    
    $engine.input.onButtonDown(Gosu::KbReturn) {
      $engine.input.onButtonHeld(Gosu::KbLeft) { $engine.mapManager.focus.moveLeft }
      $engine.input.onButtonHeld(Gosu::KbRight) { $engine.mapManager.focus.moveRight }
      $engine.input.onButtonHeld(Gosu::KbUp) { $engine.mapManager.focus.moveUp }
      $engine.input.onButtonHeld(Gosu::KbDown) { $engine.mapManager.focus.moveDown }
      $engine.input.onButtonDown(Gosu::KbReturn) { $engine.mapManager.interact }
      $engine.input.onButtonDown(Gosu::KbUp) {}
      $engine.input.onButtonDown(Gosu::KbDown) {}
      $engine.mapManager.endDialog
    }
    
    $engine.mapManager.showDialog(text, @choiceLabels) { |index| @fiber.resume(index) }
    
    index = Fiber.yield
    @choiceBlocks[index].call
  end

  def choice(label, &block)
    @choiceLabels.push(label)
    @choiceBlocks.push(block)
  end
  
  alias :select :choose
  alias :option :choice
  
end