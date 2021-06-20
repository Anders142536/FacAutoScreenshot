* Tracking cursor could be enabled by checking the cursor position every tick. Should be accessible on the cursor stack of the player
* start tracking once one of the two positions are set
* after the first position is set, create selection rectangle with the last set position and the current cursor position
* selection tool allows dragging without influencing anything next to the player or dragging the map
* alternatively have a capsule firing at the cursor position every tick with invisible projectiles and no sound.
* release of drag could be tracked by https://lua-api.factorio.com/latest/events.html#on_player_selected_area event