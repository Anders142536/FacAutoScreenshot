*Anders* — Today at 19:22
oh, another question, is there a way to show a half-transparent image on a custom built gui?
*ルシファー せんぱい [LuziferSenpai] * — Today at 19:25
sprite button should be able todo it
I think
Or a normal sprite element
*Anders* — Today at 19:26
like, over the whole gui, kinda like a background image. This bg i have in IntelliJ is the closest I could think of

but i dont think that there can be two elements at the same spot on the screen, right?
*ルシファー せんぱい [LuziferSenpai] * — Today at 19:26
I dont think thaz is possible easily I would say
And yes there can?
You just put the other elements as children of the first
*Anders* — Today at 19:29
hm, so you are saying that i could maybe add a sprite, then add the whole rest of teh gui as child to the sprite?
*Xorimuth* — Today at 19:30
https://lua-api.factorio.com/latest/LuaGuiElement.html#LuaGuiElement.ignored_by_interaction not sure how you'd position it, but this might be useful
*Anders* — Today at 19:30
maybe ill play around with it a bit later. it would be hella fancy to customize the gui
yes, i think that would be necessary even
*Xorimuth* — Today at 19:30
agreed
*raiguard* — Today at 19:53
Put it in player.gui.screen and size it to the player's display resolution and scale. You can use GUI styles to make it semitransparent.

You'll have to set ignored_by_interaction on it as well, otherwise you won't be able to use any other GUIs that are behind it.
*Anders* — Today at 21:05
oh, i see, but wouldnt that render it over the whole screen rather than just the small gui frame i built for my mod?
*curiosity* — Today at 21:06
You can change the frame's graphics. But that is not very flexible.
*raiguard* — Today at 21:06
Oh, sorry, I thought that's what you wanted.
*Anders* — Today at 21:07
its an interesting idea, but not what i need in that case
*raiguard* — Today at 21:07
Yeah, you can mess with frame styles.
*curiosity* — Today at 21:09
Also, how do non-flow-like elements arrange their children? If they don't, it may be exploited to put a non-interacting element over everything.
*Anders* — Today at 21:10
If they don't
if they don't ?
*raiguard* — Today at 21:24
In the example of buttons, it just puts it at the top-left and doesn't flow it or anything. I usually add a flow as a child of the button, manually size it, then put the children in that flow.
*curiosity* — Today at 21:26
What *raiguard* said. They don't. Then you can just stretch a sprite inside an empty widget with widget's other child being your interface.