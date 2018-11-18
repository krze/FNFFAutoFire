# FNFFAutoFire
This is a dead-simple command line calculator for Cyberpunk 2020's FNFF automatic fire rules. This automatic fire calculator does not permit you to aim at a specific location.

You can use this calculator with single shots or 3-round-burst as long as you are not aiming for a specific location.

## How to use
Run with `ruby fnff_auto.rb` and answer the questions in the prompt.

At the end of the prompts, you'll get a result that looks like this:

```
Calculating damage of 13 against target's armor.
13 damage penetrated armor!
Target's BTM 0 has reduced the damage to 13
Applying 26 damage to HEAD

Results:

LEFT ARM took 0 damage.
RIGHT ARM took 0 damage.
LEFT LEG took 0 damage.
RIGHT LEG took 0 damage.
TORSO took 0 damage.
HEAD took 26 damage.
HEAD was DESTROYED!!

Cover remaining:
SPS armor is now 10

Victim's current damage is: 26
VICTIM IS DEFINITELY DEAD!!!

Victim is now DEAD 0. Every minute increases DEAD state +2.
If the victim reaches DEAD 10 without medical attention, sell em for parts!
```

Or, if you're well-armored, something like this:

```
First hit...

Applying damage of 13 against target's armor:

13 damage strikes Armor Layer 1 in the TORSO
Armor Layer 1's SPS value is is 12
Total hit damage is 13
Reduced hit damage is 1
1 damage penetrated layer 1 to hit TORSO
Armor Layer 1's SPS value in location TORSO is now 11
1 damage penetrated armor to hit the target!
Target's BTM 0 has reduced the damage to 1
Applying 1 damage to TORSO

Next hit...

Applying damage of 14 against target's armor:

14 damage strikes Armor Layer 1 in the LEFT LEG
Armor Layer 1's SPS value is is 12
Total hit damage is 14
Reduced hit damage is 2
2 damage penetrated layer 1 to hit LEFT LEG
Armor Layer 1's SPS value in location LEFT LEG is now 11
2 damage penetrated armor to hit the target!
Target's BTM 0 has reduced the damage to 2
Applying 2 damage to LEFT LEG

Next hit...

Applying damage of 14 against target's armor:

14 damage strikes Armor Layer 1 in the TORSO
Armor Layer 1's SPS value is is 11
Total hit damage is 14
Reduced hit damage is 3
3 damage penetrated layer 1 to hit TORSO
Armor Layer 1's SPS value in location TORSO is now 10
3 damage penetrated armor to hit the target!
Target's BTM 0 has reduced the damage to 3
Applying 3 damage to TORSO

Next hit...

Applying damage of 12 against target's armor:

12 damage strikes Armor Layer 1 in the RIGHT ARM
Armor Layer 1's SPS value is is 12
Total hit damage is 12
Reduced hit damage is 0
Damage failed to penetrate.
Target's BTM 0 has reduced the damage to 0
Target still needs to take 1 damage.
Applying 1 damage to RIGHT ARM

Next hit...

Applying damage of 13 against target's armor:

13 damage strikes Armor Layer 1 in the RIGHT LEG
Armor Layer 1's SPS value is is 12
Total hit damage is 13
Reduced hit damage is 1
1 damage penetrated layer 1 to hit RIGHT LEG
Armor Layer 1's SPS value in location RIGHT LEG is now 11
1 damage penetrated armor to hit the target!
Target's BTM 0 has reduced the damage to 1
Applying 1 damage to RIGHT LEG

Results:

LEFT ARM took 0 damage.
RIGHT ARM took 1 damage.
LEFT LEG took 2 damage.
RIGHT LEG took 1 damage.
TORSO took 4 damage.
HEAD took 0 damage.

Layer 1 remaining:
HEAD armor is now 12
TORSO armor is now 10
LEFT ARM armor is now 12
RIGHT ARM armor is now 12
LEFT LEG armor is now 11
RIGHT LEG armor is now 11

Victim's current damage is: 8

Your damage of 8 indicates you must check the following rolls, in order:

STUN -1

For each roll, subtract the penalty listed from a D10 roll.
```

## Armor rules
This calculator follows the 'New Armor Rules' from Cyberpunk 2020 2nd Edition. Layered armor will add a bonus depending on the difference between the outer layer and the inner layer.

Armor that is penetrated will have one SPS point deducted. All subsequent shots will be checked against the most up-to-date value.

## Cover rules
If you indicate the target is behind cover, the cover will protect the target for shots to all locations. The cover's SPS value is added to the outer layer of armor for all shots.

'Partial Cover' considers the target to be covered from the waist down. Shots that hit the legs will take into account the cover's SPS value.

## Fragile!
I made this in an hour. It expects integers and y/n values only. Be gentle.
