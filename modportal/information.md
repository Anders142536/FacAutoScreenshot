[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/S6S73GCEL)
![img](https://cdn.discordapp.com/attachments/393475202341797908/844982702117879843/AreaScreenshotsHeader.png)

Screenshot any area perfectly snapped to the tile edges! Simply press the ![img](https://media.discordapp.net/attachments/393475202341797908/845094940073000960/unknown.png) *Area Select* button and define an area with *LMB* and *RMB*. The resolution is currently limited to 16385x16385 pixels, as this is the hardcoded limit by the game.

The given filesize estimate is a rough upper limit based on personal experiments.

![img](https://media.discordapp.net/attachments/393475202341797908/839242764297961502/fas-2.0.5area.png)


![img](https://cdn.discordapp.com/attachments/393475202341797908/844986165551693844/AutoScreenshotsHeader.png)

The whole base is screenshotted until an unreasonably big base size is reached. This feature is tailored for timelapse-videos. To minimize the performance impact the whole screenshot is dynamically split into several smaller screenshots, each taken one after the other, one per tick. This results in a time difference between the first fragment and the last fragment that can be many seconds, but in a timelapse this will not be noticeable. I offer my stitcher program to stitch those fragments back together, which is a part of this mod.

You can, of course, avoid the splitting by simply selecting the "Single tick Screenshots" checkbox. This will take a single screenshot of the whole base instead, but the performance *will* be impacted a lot more, possibly even causing several second long freeze frames or breaking multiplayer.

Currently, only the vanilla surface "nauvis" is supported.

![img](https://media.discordapp.net/attachments/393475202341797908/839242764981501972/fas-2.0.5auto.png)

The GUI shows the current status of the auto screenshots, the currently screenshotted surface as well all the necessary controls. You will see either a progress bar displaying the progress of the current screenshot or a timer until the next screenshot will be taken.

## Settings

* *Enable debug?*
Will make the logging more verbose. If you run into issues I will have an easier time understanding the issue with logs having this enabled.

## Image Stitcher

If you are separating your screenshots over several ticks by disabling the **Single Screenshot** option (which I heavily recommend) the mod will take hundreds, if not thousands of fragmented screenshots instead of just one big screenshot. Stitching those back together manually is unthinkable. Fortunatly, I wrote a program to automate this process for you! Head over to GitHub, where you will find instructions to get started: https://github.com/Anders142536/imageStitcher

For now the program is a pure command line program, as to my knowledge I am the only one using it. If required by users (like you?) I will gladly add some ui to make it easier to use.


## Background theory for nerds

Factorios engine does not allow for asynchronous screenshotting, meaning the game engine is *either* calculating your game *or* doing a screenshots. Furthermore it is not possible to do screenshots for two players at the same time, so screenshots for different players need to be queued. This causes quite some isues for the simple task of screenshotting your whole base. Factorios engine runs at 60 *update ticks per second* or 60 UPS. This means everything that happens in 1/60th of a second has to be calculated before a new image can be rendered for your screen. When you are playing the game the engine only touches the very necessary entities in the map that are required to render the next state of the game to render an image in, so a huge amount of entities can be ignored during that calculation. Basically, all entities whose state is about to change (visual state, logical state, etc.) or that are displayed on your screen are touched. When doing a screenshot of your whole base, however, *everything* is "on your screen", so the game has to touch every single one of them. This takes time, a lot actually.

While you will discover further below that you can set the mod to do a single tick screenshot, I strongly recommend not to. By default the mod takes way more, smaller screenshots by splitting the whole, resulting image into tiny fragments. This reduces the performance impact massively with the downside of thousands of small screenshots being produced instead of one. This splitting is dynamically adjusted to the total base size, so you do not have to worry about it. As a rough approximation this is based on total vertical and horizontal span of your base rather than entity count. 

This brings us to the two, unfortunatly unsolvable, problems of this feature.

1. If the splitting is too strong there will be quite a time difference between the first and the last screenshot. The (probably not used) limit by the settings I give you is 18 mins and 16 s, based on your **Increased Splitting** value.

2. If there are three players taking screenshots, all three of them have to take the screenshots one after another. If the settings are set so that every player takes a screenshot every 10 minutes and every screenshots takes roughly 4 minutes, the game will not be done with taking screenshots when the next round of screenshots is tried to be taken.

I should mention that screenshotting times in the minutes are not meant to be achieved with settings required on a mid to high end machine running factorio. This is purely allowed to give you the choice to do so. In my personal experience the point where using such a high splitting setting would be tempting is when the save is anyways so bloated that a stable UPS count can no longer be achieved. But still, the choice is yours.
