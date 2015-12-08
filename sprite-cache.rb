class SpriteCache
  
  def initialize(engine)
    @engine = engine
    @cache = {}
  end
  
  def [](filename)
    @cache[filename] = Sprite.new(@engine, "resource/sprite/" + filename) unless @cache.has_key?(filename)
    return @cache[filename]
  end
  
end
