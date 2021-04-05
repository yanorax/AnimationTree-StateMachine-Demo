# Godot AnimationTree StateMachine Demo Project

This project is a learning tool to better understand how the Godot AnimationTree Node with embedded StateMachine controls 3D animated models.

Compatible with [Godot Engine](https://godotengine.org/) v3.2.1+

## Preview

![swingtravel](https://user-images.githubusercontent.com/25857669/113559885-7b459680-9645-11eb-8f27-f09a335eaba2.gif)

## Line Paths
The outer line (red by default) marks the last path travelled.
The inner line is coloured depending on the state recorded at each point. By default: idle = magenta, ready = yellow, swing = green. 

## Controls
Click and hold any mouse button to rotate the camera. Mouse wheel zooms in and out. 

## Menu Options
- **Travel To**: Select the name of the state that the StateMachine will travel to. Click the **Go** button to start travelling.
- **Animation**: Select the name of the animation that plays when the StateMachine arrives at the swing state.
- **TimeScale**: Enter the time scale that the swing animation plays at. Hit the Enter key to confirm any changes.
- **Seek**: Enter the seek time that the swing animation will start at. Hit the Enter key to confirm any changes.
- **Paths**: Select **Add** to keep any existing line paths or select **New** to erase any existing paths when travelling begins from the idle state. The **Clear** button will immediately erase any existing paths.
- **Logs**: Toggle the display of the logs panel. The log records the time, state, rotation and position for the sticks journey through space. The log is tab delimited.

## Addons
[TrackballCamera for Godot](https://github.com/Goutte/godot-trackball-camera) by Antoine Goutenoir - [MIT License](https://github.com/Goutte/godot-trackball-camera/blob/master/LICENSE)

## Assets
[3D Model and Animations]() by yanorax - [CC BY 4.0 License](https://creativecommons.org/licenses/by/4.0/)

[Protractor](https://www.thingiverse.com/thing:1678) by ssd - [CC BY 4.0 License](https://creativecommons.org/licenses/by/4.0/) - Original converted to an image file.
