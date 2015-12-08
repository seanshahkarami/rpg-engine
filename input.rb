require 'set'

class Input
  
  def initialize(engine)
    @callbackDown = {}
    @callbackUp = {}
    @callbackHeld = {}
    @buttonState = {}
  end
    
  def onButtonDown(button, &block)
    @callbackDown[button] = block
  end
  
  def onButtonUp(button, &block)
    @callbackUp[button] = block
  end
  
  def onButtonHeld(button, &block)
    @callbackHeld[button] = block
  end
  
  def buttonDown(button)
    @callbackDown[button].call if @callbackDown.has_key?(button)
    @buttonState[button] = true
  end
  
  def buttonUp(button)
    @callbackUp[button].call if @callbackUp.has_key?(button)
    @buttonState[button] = false
  end
  
  def update
    @buttonState.each do |button, state|
      if state and @callbackHeld.has_key?(button)
        @callbackHeld[button].call
      end
    end
  end
  
end