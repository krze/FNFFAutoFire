def roll(number, sides)
    total = 0

    number.times do
        total += (1 + rand(sides))
    end

    total
end

def location(roll_value)
  case roll_value
    when 2..4
      return :torso
    when 5
      return :right_arm
    when 6
      return :left_arm
    when 7..8
      return :right_leg
    when 9..10
      return :left_leg
    else
      return :head
  end
end

def stun_or_mortal_check(damage)
  return nil if damage == 0

  mortal = "MORTAL"
  mortal_value = 0
  stun = "STUN"
  stun_value = damage >= 40 ? 9 : (damage / 4) - (damage % 4 == 0 ? 1 : 0)
  result = ""

  if damage > 12
    mortal_value = damage >= 40 ? 6 : ((damage / 4) - 3) - (damage % 4 == 0 ? 1 : 0)
    result += "#{mortal} -#{mortal_value}\n"
  end

  result += "#{stun} -#{stun_value}"

  return result
end

def above_partial_cover(location_value)
  location_value != :right_leg || location_value != :left_leg
end

def find_next_layer(armor, current_layer)
  next_layer = 1 #1 will be the last layer

  # Start the peek at the next layer
  mutable_layer_count = current_layer

  # Keep peeking until you run out of layers
  until (armor.key?(mutable_layer_count) || mutable_layer_count <= next_layer)
    mutable_layer_count -= 1
  end

  next_layer = mutable_layer_count

  next_layer
end

def reduce_by_armor(hit_damage, hit_location, armor, cover_armor_value, partial_cover, ap_rounds)
  behind_cover = armor.key?(:cover) && (partial_cover ? (hit_location == :left_leg || hit_location == :right_leg) : true)
  current_layer = behind_cover ? :cover : armor[:layer_count]
  next_layer = behind_cover ? armor[:layer_count] : find_next_layer(armor, armor[:layer_count] - 1)
  hit_damage = hit_damage

  hit_location_armor = 0
  hit_location_string = hit_location.to_s.upcase.sub('_', ' ')

  until (current_layer == 0 || hit_damage <= 0)
    hit_location_armor = behind_cover ? armor[current_layer][:sps] : armor[current_layer][hit_location]

    current_layer_string = current_layer == :cover ? current_layer.to_s.upcase : "Armor Layer #{current_layer}"

    puts "\n#{hit_damage} damage strikes #{current_layer == :cover ? "#{current_layer_string}, protecting the #{hit_location_string}" : "#{current_layer_string} in the #{hit_location_string}"}"
    puts "#{current_layer_string}\'s SPS value is is #{hit_location_armor}"

    if hit_location_armor > 0
      sps_diff_bonus = 0
      next_layer_armor = armor.key?(next_layer) ? armor[next_layer][hit_location] : 0

      if (next_layer >= 1 && next_layer_armor > 0)
        sps_diff = (hit_location_armor - next_layer_armor).abs
        puts "The next layer armor is #{next_layer_armor}"
        puts "The diff between the two layers is #{sps_diff}."
        if sps_diff < 27
          case sps_diff
          when 0..4
            sps_diff_bonus = 5
          when 5..8
            sps_diff_bonus = 4
          when 9..14
            sps_diff_bonus = 3
          when 15..20
            sps_diff_bonus = 2
          when 21..26
            sps_diff_bonus = 1
          else
            sps_diff_bonus = 0
          end
        end
      end

      puts "#{hit_location_string} is protected with an SPS value of #{hit_location_armor}"
      puts "... plus an SPS diff bonus of #{sps_diff_bonus}, making the total SPS value #{hit_location_armor + sps_diff_bonus}" if sps_diff_bonus > 0
      puts "... but AP Rounds reduce armor effect by half. Meaning the SPS is effectively #{(hit_location_armor + sps_diff_bonus) / 2}" if ap_rounds
      puts "Total hit damage is #{hit_damage}"
      hit_damage = hit_damage - ((hit_location_armor + sps_diff_bonus) / (ap_rounds ? 2 : 1))
      puts "Reduced hit damage is #{hit_damage}"

      # TODO: AP
      if hit_damage > 0
        puts("#{hit_damage} damage penetrated layer #{current_layer} to hit #{hit_location_string}")
        if current_layer == :cover
          armor[current_layer][:sps] = hit_location_armor - 1
        else
          armor[current_layer][hit_location] = hit_location_armor - 1
        end

        puts("#{current_layer_string}\'s SPS value#{current_layer == :cover ? '' : " in location #{hit_location_string}"} is now #{hit_location_armor - 1}")
        # Destroy the cover if it's been penetrated
        if (current_layer == :cover && armor[current_layer][:sps] <= 0)
          armor.delete(current_layer)
        end
      else
        puts("Damage failed to penetrate.\n")
        return current_layer == :cover ? nil : hit_damage
      end
    end

    current_layer = next_layer
    next_layer = find_next_layer(armor, next_layer - 1)
    behind_cover = false
    puts("Continuing damage calculation for next layer...") if current_layer > 0
  end
  puts("#{hit_damage} damage penetrated #{current_layer == :cover ? 'cover' : 'armor'} to hit the target!")
  return hit_damage
end

location_damage = {
    :left_arm => 0,
    :right_arm => 0,
    :left_leg => 0,
    :right_leg => 0,
    :torso => 0,
    :head => 0,
    :destroyed_limbs => Array.new
}

armor_layers = Hash.new

dead = false
crippled = []

puts "Cyberpunk 2020 FNFF automatic fire hit calculator for one target."
puts "This calculator assumes you've already rolled to hit and hit the target."
puts "Enter all values as positive integers."
puts "Enter the number of hits"
number_of_hits = gets.chomp.to_i
puts "Enter the number of dice for damage roll (i.e. the '3' in 3D6+1)"
damage_dice_number = gets.chomp.to_i
puts "Enter the number of sides per dice for the damage roll (i.e. the '6' in 3D6+1)"
damage_dice_sides = gets.chomp.to_i
puts "Enter the damage modifier, 0 if none. (i.e. the '1' in 3D6+1)"
damage_modifier = gets.chomp.to_i
puts "Are these Armor Piercing (AP) rounds? (y/n)"
ap_rounds = gets.chomp.downcase == "y"

puts "Is the target behind cover? (y/n)"
behind_cover = gets.chomp.downcase == "y"
cover_armor_value = 0
partial_cover = false

if behind_cover
  puts "What is the SPS value of the cover?"
  cover_armor_value = gets.chomp.to_i

  puts "Is it partial cover (only legs covered)? (y/n)"
  partial_cover = gets.chomp.downcase == "y"
end

puts "Enter the victim's current damage points:"
total_damage = gets.chomp.to_i
puts "Enter the victim's BTM as a positive integer"
btm = gets.chomp.to_i

puts "\nATTENTION!!!\n"
puts "The next few prompts are going to ask for armor values from INSIDE to OUT, per location."
puts "Skinweave counts as the FIRST layer."
puts "All other armor (implanted or worn) follows."
puts "Armor provided by environmental cover is calculated already. Do not enter any additional armor values provided by cover."

all_armor = Hash.new
armor_done = false
target_unarmored = false

no_armor_left = {
  :head => false,
  :torso => false,
  :left_arm => false,
  :right_arm => false,
  :left_leg => false,
  :right_leg => false
}

current_layer = 1

# Layer on the armor
until armor_done
  armor = {
    :head => 0,
    :torso => 0,
    :left_arm => 0,
    :right_arm => 0,
    :left_leg => 0,
    :right_leg => 0
  }

  armor.each do |location, value|
    puts("\nLAYER NUMBER #{current_layer}") if location == :head
    unless no_armor_left[location]
      puts "Enter the victim's armor SPS value for #{location.to_s.sub('_', ' ').upcase}, Layer #{current_layer}"
      value = gets.chomp.to_i
      armor[location] = value unless value == 0
      no_armor_left[location] = armor[location] == 0
    end
  end

  # Armor is done if there's no location that includes "false"
  armor_done = !no_armor_left.values.include?(false)

  if (armor_done && current_layer == 1)
    all_armor[:layer_count] = 0
    (target_unarmored = true) unless behind_cover
  end

  unless armor_done
    all_armor[current_layer] = armor
    all_armor[:layer_count] = current_layer
  end

  current_layer += 1
end

# Apply cover armor to armor model
if behind_cover
  all_armor[:cover] = Hash.new
  all_armor[:cover][:sps] = cover_armor_value
  unless partial_cover
    all_armor[:cover][:partial] = true
  end
end

hit_number = 0

until number_of_hits <= 0
  hit_damage = roll(damage_dice_number, damage_dice_sides) + damage_modifier
  hit_location = location(roll(1,10))
  hit_number += 1
  puts "\nHit \##{hit_number}:"
  unless target_unarmored
    puts "\nApplying damage of #{hit_damage} against target's armor:"
    hit_damage = reduce_by_armor(hit_damage, hit_location, all_armor, cover_armor_value, partial_cover, ap_rounds)
  else
    puts "\nTarget is not under cover or wearing armor. #{hit_damage} damage hits!"
  end

  # Hit damage came back nil because it failed to penetrate cover
  next unless hit_damage

  hit_damage = (hit_damage / (ap_rounds ? 2 : 1)) - btm
  puts "Hit damage against flesh was reduced by half because it's an AP round." if ap_rounds
  puts "Target's BTM #{btm} has reduced the damage to #{hit_damage}."

  # Always apply at least 1 damage
  if hit_damage <= 0
    hit_damage = 1
    puts "Target still needs to take 1 damage."
  end

  # Apply hit damage to location
  hit_damage = hit_damage * 2 if hit_location == :head
  puts "Applying #{hit_damage} damage to #{hit_location.to_s.upcase.sub('_', ' ')}"
  location_damage[hit_location] = location_damage[hit_location] + hit_damage
  unless hit_location == :torso || hit_damage < 8
    location_damage[:destroyed_limbs] << hit_location
  end

  total_damage = total_damage + hit_damage

  number_of_hits = number_of_hits - 1
end

puts "\nResults:\n\n"

dead = (total_damage > 40)
limb_destroyed = false
head_destroyed = false

location_damage.each do |part, amount|
  next if part == :destroyed_limbs

  part_string = part.to_s.sub('_', ' ').upcase
  puts "#{part_string} took #{amount} damage."

  next if part == :torso
  if location_damage[:destroyed_limbs].include?(part)
    puts "#{part_string} was DESTROYED!!"

    head_destroyed = true if part == :head
    next if part == :head
    limb_destroyed = true
  end
end

all_armor.each do |layer, armor|
  next if layer == :layer_count
  layer == :cover ? puts("\nCover remaining:") : puts("\nLayer #{layer} remaining:")
  armor.each do |part, amount|
    part_string = part.to_s.sub('_', ' ').upcase

    puts "#{part_string} armor is now #{amount}"
  end
end

puts "\nVictim's current damage is: #{total_damage}"
puts "VICTIM IS DEFINITELY DEAD!!!" if dead || head_destroyed
puts "The cover was DESTROYED!" if (behind_cover && !all_armor.key?(:cover))

mortal_check_result = stun_or_mortal_check(total_damage)

if (!dead && mortal_check_result)
  puts "\nYour damage of #{total_damage} indicates you must check the following rolls, in order:\n\n"
  puts "MORTAL -0 for loss of limb(s)" if limb_destroyed
  puts "#{mortal_check_result}"
  puts "\nFor each roll, subtract the penalty listed from a D10 roll."
  puts "The result must be EQUAL OR LESS THAN your stun save save value."
end

puts "\nVictim is now DEAD 0. Every minute increases DEAD state +2." if dead
puts "If the victim reaches DEAD 10 without medical attention, sell em for parts!" if dead
