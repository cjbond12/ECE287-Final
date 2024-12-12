# **ECE287 Project: Mandelbrot Set Fractal Generator**

---

## **Project Overview**

**Tested on**: Cyclone V FPGA  
**Goal**: To generate and display the Mandelbrot Set Fractal on a monitor via a VGA connection, leveraging the computational capabilities of the FPGA.

A fractal is a graphically recursive pattern that repeats itself at various scales. The **Mandelbrot Set** is a particularly famous fractal, known for its intricate and infinitely repeating boundary structure. This project focuses on implementing this fractal using **Verilog** for real-time rendering on an FPGA.

---

## **Design Details**

### 1. **Algorithm and Computation**:
   - The **Mandelbrot Set** is computed using the iterative formula:
     ```
     z(n+1) = z(n)^2 + c
     ```
     where:
     - `z` is a complex number represented by `z = a + bi`.
     - `c` corresponds to the pixel's coordinate in the complex plane.

   - Registers track the coordinates, iterations, and escape conditions for each pixel.

### 2. **Fixed-Point Arithmetic**:
   - The project uses a **fixed-point format** (10 integer bits and 22 fractional bits) for precision.
   - Calculations include:
     - **Width and height scaling** for zoom.
     - **Step sizes** for navigating the fractal's coordinate space.
     - Real and imaginary parts of the iterative function.

### 3. **State Machine Control**:
   - An efficient **state machine** manages the fractal generation:
     - **IDLE**: Waits for the `start` signal.
     - **INIT**: Resets and initializes registers.
     - **XLOOP/YLOOP**: Iterates over rows and columns of pixels.
     - **ITERLOOP**: Performs the fractal calculation for each pixel.
     - **PLOT**: Sends the calculated pixel color to the VGA display.
     - **DONE**: Signals the end of computation.

### 4. **VGA Display Integration**:
   - Supports **320x240** and **160x120** resolutions. (I haven't tested 160x120 at all)
   - Color coding is based on the iteration count, with customizable palettes: (Gets to
     - Low iterations: Black and Blue.
     - Higher iterations: Green, Cyan, Purple and White. 
   - Implements a double-buffered approach for seamless updates.

### 5. **User Interaction**:
   - **Switches (SW)** control zoom, horizontal, and vertical offsets:
   - These are all scaled levels from bit 000 to bit 111 (7 levels)
     - SW(0-2): Zoom levels 
     - SW(3-5): Horizontal shifts.
     - SW(6-8): Vertical shifts.
   - **Key(3)**: Reset to regenerate the image after adjustments.

### 6. **Debugging**:
   - LED indicators:
     - Show computation progress.
     - Indicate plotting activity.

---

## **Challenges and Debugging**

### **System Verilog to Verilog Conversion**:
   - The original design, written in System Verilog, required conversion to Verilog. This involved replacing unsupported features and debugging numerous syntax and compatibility issues.

### **VGA Output Artifacts**:
   - Initial tests showed random patterns or distorted images. Adjusting the VGA clock signals and memory addressing resolved most issues.

### **Algorithm Tuning**:
   - Missteps in arithmetic operations created unintended fractal patterns, resulting in aesthetically unique but incorrect images. These artifacts, such as the "Eye of Sauron," became interesting by-products.

---

## **Visual Outputs**

1. **Initial Patterns**:
   - Unintended fractal artifacts created during debugging:
     - Artifacts such as the "Eye of Sauron."
     - Unique shapes from misaligned VGA outputs.

2. **Final Results**:
   - The Mandelbrot Set fractal is displayed with smooth zooming and shifting capabilities.
   - Adjusted color palettes enhance contrast and visual appeal.

## **Conclusion**

This project successfully demonstrates the computational power of FPGAs by generating a complex fractal in real-time. The combination of fixed-point arithmetic, efficient state machine design, and VGA integration makes this an engaging and visually appealing project. Despite challenges with the initial implementation, the final design is robust, customizable, and capable of producing high-quality fractal visualizations.
