# VHDL Space Invaders

## Overview
This project is an implementation of the classic Space Invaders game using VHDL (VHSIC Hardware Description Language). It is designed to be run on FPGA boards and demonstrates the use of VHDL for developing a complete, functional game.

## Features

### VGA Display
- Generates video signals to display the game on a VGA monitor.
- Implements synchronization signals and pixel generation for the game display.

### Game Logic
- Includes game mechanics such as player movement, invader movement, shooting, and collision detection.

### Score Display
- Keeps track of and displays the player's score on the screen.

## File Structure

- `Counter_disp_Mensah_1.vhd`: Implements a counter display module.
- `Pong_graph_st_HW7_MENSAH.vhd`: Contains the graphical state machine for game display.
- `VGA_sync.vhd`: Handles VGA synchronization signals.
- `pong_top_1_MENSAH.vhd`: Top-level file integrating all components of the game.
- `Nexys-A7-100T-Masterlab_9c.xdc`: Constraint file for the Nexys A7-100T FPGA board.
- `.vscode/`: Directory containing Visual Studio Code settings for the project.
- `.dvt/`: the change log for the DVT IDE extension in VS code 

## Getting Started

1. **Clone the repository**:
    ```sh
    git clone https://github.com/KennedyMen03032731/VHDL_Space_Invaders.git
    cd VHDL_Space_Invaders
    ```
2. **Open in your VHDL simulation tool**: Use tools like ModelSim or Vivado to open the project files.
3. **Synthesize and implement**: Follow the steps to synthesize the design and implement it on an FPGA board.

## Acknowledgements

- Inspired (partially) by the classic Space Invaders arcade game.


## Screenshots


### VGA Display Schematic
![VGA Display Schematic](https://ibb.co/4JsNv2L)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
