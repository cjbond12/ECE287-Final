Here’s the simplified version of the README, following the example structure and keeping it simple:

---

# **ECE287 Project: Mandelbrot Set Fractal Generator**

**Tested on:** Cyclone V FPGA  
**Goal:** Generate and display the Mandelbrot Set Fractal on a monitor through VGA.  

---

## **Overview**
The Mandelbrot Set is one of the most recognizable fractals, representing complex patterns formed by a simple recursive formula:

z_{n+1} = z_{n}^2 + c

This project calculates and displays the fractal using the FPGA hardware. Users can zoom into and pan around the fractal using switches on the FPGA board.

---

## **Switch Controls**
| **Function**         | **Control**  | **Description**                               |
|----------------------|--------------|-----------------------------------------------|
| **Regenerate**       | **KEY[3]**   | Resets the fractal to its default view.       |
| **Zoom Levels**      | **SW[0:2]**  | Selects zoom levels 7 levels(3b'000 - 3b'111).|
| **Move Horizonally** | **SW[3:5]**  | Shifts horizontally 7 levels(3b'000 - 3b'111).|
| **Move Veritcally**  | **SW[6:8]**  | Shifts vertically 7 levels(3b'000 - 3b'111).  |

---

## **How to Operate**
1. Load the compiled bitstream onto the Cyclone V FPGA using Quartus.
2. Connect the board to a VGA-compatible monitor.
3. Use the switches to explore the Mandelbrot Set:
   - Toggle **SW[0:2]** for zooming.
   - Toggle **SW[3:8]** for panning.
4. Press **KEY[3]** to regenerate based on switches set.

---

## **Image/Video**

Video of the Mandelbrot Generator: https://youtube.com/shorts/O06DklgDeBc?feature=share

Zoom level 1 and centered:
![VID_20241212_103231259_exported_13442](https://github.com/user-attachments/assets/8da0a9e2-6b52-450e-aed8-7cb7c46cdf4f)

Zoom Level 2 and centered:
![VID_20241212_103231259_exported_24995](https://github.com/user-attachments/assets/f34f0f41-3b91-479c-8d2d-eaf5d4b0567b)

Shifted left same zoom:
![VID_20241212_103231259_exported_31787](https://github.com/user-attachments/assets/2676c140-907c-486b-888e-fe6a68a5c0da)
![IMG_20241212_101257143](https://github.com/user-attachments/assets/6faea78a-ed24-44f0-8f44-33edefd6d289)
Bad image quality from phone.
