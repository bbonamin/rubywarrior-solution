require 'delegate'

class Player
  def play_turn(warrior)
    barbarian = Barbarian.new(warrior)
    barbarian.perform!
  end
end

# Enhanced warrior
class Barbarian < SimpleDelegator
  DIRECTIONS = [:forward, :left, :right, :backward]
  def perform!
    if feel(direction_of_stairs).enemy?
      attack!(direction_of_stairs) 
    else
      walk!(direction_of_stairs)
    end
  end
end
