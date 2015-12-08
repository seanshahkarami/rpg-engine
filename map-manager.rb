require 'character'
require 'sprite'
require 'link'
require 'tileset'
require 'sprite-cache'
require 'tileset-cache'
require 'nokogiri'
require 'base64'
require 'zlib'

class MapManager
  
  attr_accessor :focus
  
  def initialize(engine)
    @engine = engine
    
    @spriteCache = SpriteCache.new(@engine)
    @tilesetCache = TilesetCache.new(@engine)
    
    @map = nil
    
    @width = 0
    @height = 0
    
    @layers = []
    @obstruction = nil
    
    @characters = []
    @focus = nil
    
    @links = {}
    @linked = true
    
    @transitionState = 0
    @transitionOpacity = 0
    @transitionFileName = ""
    @transitionLinkName = ""
    
    @messageImage = nil
    @messageCallback = nil
    
    @dialogImage = nil
    @dialogImage2 = nil
    @dialogCallback = nil
    @dialogCount = 0
    @dialogIndex = 0
    
    @dialogManager = nil
  end
  
  def showMessage(message, &callback)
    @messageImage = Gosu::Image.from_text($engine, message, "Arial", 24, 8, ($engine.width * MessageWindowPercentWidth).to_i, :left)
    @messageCallback = callback
  end
  
  def endMessage
    @messageImage = nil
    callback = @messageCallback
    @messageCallback = nil
    callback.call
  end
  
  def showDialog(message, choices, &callback)
    text = ""
    
    text += message
    text += "\n"
    
    choices.each do |label|
      text += label
      text += "\n"
    end
    
    @dialogImage = Gosu::Image.from_text($engine, text, "Arial", 24, 8, ($engine.width * MessageWindowPercentWidth).to_i, :left)
    @dialogCount = choices.count
    @dialogIndex = 0
    @dialogCallback = callback
  end
  
  def nextDialog
    @dialogIndex = (@dialogIndex + 1) % @dialogCount
  end
  
  def prevDialog
    @dialogIndex = (@dialogIndex - 1) % @dialogCount
  end
  
  def endDialog
    @dialogImage = nil
    callback = @dialogCallback
    @messageCallback = nil
    callback.call(@dialogIndex)
  end
  
  def interact
    case @focus.direction
    when Character::DirectionLeft
      x = @focus.x-1
      y = @focus.y
      direction = Character::DirectionRight
    when Character::DirectionRight
      x = @focus.x+1
      y = @focus.y
      direction = Character::DirectionLeft
    when Character::DirectionUp
      x = @focus.x
      y = @focus.y-1
      direction = Character::DirectionDown
    when Character::DirectionDown
      x = @focus.x
      y = @focus.y+1
      direction = Character::DirectionUp
    end
    
    if character = @characters.select { |character| character != @focus }.find { |character| character.x == x && character.y == y }
      character.direction = direction
      unless character.scriptName.empty?
        $engine.scriptManager.runScript(character.scriptName)
      end
    end
  end
  
  def addCharacter(x, y, spriteFilename)
    character = Character.new(@engine, x, y)
    character.sprite = @spriteCache[spriteFilename]
    @characters.push(character)
    return character
  end
  
  def addLink(name, left, top, right, bottom, mapName, linkName)
    link = Link.new
    link.left = left
    link.top = top
    link.right = right
    link.bottom = bottom
    link.map = mapName
    link.link = linkName
    @links[name] = link
    return link
  end
  
  def changeMap(fileName, linkName)
    @map = Map.loadFromFile(@engine, "resource/map/" + fileName)
    p @map
    
    @characters.clear
    @characters.push(@focus) unless @focus.nil?

    @links.clear
    @linked = true

    loadMapFile(fileName)

    link = @links[linkName]
    @focus.moveTo(((link.left + link.right) / 2).to_i / 32, ((link.top + link.bottom) / 2).to_i / 32)
  end
  
  def transitionMap(fileName, linkName)
    @transitionState = 1
    @transitionOpacity = 0
    @transitionFileName = fileName
    @transitionLinkName = linkName
  end
  
  def findLinkCollision
    x = @focus.spriteX + 16.0
    y = @focus.spriteY + 16.0
    return @links.values.find { |link| link.left <= x and x <= link.right and link.top <= y and y <= link.bottom }
  end
  
  def obstruction?(x, y)
    return true if @obstruction[x + @width * y]
    return true if @characters.find { |character| x == character.x && y == character.y }
    return false
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
    @characters.each(&:update)
  
    if link = findLinkCollision
      transitionMap(link.map, link.link) unless @linked or link.map.empty?
    else
      @linked = false
    end
  end
  
  def updateTransitionOut
    @transitionOpacity += 16
    
    if @transitionOpacity >= 255
      @transitionState = 2
      @transitionOpacity = 255
      changeMap(@transitionFileName, @transitionLinkName)
    end

  end
  
  def updateTransitionIn
    @transitionOpacity -= 16
    @transitionState = 0 if @transitionOpacity <= 0
  end
  
  MessageWindowPercentLeft  = 0.05
  MessageWindowPercentRight = 0.95
  MessageWindowPercentTop  = 0.05
  MessageWindowPercentBottom = 0.45
  MessageWindowPercentWidth = MessageWindowPercentRight - MessageWindowPercentLeft
  
  def draw
    cameraX = @focus.spriteX - (@engine.width / 2) + 16
    cameraY = @focus.spriteY - (@engine.height / 2) + 16
    
    drawLayers(cameraX, cameraY)
    drawCharacters(cameraX, cameraY)
    
    if @transitionState != 0
      overlay = Gosu::Color.new(@transitionOpacity, 0, 0, 0)
      @engine.draw_quad(0, 0, overlay, @engine.width, 0, overlay, 0, @engine.height, overlay, @engine.width, @engine.height, overlay)
    end
    
    unless @messageImage.nil?
      x1 = $engine.width * MessageWindowPercentLeft
      x2 = $engine.width * MessageWindowPercentRight
      y1 = $engine.height * MessageWindowPercentTop
      y2 = $engine.height * MessageWindowPercentBottom
      
      drawWindow(x1, y1, x2, y2)
      
      @messageImage.draw(x1 + 17, y1 + 17, 0, 1, 1, Gosu::Color::BLACK)
      @messageImage.draw(x1 + 16, y1 + 16, 0)
    end
    
    unless @dialogImage.nil?
      x1 = $engine.width * MessageWindowPercentLeft
      x2 = $engine.width * MessageWindowPercentRight
      y1 = $engine.height * MessageWindowPercentTop
      y2 = $engine.height * MessageWindowPercentBottom
      
      drawWindow(x1, y1, x2, y2)
      
      @dialogImage.draw(x1 + 17, y1 + 17, 0, 1, 1, Gosu::Color::BLACK)
      @dialogImage.draw(x1 + 16, y1 + 16, 0)
      
      x1 = 32
      x2 = $engine.width - 32
      y1 = $engine.height - 36 * @dialogCount + 32 * @dialogIndex - 22
      y2 = y1 + 28
      
      color = Gosu::Color.new(100, 200, 200, 200)
      
      $engine.draw_quad(x1, y1, color, x2, y1, color, x1, y2, color, x2, y2, color)
    end
  end
  
  private
  
  WindowColor1 = Gosu::Color.new(160, 0, 0, 255)
  WindowColor2 = Gosu::Color.new(160, 255, 255, 255)
  WindowColorShadow = Gosu::Color.new(120, 0, 0, 0)
  
  def drawWindow(x1, y1, x2, y2)
    $engine.draw_quad(x1+2, y1+2, WindowColorShadow,
                      x2+2, y1+2, WindowColorShadow,
                      x1+2, y2+2, WindowColorShadow,
                      x2+2, y2+2, WindowColorShadow)
    
    $engine.draw_quad(x1, y1, WindowColor1,
                      x2, y1, WindowColor1,
                      x1, y2, WindowColor1,
                      x2, y2, WindowColor1)

    $engine.draw_line(x1, y1, WindowColor2,
                      x2, y1, WindowColor2)
                      
    $engine.draw_line(x1, y2, WindowColor2,
                      x2, y2, WindowColor2)
                      
    $engine.draw_line(x1, y1, WindowColor2,
                      x1, y2, WindowColor2)
                      
    $engine.draw_line(x2, y1, WindowColor2,
                      x2, y2, WindowColor2)
                      
    $engine.draw_line(x2, y1, WindowColor2,
                      x2, y2, WindowColor2)
  end
  
  # Draws the tile layers of the map
  def drawLayers(cameraX, cameraY)
    left = (cameraX / 32.0).floor
    right = ((cameraX + @engine.width) / 32.0).ceil
    top = (cameraY / 32.0).floor
    bottom = ((cameraY + @engine.height) / 32.0).ceil

    left = 0 if left < 0
    top = 0 if top < 0
    right = @width - 1 if right >= @width
    bottom = @height - 1 if bottom >= @height

    @layers.each do |layer|
      (top..bottom).each do |y|
        (left..right).each do |x|
          index = layer[x + @width * y]
          if index != 0
            tile = @tileset.tile(index-1)
            tile.draw(x * 32 - cameraX, y * 32 - cameraY, 0.0)
          end
        end
      end
    end
  end
  
  # Draws the characters on the map
  def drawCharacters(cameraX, cameraY)
    @characters.each do |character|
      character.draw(cameraX, cameraY)
    end
  end
  
  def getPropertiesFromNode(node)
    Hash[node.xpath("properties/property").map { |node2| [node2['name'], node2['value']] }]
  end
  
  def loadMapFile(filename)
    doc = Nokogiri::XML(File.read('resource/map/' + filename))
    root = doc.root
    
    @width = root['width'].to_i
    @height = root['height'].to_i
    
    properties = getPropertiesFromNode(root)

    @engine.musicManager.changeMusic(properties['music']) if properties.has_key?('music')

    # load tile layers    
    @layers = root.xpath("layer[@name!='obstruction']/data").map do |layer|
      Zlib::Inflate.inflate(Base64.decode64(layer.text)).unpack("I*")
    end
    
    # load obstruction layer
    elm = root.xpath("layer[@name='obstruction']/data").first
    @obstruction = Zlib::Inflate.inflate(Base64.decode64(elm.text)).unpack("I*").map { |x| x != 0 }

    #
    # load tileset
    #
    @tileset = @tilesetCache[root.xpath('tileset/image').first['source']]

    root.xpath("objectgroup/object[@type='Link']").each do |elm|
      properties = getPropertiesFromNode(elm)
      
      addLink(elm['name'],
              elm['x'].to_i,
              elm['y'].to_i,
              elm['x'].to_i + elm['width'].to_i,
              elm['y'].to_i + elm['height'].to_i,
              properties['map'],
              properties['link'])
    end
    
    root.xpath("objectgroup/object[@type='Character']").each do |elm|
      properties = getPropertiesFromNode(elm)
      
      character = addCharacter(elm['x'].to_i / 32,
                               elm['y'].to_i / 32,
                               properties['sprite'])

      case properties['direction']
      when 'down'
        character.faceDown
      when 'left'
        character.faceLeft
      when 'right'
        character.faceRight
      when 'up'
        character.faceUp
      end
      
      character.scriptName = properties['script'] if properties.has_key?('script')
    end
  end
  
end



# This encapsulates all the data associated to a map object which includes
# tile layers, characters, links and triggers.
class Map

  attr_accessor :width
  attr_accessor :height
  attr_accessor :characters
  attr_accessor :links
  attr_accessor :layers
  attr_accessor :obstruction
  attr_accessor :tileset
  
  # Loads a map instance from TMX data on disk
  def self.loadFromFile(engine, filename)
    Map.loadFromXMLDocument(engine, Nokogiri::XML(File.read(filename)))
  end
  
  def initialize
    @width = 0
    @height = 0
    @characters = []
    @links = []
    @layers = []
    @obstruction = []
    @tileset = nil
  end
  
  # units of character movement will be in tiles per second. So, a character with a speed of 1.5 should move 1.5 tiles per second
  # units of time will be in seconds. so, we should be able to
  def updateWorldForTime(dt)
    # right, dt will usually be seomthing like 1.0 / 60.0

    vector = destination - position
    
    if vector.norm < speed
      position = destination
    else
      position += vector.normalize * speed * dt
    end
  end
  
  protected
  
  # Loads a map instance from XML data in memory
  def self.loadFromXMLDocument(engine, document)
    map = Map.new
    
    root = document.root
    
    map.width = root['width'].to_i
    map.height = root['height'].to_i
    
    map.layers = Map.loadLayersFromNodes(root.xpath("layer[@name!='obstruction']/data"))
    map.obstruction = Map.loadObstructionFromXMLNode(root)
    #map.tileset = engine.tilesetCache[root.xpath('tileset/image').first['source']]
    map.links = Map.loadLinksFromNodes(root.xpath("objectgroup/object[@type='Link']"))
    map.characters = Map.loadCharactersFromNodes(root.xpath("objectgroup/object[@type='Character']"))
    
    properties = Map.loadPropertiesFromXMLNode(root)
    engine.musicManager.changeMusic(properties['music']) if properties.has_key?('music')
    
    map
  end
  
  # Loads layers represented by given list of XML nodes.
  def self.loadLayersFromNodes(nodes)
    nodes.map do |node|
      Zlib::Inflate.inflate(Base64.decode64(node.text)).unpack("I*")
    end
  end
  
  # Loads links represented by given list of XML nodes.
  def self.loadLinksFromNodes(nodes)
    nodes.map do |node|
      link = Link.new
      
      link.left = node['x'].to_f
      link.top = node['y'].to_f
      link.right = link.left + node['width'].to_f
      link.bottom = link.top + node['height'].to_f
      
      prop = Map.loadPropertiesFromXMLNode(node)
      
      link.map = prop['map']
      link.link = prop['link']
      
      link
    end
  end
  
  # Loads characters represented by given list of XML nodes.
  def self.loadCharactersFromNodes(nodes)
    nodes.map do |node|
      #character = Character.new
            
      properties = Map.loadPropertiesFromXMLNode(node)
      
      #character.moveTo(xmlNode['x'].to_f / 32.0, xmlNode['y'].to_f / 32.0)
      
      #character.sprite = engine.spriteCache[properties["sprite"]]

      #case properties['direction']
      #when 'down'
      #  character.faceDown
      #when 'left'
      #  character.faceLeft
      #when 'right'
      #  character.faceRight
      #when 'up'
      #  character.faceUp
      #end
      
      #character.scriptName = properties['script'] if properties.has_key?('script')
      
      #character
    end
  end
  
  # Gets the properties from a TMX properties tree
  def self.loadPropertiesFromXMLNode(xmlNode)
    return Hash[xmlNode.xpath("properties/property").map { |node2| [node2['name'], node2['value']] }]
  end
  
  # Gets th eobstructions from a TMX obstruction layer
  def self.loadObstructionFromXMLNode(xmlNode)
    Zlib::Inflate.inflate(Base64.decode64(xmlNode.xpath("layer[@name='obstruction']/data").first.text)).unpack("I*").map { |x| x != 0 }
  end
  
end
