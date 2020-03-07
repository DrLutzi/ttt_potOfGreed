# ttt_potOfGreed
Pot of greed weapon mod for Garry's mod's [Trouble in Terrorist Town 2](https://github.com/TTT-2). It doesn't work with the original TTT gamemode as of now.

## Effect
Much like its Yu-Gi-Oh! counterpart, this item gives you two random items from the shop of your role.
Game design-wise, this item should be used when a shop contains a lot of different items modded in, as more often than not, some shop items go unused. The user will be able to enjoy an increased number of items in exchange for control over which items they want to buy.

## ConVar options
* ttt_potOfGreed_nbItemsToGive allows you to change the number of shop items given by the pot of greed (default is 2).
* ttt_potOfGreed_conflictPolicy determines what to do when an item received takes the same slot as an item already in the buyer's inventory (default is 2):
  * 0 - do nothing. The new item is lost.
  * 1 - override the current item. The user may still lose items if several items taking the same slot are obtained.
  * 2 - override the current item, and prevent next given items from overriding this new item (e.g. you won't get a slot 4 grenade after another slot 4 grenade, but you might get two slot 7 items).

  Changing this ConVar might be a way to balance the item if it is judged too weak or too strong. Using either 0 or 1 may result in players sometimes getting less items from the pot of greed; however, this can result in a frustrating outcome for players and severly penalize them over "bad RNG".
  
## How to install
Just like every other mod, download and extract this project in your addons folder. Make sure [TTT2](https://github.com/TTT-2/TTT2) is installed as well.
