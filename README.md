### Description
The OTTER is a full, assembly-programmable <a href="https://en.wikipedia.org/wiki/RISC-V">RISC-V</a> <a href="https://en.wikipedia.org/wiki/Microcontroller">Microcontroller</a>. I designed the OTTER in SystemVerilog, testing it on a <a href="https://www.trenz-electronic.de/en/Basys-3-Artix-7-FPGA-Board-academic/26083">Basys-3 FPGA board</a>. 

### Programming the OTTER
The OTTER is fully programmable with RISC-V assembly, compiled to machine code. 
I wrote code to run on the OTTER using <a href="https://github.com/TheThirdOne/rars">RARS</a>. An example of a program run on the OTTER is in the Test Scripts folder.

I used assembly scripts for testing the OTTER's performance with matrix multiplication and implementations of various sorting algorithms. 
Programming the OTTER is done by compiling assembly code to hexadecimal machine instructions to the "otter_memory.mem" file, which otter_memory.sv should point to.

The original version of the OTTER closely followed a traditional RISC-V Microcontroller architecture, (shown below) but I recently restructured it to use a 5-stage pipeline instead. This sped throughput up by about 2.2 times per instruction (on average, of course, while running a very long series of test cases). </br>
<img height="400px" alt="OTTER Architecture" src="https://github.com/user-attachments/assets/1a5d48d8-6b31-4121-a7e5-d83bf0763285" />
</br>
I also added a 3-level memory cache system. As the device isn't implemented physically (it's a computer inside a computer for now), there's no memory access delay, and this change didn't really optimize anything. If you were to implement the OTTER on an actual chip, I estimate this would result in a significant boost for repeated access processes used in operations like ML training. I tested the otter with a simple matrix multiplication script I hand-wrote in assembly and noted the pipelined, cached OTTER performed several times better (taking into account cache delay) than the previous architecture.

### Testing the OTTER
I used Xilinx Vivado to write and test the OTTER, preforming unit and end-to-end tests initially using the simulation timing diagram and later testing on a physical Basys-3 board with the otter_wrapper (written by Prof. Hummel). The test diagrams I wrote and used are in a series of google docs at the moment, I'll upload those here when I get a chance.

A demonstration of the OTTER running a full test script: </br>
[![OTTER runs test script](http://img.youtube.com/vi/a2BAeu-PlXg/0.jpg)](http://www.youtube.com/watch?v=a2BAeu-PlXg) <br>
(http://www.youtube.com/watch?v=a2BAeu-PlXg)

### Architecture
I originally built a far simpler version of the OTTER for a computer architecture course I took (CPE 233), submitting it with a small group for one of our final projects (we each built our own MCUs, demonstrating programmability on one of them). Each member of the group built their own microcontroller, and we submitted one. This OTTER is an evolved version of mine.
The original version of the OTTER's architecture was designed by Prof. Joseph Callenes-Sloan. I have since diverged from this structure. All code in the OTTER is my own, with the exception of the otter_memory module written by Prof. Paul Hummel. 

***Please do not attempt to pass any version of this code off as your own for your CPE 233 / CPE 333 / Capstone project.***
