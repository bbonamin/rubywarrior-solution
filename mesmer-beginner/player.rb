require 'delegate'
require 'singleton'

class Player
  def play_turn(warrior)
    init_collaborators(warrior)
 
    catch :turn_done do
      if @barbarian.safe_ahead? 
        @barbarian.ensure_healthy
        @barbarian.walk!
      else
        @barbarian.mercyful_attack!
      end
    end
    Health.instance.last_recorded = @barbarian.health
  end
  
  def init_collaborators(warrior)
    @barbarian = Barbarian.from_warrior(warrior)
  end
end

# Enhanced Warrior
class Barbarian < SimpleDelegator

  def self.from_warrior(warrior)
    new(warrior)
  end
  
  def ensure_healthy
    if health_below_safe_threshold? and safe_ahead? and not(taking_damage?)
      rest!
    end
  end
  
  def health_below_safe_threshold?
    health < 15
  end
 
  def taking_damage?
    health < Health.instance.last_recorded
  end

  def mercyful_attack!
    if feel.captive?
      rescue!
    else
      attack!
    end
  end 
  
  def safe_ahead?
    feel.empty?
  end
 
  # A little magic that automatically ends the turn after a 
  # rubywarrior action 
  def method_missing(method, *args, &block)
    results = super
    if method.to_s[-1] == '!'
      throw :turn_done 
    else
      results
    end
  end
end

class Health
  include Singleton
  attr_accessor :last_recorded
end
