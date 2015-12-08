class Tileset
  
  def initialize(engine, filename)
    @tiles = Gosu::Image.load_tiles(engine, filename, 32, 32, false)
  end
  
  def tile(index)
    @tiles[index]
  end
  
end
