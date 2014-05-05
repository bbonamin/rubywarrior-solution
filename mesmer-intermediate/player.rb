require 'delegate'
require 'singleton'

class Player
  def play_turn(warrior)
    barbarian = Barbarian.new(warrior)
    Health.instance.last_recorded ||= barbarian.health
    barbarian.perform!
  end
end

# Enhanced warrior
class Barbarian < SimpleDelegator
  DIRECTIONS = [:forward, :left, :right, :backward]
  attr_accessor :safe
  def perform!
    catch :turn_done do
      ensure_healthy_status
      bind_enemies if surrounded? 
      if others_around_me?
        smart_attack!
      else
        walk!(direction_of_stairs)
      end
    end
    Health.instance.last_recorded = health
  end
  
  def ensure_healthy_status
    retreat! if Health.instance.below_critical_limit?
    if Health.instance.below_confortable_limit? and safe_position?
      rest!
    end
  end
 
  def safe_position?
    DIRECTIONS.none? {|d| feel(d).enemy?}
  end
  
  def retreat!
    safe_direction = DIRECTIONS.detect {|d| feel(d).empty? }
    walk!(safe_direction) unless safe_position?
  end
  
  def taking_damage?
    puts "Current health #{health}"
    puts "Last recorded health #{Health.instance.last_recorded}"
    health < Health.instance.last_recorded
  end

  def smart_attack!
    maybe_attack_closest_unbound_enemy!
    maybe_attack_closest_bound_enemy!
    maybe_rescue_closest_captive!
  end
  
  def maybe_attack_closest_unbound_enemy!
    closest_unbound_enemy_direction = DIRECTIONS.detect {|d| feel(d).enemy?}
    attack!(closest_unbound_enemy_direction) if closest_unbound_enemy_direction 
  end

  def maybe_attack_closest_bound_enemy!
    closest_bound_enemy_direction = DIRECTIONS.detect {|d| feel(d).captive? and not(feel(d).character == 'C') }
    attack!(closest_bound_enemy_direction) if closest_bound_enemy_direction
  end
  
  def maybe_rescue_closest_captive!
    closest_captive_direction = DIRECTIONS.detect {|d| feel(d).captive? and feel(d).character == 'C'}
    rescue!(closest_captive_direction) if closest_captive_direction
  end
  
  def others_around_me?
    others = DIRECTIONS.select {|d| feel(d).captive? or feel(d).enemy? }
    others.count > 0
  end
  
  def surrounded?
    enemies = DIRECTIONS.select {|d| feel(d).enemy?} 
    enemies.count >= 2
  end
  
  def bind_enemies
    DIRECTIONS.each do |d|
      bind!(d) if feel(d).enemy?
    end
  end

  #A little magic to automatically end the turn after a 
  # rubywarrior action
  def method_missing(method_name, *args, &block)
    if method_name[-1] == '!'
      output = super
      throw :turn_done
    else
      output = super 
    end
    output
  end
end

class Health
  include Singleton
  attr_accessor :last_recorded
  
  CRITICAL_LIMIT = 5
  CONFORTABLE_LIMIT = 15
 
  def below_critical_limit?
    last_recorded < CRITICAL_LIMIT
  end
 
  def below_confortable_limit?
    last_recorded < CONFORTABLE_LIMIT
  end
end

