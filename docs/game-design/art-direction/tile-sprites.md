# Tile Sprites

The main game world is generated with a mix of terrain types including mountains, hills, forests, lakes and rivers. The baseline background in between is simply left black and doesn't require any sprites. The swamp, castle, and cave levels have specialized tile sets. Unique quest levels that come with specific character skins can also have their own tile sprites to fit the level design.

Environment tiles need to flow together, meaning edge construction must be done with extreme care and cleverness to balance "randomness" with seamless edges. They should not invoke obvious repeated tiles. This means using many variants, but all following a template of acceptable connection points.

Level entrances and special locations on the main map are often rendered as something like a 2x3 or 5x5 tile sprite on top of the underlying environment tiles (or simple black background).