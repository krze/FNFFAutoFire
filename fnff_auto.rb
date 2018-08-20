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

location_damage = {
    :left_arm => 0,
    :right_arm => 0,
    :left_leg => 0,
    :right_leg => 0,
    :torso => 0,
    :head => 0
}

armor = {
    :left_arm => 0,
    :right_arm => 0,
    :left_leg => 0,
    :right_leg => 0,
    :head => 0,
    :torso => 0
}

dead = false
crippled = []

puts "Cyberpunk 2020 FNFF automatic fire hit calculator for one target."
puts "This calculator assumes you've already rolled to hit and hit the target."
puts "Enter all values as positive integers. Please dont fuck with me."
puts "Enter the number of hits"
number_of_hits = gets.chomp.to_i
puts "Enter the number of dice for damage roll"
damage_dice_number = gets.chomp.to_i
puts "Enter the number of sides per dice for the damage roll"
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
puts "Enter the victim's total armor SPS value for HEAD"
armor[:head] = gets.chomp.to_i
puts "Enter the victim's total armor SPS value for TORSO"
armor[:torso] = gets.chomp.to_i
puts "Enter the victim's total armor SPS value for RIGHT ARM"
armor[:right_arm] = gets.chomp.to_i
puts "Enter the victim's total armor SPS value for LEFT ARM"
armor[:left_arm] = gets.chomp.to_i
puts "Enter the victim's total armor SPS value for RIGHT LEG"
armor[:right_leg] = gets.chomp.to_i
puts "Enter the victim's total armor SPS value for LEFT LEG"
armor[:left_leg] = gets.chomp.to_i

until (dead || number_of_hits <= 0)
  hit_damage = roll(damage_dice_number, damage_dice_sides) + damage_modifier
  hit_location = location(roll(1,10))

  if partial_cover && !above_partial_cover(hit_location)
    until above_partial_cover(hit_location)
      hit_location = location(roll(1,10))
    end
  end

  hit_location_armor = armor[hit_location]
  hit_location_armor = 0 if hit_location_armor < 0

  # Cover needs to be calculated first, then damage applied to cover
  hit_damage = hit_damage - cover_armor_value
  cover_armor_value = cover_armor_value - 1 if cover_armor_value > 0

  # Armor and BTM is subtracted next, then damage applied to armor
  hit_damage = (hit_damage - hit_location_armor) - btm
  hit_damage = 1 unless hit_damage > 1
  armor[hit_location] = hit_location_armor - 1 if hit_location_armor > 0

  # Apply hit damage to location
  hit_damage = hit_damage * 2 if hit_location == :head
  location_damage[hit_location] = location_damage[hit_location] + hit_damage

  total_damage = total_damage + hit_damage

  dead = true if (total_damage > 40 || location_damage[:head] > 8)
  number_of_hits = number_of_hits - 1
end

puts "VICTIM IS DEFINITELY DEAD!!\nHere's the obituary:\n" if dead
puts "Victim is now at #{total_damage} damage"

limb_destroyed = false

location_damage.each do |location, amount|
  puts "#{location} took #{amount} damage."
  next if location == :torso
  puts "#{location} is DESTROYED!" if amount >= 8
  limb_destroyed = true
end

armor.each do |location, amount|
  puts "Armor on #{location} is now #{amount}"
end

puts "A mortal save is necessary due to the loss of one or more limbs." if (limb_destroyed && !dead)
puts "The cover was DESTROYED!" if behind_cover && !partial_cover && cover_armor_value == 0
