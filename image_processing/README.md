---

# Real-Time Sobel Edge Detection on FPGA (DE10-Lite)

This project implements a real-time **Sobel Edge Detection** filter using Verilog HDL. The system is designed for the **Intel/Terasic DE10-Lite (MAX 10)** FPGA board. It processes a grayscale image stored in on-chip memory and outputs the edge-detected result via VGA at a 640x480 resolution.

##  Project Demo

[![Video Title](https://img.youtube.com/vi/KiFZCrfJaR8/0.jpg)](https://www.youtube.com/watch?v=KiFZCrfJaR8)

---

##  Architecture Overview

The system utilizes a pipelined architecture to perform spatial convolution in real-time. The data flow is as follows:

1. **Image Storage**: An 8-bit grayscale image is stored in the FPGA's internal block memory (ROM) using a Memory Initialization File (.mif).
2. **Line Buffering**: Four `lineBuffer` modules are used to create a sliding window. While three buffers provide data for a 3x3 image patch, the fourth is simultaneously filled with new pixel data to ensure continuous processing.
3. **Patch Generation**: The `imagePatchProvider` module manages the line buffers and coordinates the extraction of a 3x3 pixel neighborhood for every clock cycle.
4. **Convolution Engine**: Two `conv` modules work in parallel to compute the horizontal ($G_x$) and vertical ($G_y$) gradients using the Sobel kernels.
5. **Gradient Calculation**: The `sobel` module computes the final edge magnitude by calculating the sum of absolute values: $|G_x| + |G_y|$.
6. **VGA Sync**: The `imageProcessingTop` module synchronizes the filtered pixel data with the VGA controller, driving a 640x480 @ 60Hz display (25MHz pixel clock).

---

##  File Descriptions

| File | Description |
| --- | --- |
| **`imageProcessingTop.v`** | The top-level module that interconnects the ROM, the Sobel processor, and the VGA controller. |
| **`imagePatchProvider.v`** | Logic to manage line buffers and provide a 3x3 pixel window to the convolution engine. |
| **`sobel.v`** | The core arithmetic module that combines $G_x$ and $G_y$ to find edge magnitude. |
| **`conv.v`** | Performs the 3x3 convolution operation using signed arithmetic. |
| **`lineBuffer.v`** | A FIFO-based shift register used to store a single row of image pixels. |

---

##  Hardware Specifications

* **FPGA**: Intel MAX 10 10M50DAF484C7G
* **Resolution**: 640 x 480 pixels
* **Pixel Clock**: 25.175 MHz
* **Input Color Depth**: 8-bit Grayscale
* **Output Interface**: VGA

---

##  How to Run

1. **Clone the repository**:
```bash
git clone https://github.com/mukundramanuj/FPGA_Projects.git

```


2. **Open in Quartus**: Open the project file in Intel Quartus Prime.
3. **Generate ROM**: Ensure your `.mif` file is correctly linked to the ROM IP.
4. **Compile**: Run the Full Compilation.
5. **Program**: Use the Quartus Programmer to flash the `.sof` file to your DE10-Lite board.
6. **Display**: Connect a VGA monitor to see the real-time edge detection.

---

##  Author

**Mukund Ramanuj** - [GitHub Profile](https://www.google.com/search?q=https://github.com/mukundramanuj)