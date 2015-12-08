class Character
  
  DirectionLeft   = 0
  DirectionRight  = 1
  DirectionUp     = 2
  DirectionDown   = 3
  
  attr_accessor :x
  attr_accessor :y
  attr_reader :spriteX
  attr_reader :spriteY
  attr_accessor :speed
  attr_accessor :sprite
  attr_accessor :direction
  attr_accessor :animation
  attr_accessor :scriptName
  
  def initialize(engine, x, y)
    @engine = engine
    moveTo(x, y)
    @speed = 2
    @direction = 0
    @animation = 0
    @sprite = nil
    @scriptName = ""
  end
  
  def moveLeft
    unless moving?
      @x -= 1 unless @engine.mapManager.obstruction?(@x-1, @y)
      faceLeft
    end
  end
  
  def moveRight
    unless moving?
      @x += 1 unless @engine.mapManager.obstruction?(@x+1, @y)
      faceRight
    end
  end
  
  def moveUp
    unless moving?
      @y -= 1 unless @engine.mapManager.obstruction?(@x, @y-1)
      faceUp
    end
  end
  
  def moveDown
    unless moving?
      @y += 1 unless @engine.mapManager.obstruction?(@x, @y+1)
      faceDown
    end
  end
  
  def faceLeft
    @direction = DirectionLeft
  end
  
  def faceRight
    @direction = DirectionRight
  end
  
  def faceUp
    @direction = DirectionUp
  end
  
  def faceDown
    @direction = DirectionDown
  end
  
  def moving?
    return (@x * 32) != @spriteX || (@y * 32) != @spriteY
  end
  
  def update
    @animation += 0.05
    
    dx = @x * 32 - @spriteX
    dy = @y * 32 - @spriteY
    
    if dx > 0
      @spriteX += (1 << @speed)
    elsif dx < 0
      @spriteX -= (1 << @speed)
    end
    
    if dy > 0
      @spriteY += (1 << @speed)
    elsif dy < 0
      @spriteY -= (1 << @speed)
    end
  end
  
  def moveTo(x, y)
    @x = x
    @y = y
    @spriteX = x * 32
    @spriteY = y * 32
  end
  
  def draw(cameraX, cameraY)
    case @direction
    when DirectionLeft
      image = @sprite.left(@animation)
    when DirectionRight
      image = @sprite.right(@animation)
    when DirectionUp
      image = @sprite.up(@animation)
    when DirectionDown
      image = @sprite.down(@animation)
    end
    
    image.draw(@spriteX - cameraX, @spriteY - cameraY, 0)
  end
  
end
