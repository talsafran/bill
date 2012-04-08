-----

Tal Safran
Computer Systems Organization (Honors)
V22.0201.001

-----

# Game Project Proposal #

## “Bill's Last Job”
(working title) ##


It is 2056, the year of the Twelfth Bit. In an act of desperation to regain his former grandeur, one-time billionaire William Henry “Bill” Gates III has stolen the cryogenically frozen brain of Steve Jobs, which contains the secrets to the ubiquitous Mac OS L operating system. 

In order to extract the information, however, Gates will need to deploy his Brain Ushering Gun (B.U.G.) to transport Jobs’ chilled cerebrum through the underground tunnels connecting Apple Headquarters to his subterranean laboratory in Redmond, Washington. This will be no easy task, as the tunnel system will surely contain many perilous and oddly pixilated obstacles along the way.


### User-Level Description ###
The objective of this game is to launch Steve Jobs' brain from one tunnel to the next, until reaching the lab in Redmond. This is done by correctly positioning and aiming the B.U.G. from the launch pad so the brain safely bypasses all of the obstacles and reaches the target. In later, more advanced levels, some of obstacles will be mobile, meaning you will need to time your shot with precision.

In each level, you will begin with the B.U.G. placed on the launch pad. Using the arrow keys on the keyboard, you will maneuver the UPL within this area (but not outside of it) and then, using a toggle button, aim the cannon in one of six directions (Northeast or Southeast, by either 22.5, 45, or 67.5 degrees), with the purpose of hitting the target. Hitting the spacebar launches Jobs' brain. If the brain reaches the target, you will advance to the next level. Otherwise, your failed attempt will be recorded and you will need to try again. Also, each launch will have a maximum distance. This means that if the brain does not reach the target after traveling a certain extent, it will “explode” and you will need to try again (this will prevent the brain from continuing to ricochet uselessly if the aim is not right, and also prevent “cheap” solutions to the puzzle).

Reaching the target will be more challenging than it may seem at first. Often, you will need to have the brain bounce off of several walls and obstacles for it to reach the target (see Figures 1 and 2). In more advanced stages, some of the obstacles will be moving, so the challenge will be even greater.

The game will incorporate statistics and record-keeping  as an incentive for competition and repeated play (i.e., “Tal completed Level Two in 4 attempts”). There will be a “High Scores” feature, displaying those players who completed the game (as well as each individual level) with the fewest attempts.


### Implementation ###
This game will implement ASCII graphics and will be played using the keyboard. Sound effects will be used for various actions in the game, as well as for the opening and closing sequences.

Basic features: movement of B.U.G., movement of launched brain, sound effects and music, score-keeping and display of high-scores, opening/closing sequences.
Advanced features (some ideas, in order of priority): moving obstacles, tracing of launch trajectory, customizable color schemes, random level generator, animated opening/closing sequences.

