class Player
  def play_turn(warrior)
    #@barbarian ||= Barbarian.from_warrior(warrior)
    
    catch :turn_done do
      if warrior.feel.empty? 
        ensure_healthy(warrior)
        warrior.walk!
      else
        warrior.attack!
      end
    end
    @previous_health = warrior.health
  end

  def ensure_healthy(warrior)
    if health_below_safe_threshold?(warrior) and warrior.feel.empty? and not(taking_damage?(warrior))
      warrior.rest!
      throw :turn_done
    end
  end 
 
  def health_below_safe_threshold?(warrior)
    warrior.health < 15
  end
 
  def taking_damage?(warrior)
    @previous_health ||= 0
    warrior.health < @previous_health
  end
  
  def retreat(warrior)
    warrior.walk! :backward
  end
end

# Enhanced Warrior
class Barbarian
  def self.from_warrior(warrior)
    new(warrior: warrior)
  end
  
  def initialize(options = {})
    @warrior = options[:warrior]
  end
end
