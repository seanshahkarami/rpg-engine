class Sprite
  
  def initialize(engine, filename)
    @tiles = Gosu::Image.load_tiles(engine, filename, 32, 32, false)
  end
  
  def up(index)
    @tiles[0 + (index % 2.0).to_i]
  end
  
  def right(index)
    @tiles[2 + (index % 2.0).to_i]
  end
  
  def down(index)
    @tiles[4 + (index % 2.0).to_i]
  end
  
  def left(index)
    @tiles[6 + (index % 2.0).to_i]
  end
  
end
