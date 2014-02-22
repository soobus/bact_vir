#Valery Nemychnikova

require 'gosu'
require_relative 'bactvir.rb'

class GameWindow < Gosu::Window
  def initialize game
    super 640, 480, false
    self.caption = "Gosu Tutorial Game"
    @background_image = Gosu::Image.new(self, "media/space.png", true)
    @game = game
  end
  
  def update
    @game.play
  end
  
  def draw
    @background_image.draw(0, 0, 0)
  end
end


