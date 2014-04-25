class Player
  def play_turn(warrior)
    catch :turn_done do
      ensure_healthy(warrior)

      if warrior.feel.empty?
        warrior.walk!
      else
        warrior.attack!
      end
    end
  end

  def ensure_healthy(warrior)
    if warrior.health < 10 and warrior.feel.empty?
      warrior.rest!
      throw :turn_done
    end
  end 
end
