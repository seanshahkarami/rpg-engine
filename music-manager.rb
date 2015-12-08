# The music manager is in charge of keeping track of the currently playing music
# and handling changes between music. This includes only changing music when a
# song other than the currently playing song is requested and handling a simple
# fade effect between requests.
class MusicManager
  
  def initialize
    @music = nil
    @filename = ""
    @timer = nil
  end
  
  # Changes the current music to 'filename' but not instantly. What we should
  # really be doing is scheduling a timer to manage the transition. That is
  # much more maintainable in the long run.
  def changeMusic(filename)
    if @filename != filename
      @timer.terminate unless @timer.nil?
      @timer = Timer.new(0.02) { scheduledFadeOut }
      @filename = filename
    end
  end
  
  private
  
  # Scheduled callback which fades the current music out
  def scheduledFadeOut
    if not @music.nil? and @music.volume > 0.0
      @music.volume -= 0.02
    else
      @music = Gosu::Song.new($engine, 'resource/music/' + @filename)
      @music.volume = 0.8
      @music.play(true)

      @timer.terminate
      @timer = Timer.new(0.1) { scheduledFadeIn }
    end
  end
  
  # Scheduled callback which fade the current music in
  def scheduledFadeIn
    if @music.volume < 1.0
      @music.volume += 0.02
    else
      @timer.terminate
      @timer = nil
    end
  end
  
end
