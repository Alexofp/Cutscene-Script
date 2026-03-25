# Cutscene-Script
A simple bring-your-own-batteries scripting language for Godot 4.x designed for cutscenes/dialogues

https://github.com/user-attachments/assets/dd358057-0ffa-4c6d-a352-d674e3279100

Script example:
```gdscript
say "You approach the Slot Machine!"

> askloop
ask "What do you wanna do?"
answer "Pull for 5$", start5
answer "Step away", leave
waitAnswer

> start5
if get.money < 5: jump notEnough
inc.money -5
say "You insert 5$ and pull the lever..."

if RNG.chance(10): jump jackpot
else: if RNG.chance(55): jump won

say "Aw, you lost! Better luck next time."
jump askloop

> won
inc.money 10
say "YOU WON 10$! Congrats!"
jump askloop

> jackpot
inc.money 30
say "[rainbow]JACKPOT!!![/rainbow] You won 30$!"
jump askloop

> notEnough
say "Not enough money! You're a poor starving game developer!"
jump askloop

> leave
stopScript

```
