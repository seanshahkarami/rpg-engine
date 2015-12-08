class TilesetCache
  
  def initialize(engine)
    @engine = engine
    @cache = {}
  end
  
  def [](filename)
    @cache[filename] = Tileset.new(@engine, 'resource/tileset/' + filename) unless @cache.has_key?(filename)
    return @cache[filename]
  end
  
end
