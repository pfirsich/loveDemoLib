# loveDemoLib
A library for gameplay (input) recording and playback using LÖVE2D.

You can use this library to make integrate a gameplay recording feature into your game without changing anything in your game code (except some initialization, finalization and an update()-call - see the example in main.lua for details) provided you use a fixed timestep loop (e.g. a deterministic simulation and ironically not used in main.lua).
