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
    maybe_rescue_closest_captives!
  end
  
  def maybe_attack_closest_unbound_enemy!
    closest_unbound_enemy_direction = DIRECTIONS.detect {|d| feel(d).enemy?}
    approaching_nearby_target(closest_unbound_enemy_direction, :enemy) do |direction|
      attack!(closest_unbound_enemy_direction) 
    end
  end

  def maybe_attack_closest_bound_enemy!
    closest_bound_enemy_direction = DIRECTIONS.detect {|d| feel(d).bound_enemy? }
    approaching_nearby_target(closest_bound_enemy_direction, :bound_enemy) do |direction|
      attack!(direction) 
    end
  end
  
  def maybe_rescue_closest_captives!
    closest_captive_direction = DIRECTIONS.detect {|d| feel(d).non_hostile_captive? }
    approaching_nearby_target(closest_captive_direction, :captive) do |direction|
      rescue!(direction)
    end 
  end
  
  def approaching_nearby_target(direction, looking_for)
    if direction
      yield(direction)
    else
      nearby_target = if looking_for == :enemy
                        listen.detect {|space| space.enemy? }
                      elsif looking_for == :bound_enemy
                        listen.detect {|space| space.bound_enemy? }
                      elsif looking_for == :captive
                        listen.detect {|space| space.non_hostile_captive? }
                      end
      if nearby_target
        if feel(direction_of(nearby_target)).stairs?
          nearby_target = feel(DIRECTIONS.detect {|d| not(feel(d).stairs?) })
        end
        walk!(direction_of(nearby_target))
      end
    end
  end
  
  def others_around_me?
    others = listen.select {|d| d.captive? or d.enemy? } 
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

class RubyWarrior::Space
  def bound_enemy?
    captive? and not(character == 'C')
  end

  def non_hostile_captive?
    captive? and character == 'C'
  end
end
