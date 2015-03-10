# loveDemoLib
A library for gameplay (input) recording and playback using LÖVE2D.

You can use this library to integrate a gameplay recording feature into your game without changing anything in your game code (except some initialization, finalization and an update()-call - see the example in main.lua for details) provided you use a fixed timestep loop that is deterministic. With a little extra work it will probably also work with variable timestep (determinism is still required).

I talk about this here: http://theshoemaker.de/2015/03/sudohack-update-replay-system/
