@UI/HUD/Spedometer/spedometer.tscn @UI/HUD/Spedometer/spedometer.gd 

%SpeedText_RichTextLabel needs to have its text updated with the integer of our current speed. I want the color to be cyan (0R 255G 255B) from 0-100mph, and then from there i want it to lerp colors--from cyan to pure green (lose blue), then from green to yellow (gain red), then from yellow to red (lose green), then from red to magenta (gain blue). the lowest color (cyan) goes from 0-100 mph, and the highest color is anything over 1000mph. ignoring 0, i want the floor and ceiling (100,1000) adjustable exports on the spedometer so i can tweak it how i like. the rest should interpolate smoothly between those ranges. the color to change is the font Theme Override "default color".

then the boost light logic:
%LightTexture and its one child (GlassTubes, doesn't really matter what it's called) both change their self-modulate to the color
%PointLight2D also sets its color.
as they change color they should lerp from white to the color, or whatever color they were to the new color (default to white), and while they do that the alpha of the PointLight2D's color also needs to lerp--down to 0 and back up to 1 between each color change.
%LargeIcon_ALPHA also needs to map its self modulate Alpha to 0 during White color and to 1 for any other color, going down to 0 and back up just like the light's does.

make spedometer a tool script and have it so there is an export LightColor that I can tweak the light and see how all of the aforementioned logic reacts to changes. the color I choose there should be what is changed by external input. in other words, this export field will be the source of truth for the current light color, driving the modulates and alphas of all those other components.

remember to abide by the 4 pillars architecture outlined in the docs. this should all be responsive to signals.

### fill bar logic

i traced a multi-segmented pixel line to measure the length of my odd spedometer bar, so we're going to do some programmatic procedural animation of some clipping masks to cover it properly. we're going to be hiding/showing, moving, and rotating several child clipping masks as we progress past certain thresholds of percentage. arriving at a certain percentage should enforce the following:

fill 1 starts at:
-75 189, 0 deg (starting position)
then goes to 
-26 189, 0 deg
from pixels 0 to 49 / 260 (the first 18.46% of progress)

then starts rotating from 
-26 189, 0 deg
to 
-26 189, -20 deg (final position)
from pixels 49 to 60 / 260 (up to 23.077%)

23 %

fill 1 stops moving (still active tho)
fill 2 appears instantly

fill 2 starts at:
53 193, 70 deg (starting position)
then rotates to 
53 193, 45 deg
from pixels 60 to 66 / 260 (up to 25.38%)

then goes from
53 193, 45 deg
and slides to:
137, 110, 45 deg (final position)
from pixels 66 to 150 / 260 (up to 57.7%)

57.7 %

fill 2 stops moving (still active tho)
fill 3 appears instantly

fill 3 starts at
137, 110, 45 deg (starting position)
then rotates to
137, 110, 0 deg
from pixels 150 to 160 / 260 (up to 61.54%)

then goes from
137, 110, 0 deg
then rotates to
137, 111, -45 deg
from pixels 160 to 170 / 260 (up to 65.39%)

then goes from
137, 110, 0 deg
then slides up to
48, 22, -45 deg (final position)
from pixels 170 to 260 / 260 (up to 100%)

100 %

...

large jumps in percentage should instantly hide fills that are outside of that percentage range. for instance, if you go from 100% to 5% instantly, fill 2 and 3 should go down to their starting states where they hide instantly and then reset their transforms to their starting positions. if you jump from 5% to 40%, then fill 1 should instantly jump to its final position, 3 is disabled, and 2 goes to the lerped position/rotation between the 2 surrounding checkpoint positions.