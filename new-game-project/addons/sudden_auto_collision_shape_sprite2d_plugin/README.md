# SuddenSprite2D

## Overview
This is project contains the SuddenSprite2D plugin and demo. SuddenSprite2D is a Sprite2D 
that generates collision polygons for its texture at runtime and in Godot Editor. 

It was tested on **Godot 4.6**. It should work on some previous versions though.

# Setup
- After installing the plugin, the SuddenSprite2D will be available on **Create New Node** window.

#Important Notes
- Feel free to extend the SuddenSprite2D. Check out the Demo in this repository.
- SuddenSprite2D exposes an **area_entered()** signal and methods to get the overlapping areas and bodies.
- You can also set collision layers and masks.
- Graphics used in the Demo: https://kenney.nl/assets/platformer-characters 
- **Don't forget to reload the scene after add new SuddenSprite2Ds to it or changing textures
  so they collision polygons are visible on the Editor.**

## Visual Sample
![Visual Sample](https://github.com/suddenhost/godot-auto-collision-polygon-sprite2d/blob/main/CollisionPolygons.png)
