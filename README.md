287 Project

Tested on Cyclone V FPGA

Goal: Produce a Mandelbrot Set Fractal generated in the FPGA Board and displayed to the monitor via a VGA cable


A Fractal is a graph that endlessly generates the same pattern over and over again while expanding or zooming out. 
Think of a triangle that is made of 3 smaller triangles that are themselves made of 3 smaller triangles. 
This pattern continues for ever. 

The Mandelbrot Set is one of the most reconizable fractal disigns and the one we choose to repilcate on the FPGA.
We sourced our design from a github what was written in SV (System Verilog) and converted it into verilog.
We had to debug issues converting the original code into verilog as SV has many function that verilog does not have. 
We also ran into issues where random or messed up images were displayed. These were often very interesting and would make some nice backgrounds.

![image4](https://github.com/user-attachments/assets/ec5f7950-ca09-4a90-adc1-bb16d293f247)

![image3](https://github.com/user-attachments/assets/d1defecd-a100-4084-a479-27c320ef05d1)

![image1](https://github.com/user-attachments/assets/d813345c-d7d4-4d3d-bfc0-628f0b4e8c88)

![image6](https://github.com/user-attachments/assets/bc6ca436-9eff-4e09-ba1e-323c4c00603e)

![image7](https://github.com/user-attachments/assets/ee31349f-8b33-4474-ad05-c97bdf956af9)

Comments inside code on what does what:

List of switches and which ones zoom in and out and move the image left, right, up, and down:

Finished Project:
![Mandelbrot on Monitor](https://github.com/user-attachments/assets/b9d430f0-c206-4c73-b210-48f75a9e75b9)

![Mandlebrot zoomed in and centered](https://github.com/user-attachments/assets/e46a039a-b0b3-49cb-bf4a-7c56d8b52633)
This is a zoomed in version of the Mandlebrot that is centered on the monitor by using the switches

![Mandelbrot zoomed in more](https://github.com/user-attachments/assets/3e31ae4f-3fe9-4a7e-bdcc-a25f5ff81fb3)



