def roll(number, sides)
    total = 0

    number.times do
        total += (1 + rand(sides))
    end

    total
end

def decide_hit_damage(is_point_blank, number, sides, damage_modifier)
  if is_point_blank
    return (number * sides) + damage_modifier
  end

  return roll(number, sides)
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

def sps_diff_bonus(diff)
  case diff
  when 0..4
    return 5
  when 5..8
    return 4
  when 9..14
    return 3
  when 15..20
    return 2
  when 21..26
    return 1
  else
    return 0
  end
end

def armor_location_info(armor, location, partial_cover)
  behind_cover = armor.key?(:cover)
  return armor[:cover][:value] if behind_cover && armor[:no_armor_left] == true

  total_sps_diff_bonus = 0
  hard = armor[location][:hard]

  if behind_cover
    if partial_cover == false || (partial_cover && (location == :left_leg || location == :right_leg))
      values = [armor[:cover][:value], armor[location][:value]].sort
      total_sps_diff_bonus = sps_diff_bonus(values.last - values.first)
    end
  end

  return {
    :value => armor[location][:value] + total_sps_diff_bonus,
    :hard => hard
  }
end

def reduce_by_armor(hit_damage, hit_location, armor, cover_armor_value, partial_cover, ap_rounds)
  behind_cover = armor.key?(:cover) && (partial_cover ? (hit_location == :left_leg || hit_location == :right_leg) : true)
  outer_layer = behind_cover ? :cover : hit_location
  hit_damage = hit_damage

  hit_location_info = armor_location_info(armor, hit_location, partial_cover)
  hit_location_armor = hit_location_info[:value]
  hit_location_string = hit_location.to_s.upcase.sub('_', ' ')
  ap_is_effective = ap_rounds

  outer_layer_string = outer_layer == :cover ? outer_layer.to_s.upcase : "body armor"

  puts "\n#{hit_damage} damage strikes #{outer_layer == :cover ? "#{outer_layer_string}, protecting the #{hit_location_string}" : "the #{hit_location_string}"}"

  if hit_location_armor > 0
    puts "#{hit_location_string} is protected with an SPS value of #{hit_location_armor}"
    puts "... but AP Rounds reduce armor effect by half. Meaning the SPS is effectively #{hit_location_armor / 2}" if ap_is_effective
    puts "Total hit damage is #{hit_damage}"
    hit_damage = hit_damage - (hit_location_armor / (ap_is_effective ? 2 : 1))
    puts "Reduced hit damage is #{hit_damage}"

    if hit_damage > 0
      puts("#{hit_damage} damage penetrated to hit #{hit_location_string}")
      if outer_layer == :cover
        armor[:cover][:value] = armor[:cover][:value] - 1

        # Destroy the cover if it's been penetrated
        armor.delete(:cover) if (armor[:cover][:value] <= 0)
      end

      new_value = armor[hit_location][:value] - 1
      armor[hit_location][:value] = new_value > 0 ? new_value : 0
    else
      puts("Damage failed to penetrate.\n")
      return hit_damage
    end
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
puts "Enter all number values as positive integers. No negatives."
puts "Enter yes or no answers as y or n"
puts ""
puts "Is this a point blank attack? (y/n)"
point_blank = gets.chomp.downcase == "y"
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
  cover_armor_value = gets.chomp

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
puts "Enter the armor value followed by an 'h' to indicate it's hard armor (i.e. '15h')"

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
    :head => {
      :value => 0,
      :hard => false
    },
    :torso => {
      :value => 0,
      :hard => false
    },
    :left_arm => {
      :value => 0,
      :hard => false
    },
    :right_arm => {
      :value => 0,
      :hard => false
    },
    :left_leg => {
      :value => 0,
      :hard => false
    },
    :right_leg => {
      :value => 0,
      :hard => false
    }
  }

  armor.each do |location, status|
    puts("\nLAYER NUMBER #{current_layer}") if location == :head
    unless no_armor_left[location]
      puts "Enter the victim's armor SPS value for #{location.to_s.sub('_', ' ').upcase}, Layer #{current_layer}"
      input = gets.chomp
      value = input.to_i
      hard = input.downcase.include?('h')
      previous_location_value = current_layer > 1 ? all_armor[location][:value] : nil

      if previous_location_value && value > 0
        sorted_values = [value, previous_location_value].sort
        diff = sps_diff_bonus(sorted_values.last - sorted_values.first)
        armor[location][:value] = sorted_values.last + diff
      elsif value > 0
        armor[location][:value] = value
      end

      armor[location][:hard] = hard && (value > 0)
      no_armor_left[location] = value == 0
    end
  end

  # Armor is done if there's no location that includes "false"
  armor_done = !no_armor_left.values.include?(false)

  if (armor_done && current_layer == 1)
    all_armor = armor
    all_armor[:no_armor_left]
    (target_unarmored = true) unless behind_cover
  end

  unless armor_done
    all_armor = armor
  end

  current_layer += 1
end

# Apply cover armor to armor model
if behind_cover
  all_armor[:cover] = Hash.new
  all_armor[:cover][:value] = cover_armor_value.to_i
  all_armor[:cover][:hard] = cover_armor_value.downcase.include?('h')
  unless partial_cover
    all_armor[:cover][:partial] = true
  end
end

hit_number = 0
rat_a_tat = "\nThe gun goes RAT-A"
number_of_hits.times do
  rat_a_tat << "-TAT"
end

puts rat_a_tat
until number_of_hits <= 0
  hit_damage = decide_hit_damage(point_blank, damage_dice_number, damage_dice_sides, damage_modifier)
  hit_location = location(roll(1,10))
  hit_number += 1
  puts "\nHit \##{hit_number}:"
  unless target_unarmored
    puts "\nApplying damage of #{hit_damage} against target's armor:"
    hit_damage = reduce_by_armor(hit_damage, hit_location, all_armor, cover_armor_value, partial_cover, ap_rounds)
  else
    puts "\nTarget is not under cover or wearing armor. #{hit_damage} damage finds flesh!"
  end

  number_of_hits = number_of_hits - 1
  # Hit damage came back as 0 because it failed to penetrate
  next unless hit_damage > 0

  hit_damage = (hit_damage / (ap_rounds ? 2 : 1)) - btm
  puts "Hit damage against flesh was reduced by half because it's an AP round." if ap_rounds
  puts "Target's BTM #{btm} has reduced the damage to #{hit_damage}."

  # Always apply at least 1 damage
  if hit_damage <= 0
    hit_damage = 1
    puts "Target still needs to take 1 damage if damage is reduced by BTM <= 0."
  end

  # Apply hit damage to location
  hit_damage = hit_damage * 2 if hit_location == :head
  puts "Applying #{hit_damage} damage to #{hit_location.to_s.upcase.sub('_', ' ')}\n\n"
  location_damage[hit_location] = location_damage[hit_location] + hit_damage
  unless hit_location == :torso || location_damage[hit_location] < 8
    location_damage[:destroyed_limbs] << hit_location
  end

  total_damage = total_damage + hit_damage
  puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
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

all_armor.each do |location, status|
  part_string = location.to_s.sub('_', ' ').upcase
  location == :cover ? puts("\nCover remaining:") : puts("\n#{part_string} armor remaining:")

  puts "#{part_string} armor is now #{status[:value]}"
end

puts "\nVictim's current damage is: #{total_damage}"
puts "VICTIM IS DEFINITELY DEAD!!!" if dead || head_destroyed
puts "The cover was DESTROYED!" if (behind_cover && !all_armor.key?(:cover))

mortal_check_result = stun_or_mortal_check(total_damage)

if (!dead && mortal_check_result)
  puts "\nTotal damage of #{total_damage} indicates you must check against the following rolls, in order:\n\n"
  puts "MORTAL -0 for loss of limb(s)" if limb_destroyed
  puts "#{mortal_check_result}"
  puts "\nFor each roll, subtract the penalty listed from a D10 roll."
  puts "The result must be EQUAL OR LESS THAN your character's stun save save value."
end

puts "\nVictim is now DEAD 0. Every minute increases DEAD state +2." if dead
puts "If the victim reaches DEAD 10 without medical attention, sell em for parts!" if dead
