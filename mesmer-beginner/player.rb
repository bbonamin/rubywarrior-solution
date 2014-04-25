require 'delegate'
class Player
  def play_turn(warrior)
    @health ||= Health.new
    @barbarian = Barbarian.from_warrior(warrior)
    @barbarian.health_collaborator = @health
 
    catch :turn_done do
      if @barbarian.feel.empty? 
        @barbarian.ensure_healthy
        @barbarian.walk!
      else
        @barbarian.smart_attack!
      end
    end
    @health.previous = @barbarian.health
  end

    def retreat(warrior)
    warrior.walk! :backward
  end
end

# Enhanced Warrior
class Barbarian < SimpleDelegator
  attr_accessor :health_collaborator

  def self.from_warrior(warrior)
    new(warrior)
  end
  
  def ensure_healthy
    if health_below_safe_threshold? and feel.empty? and not(taking_damage?)
      rest!
      throw :turn_done
    end
  end
  
  def health_below_safe_threshold?
    health < 15
  end
 
  def taking_damage?
    if health < health_collaborator.previous
      true
    else
      puts 'Not taking damage'
    end
  end

  def smart_attack!
    if feel.captive?
      rescue!
    else
      attack!
    end
  end 
end

class Health
  attr_accessor :previous
end
