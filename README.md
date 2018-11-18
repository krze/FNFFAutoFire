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

## Armor rules
This calculator follows the 'New Armor Rules' from Cyberpunk 2020 2nd Edition. Layered armor will add a bonus depending on the difference between the outer layer and the inner layer.

Armor that is penetrated will have one SPS point deducted. All subsequent shots will be checked against the most up-to-date value.

## Cover rules
If you indicate the target is behind cover, the cover will protect the target for shots to all locations. The cover's SPS value is added to the outer layer of armor for all shots.

'Partial Cover' considers the target to be covered from the waist down. Shots that hit the legs will take into account the cover's SPS value.

## Fragile!
I made this in an hour. It expects integers and y/n values only. Be gentle.
