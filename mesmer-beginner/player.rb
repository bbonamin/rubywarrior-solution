require 'delegate'
require 'singleton'

class Player
  def play_turn(warrior)
    init_collaborators(warrior)
 
    catch :turn_done do
      @barbarian.perform!
    end
    Health.instance.last_recorded = @barbarian.health
  end
  
  def init_collaborators(warrior)
    @barbarian = Barbarian.from_warrior(warrior)
    Health.instance.last_recorded ||= @barbarian.health
  end
end

# Enhanced Warrior
class Barbarian < SimpleDelegator
  attr_accessor :closest_enemies

  def self.from_warrior(warrior)
    new(warrior)
  end
 
  def perform!
    rotate_if_facing_wall!
    evaluate_surroundings
    if safe_ahead? 
      ensure_healthy
      try_ranged!
      rescue_captives_behind unless $behind_captive_saved
      walk!
    else
      mercyful_attack!
    end
  end
  
  def evaluate_surroundings
    self.closest_enemies = {
      forward: look.find_index{|s| s.enemy?}, 
      backward: look(:backward).find_index{|s| s.enemy?}
    }
  end 

  def try_ranged!
    pivot! if closest_enemy_behind 
    initial_encounter = look.detect {|s| not(s.empty?) }
    return if initial_encounter && initial_encounter.captive?
    shoot! if look.any? {|s| s.enemy? } 
  end
  
  def closest_enemy_behind
    puts "Behind: #{closest_enemies[:backward]}, Front: #{closest_enemies[:forward]}"
    closest_enemies[:backward] and closest_enemies[:forward] and
    closest_enemies[:backward] > closest_enemies[:forward] 
  end

  def rotate_if_facing_wall!
    pivot! if feel.wall?
  end
  
  def ensure_healthy
    if Health.instance.below_confortable_limit? and safe_ahead? 
      if taking_damage? and Health.instance.below_critical_limit?
        retreat!
      else
        rest!
      end
    end
  end
  
  def rescue_captives_behind
    if feel(:backward).empty?
      walk!(:backward)
    else
      $behind_captive_saved = true
      rescue!(:backward)
    end 
  end 
  def retreat!
    walk!(:backward)
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
  
  CRITICAL_LIMIT = 10
  CONFORTABLE_LIMIT = 12
 
  def below_critical_limit?
    last_recorded < CRITICAL_LIMIT
  end
 
  def below_confortable_limit?
    last_recorded < CONFORTABLE_LIMIT
  end
 

end
