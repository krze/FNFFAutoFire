require 'pp'

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

def above_partial_cover(location_value)
  location_value != :right_leg || location_value != :left_leg
end

def find_next_layer(armor, current_layer)
  next_layer = 1 #1 will be the last layer

  # Start the peek at the next layer
  mutable_layer_count = current_layer
  puts("Seeking the next layer. Checking #{mutable_layer_count}")
  # Keep peeking until you run out of layers
  until (armor.key?(mutable_layer_count) || mutable_layer_count <= next_layer)
    mutable_layer_count -= 1
    puts("Skipping to layer #{mutable_layer_count}")
  end

  next_layer = mutable_layer_count

  next_layer
end

def reduce_by_armor(hit_damage, hit_location, armor, cover_armor_value, partial_cover)
  behind_cover = armor.key?(:cover) && (partial_cover ? (hit_location == :left_leg || hit_location == :right_leg) : true)
  current_layer = behind_cover ? :cover : armor[:layer_count]
  next_layer = behind_cover ? armor[:layer_count] : find_next_layer(armor, armor[:layer_count] - 1)
  hit_damage = hit_damage

  hit_location_armor = 0

  until (current_layer == 0 || hit_damage <= 0)
    hit_location_armor = behind_cover ? armor[current_layer][:sps] : armor[current_layer][hit_location]

    puts "\nCalculating hit for layer #{current_layer}, in location #{hit_location}"
    puts "The next layer is #{next_layer}"
    puts "The current layer's armor is #{hit_location_armor}"
    if hit_location_armor > 0
      sps_diff_bonus = 0
      next_layer_armor = armor.key?(next_layer) ? armor[next_layer][hit_location] : 0
      if next_layer >= 1
        sps_diff = (hit_location_armor - next_layer_armor).abs
        puts "The next layer armor is #{next_layer_armor}."
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

      puts "Hit location armor is #{hit_location_armor}, with sps diff bonus of #{sps_diff_bonus}"
      puts "Total hit damage is #{hit_damage}"
      hit_damage = hit_damage - (hit_location_armor + sps_diff_bonus)
      puts "Reduced hit damage is #{hit_damage}"


      # TODO: AP
      if hit_damage > 0
        puts("Shot penetrated layer #{current_layer} to hit #{hit_location}")
        if current_layer == :cover
          armor[current_layer][:sps] = hit_location_armor - 1
        else
          armor[current_layer][hit_location] = hit_location_armor - 1
        end

        puts("Layer #{current_layer} armor in location #{hit_location} is now #{hit_location_armor - 1}")
        # Destroy the cover if it's been penetrated
        if (current_layer == :cover && armor[current_layer][:sps] <= 0)
          armor.delete(current_layer)
        end
      else
        puts("Shot failed to penetrate.\n")
        return current_layer == :cover ? nil : hit_damage
      end
    end

    current_layer = next_layer
    next_layer = find_next_layer(armor, next_layer - 1)
    behind_cover = false
    puts("Continuing damage calculation for next layer...")
  end

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
puts "Enter all values as positive integers. Please dont fuck with me."
puts "Enter the number of hits"
number_of_hits = gets.chomp.to_i
puts "Enter the number of dice for damage roll (i.e. the '3' in 3D6+1)"
damage_dice_number = gets.chomp.to_i
puts "Enter the number of sides per dice for the damage roll (i.e. the '6' in 3D6+1)"
damage_dice_sides = gets.chomp.to_i
puts "Enter the damage modifier, 0 if none. (i.e. the '1' in 3D6+1)"
damage_modifier = gets.chomp.to_i

puts "Is the target behind cover? (y/n)"
behind_cover = gets.chomp == "y"
cover_armor_value = 0
partial_cover = false

if behind_cover
  puts "What is the SPS value of the cover?"
  cover_armor_value = gets.chomp.to_i

  puts "Is it partial cover (only legs covered)? (y/n)"
  partial_cover = gets.chomp == "y"
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

until (dead || number_of_hits <= 0)
  hit_damage = roll(damage_dice_number, damage_dice_sides) + damage_modifier
  hit_location = location(roll(1,10))

  hit_damage = reduce_by_armor(hit_damage, hit_location, all_armor, cover_armor_value, partial_cover)

  # Hit damage came back nil because it failed to penetrate cover
  next unless hit_damage

  hit_damage = hit_damage - btm

  # Always apply at least 1 damage
  if hit_damage <= 0
    hit_damage = 1
  end

  # Apply hit damage to location
  hit_damage = hit_damage * 2 if hit_location == :head
  location_damage[hit_location] = location_damage[hit_location] + hit_damage
  unless hit_location == :torso || hit_damage < 8
    location_damage[:destroyed_limbs] << hit_location
  end

  total_damage = total_damage + hit_damage

  dead = true if (total_damage > 40 || location_damage[:head] > 8)
  number_of_hits = number_of_hits - 1
end

puts "\nResults:\n\n"
puts "VICTIM IS DEFINITELY DEAD!!\nHere's the obituary:\n\n" if dead
puts "Victim is now at #{total_damage} damage"

limb_destroyed = false

location_damage.each do |part, amount|
  next if part == :destroyed_limbs

  part_string = part.to_s.sub('_', ' ').upcase
  puts "#{part_string} took #{amount} damage."

  next if part == :torso
  puts "#{part_string} was DESTROYED!!" if location_damage[:destroyed_limbs].include?(part)
end

pp all_armor

all_armor.each do |layer, armor|
  next if layer == :layer_count
  puts "Layer #{layer}:"
  armor.each do |part, amount|
    part_string = part.to_s.sub('_', ' ').upcase

    puts "#{part_string} armor is now #{amount}"
  end
end

puts "A mortal save is necessary due to the loss of one or more limbs." if (limb_destroyed && !dead)
puts "The cover was DESTROYED!" if (behind_cover && all_armor[:cover][:sps] <= 0)
