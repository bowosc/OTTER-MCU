# The OTTER MCU
### Description
The OTTER is a full, assembly-programmable <a href="https://en.wikipedia.org/wiki/RISC-V">RISC-V</a> <a href="https://en.wikipedia.org/wiki/Microcontroller">Microcontroller</a>. I designed the OTTER in SystemVerilog, testing it on a <a href="[https://github.com/TheThirdOne/rars](https://www.trenz-electronic.de/en/Basys-3-Artix-7-FPGA-Board-academic/26083)">BASYS-3 FPGA board</a>.

### Programming the OTTER
The OTTER is fully programmable with RISC-V assembly, compiled to machine code. 
I wrote code to run on the OTTER using <a href="https://github.com/TheThirdOne/rars">RARS</a>. An example of a program run on the OTTER is in the Test Scripts folder.

I used assembly scripts for testing the OTTER and showing off its functionality with sorting algorithm implementations and such. 
Programming the OTTER is done by compiling assembly code to hexadecimal machine instructions to the "otter_memory.mem" file, which otter_memory.sv should point to.

The OTTER closely follows traditional RISC-V Microcontroller architecture: <br>
<img height="500px" alt="OTTER Architecture" src="https://github.com/user-attachments/assets/1a5d48d8-6b31-4121-a7e5-d83bf0763285" />

### Testing the OTTER
I used Xilinx Vivado to write and test the OTTER, preforming unit and end-to-end tests initially using the simulation timing diagram and later testing on a physical BASYS-3 board with the otter_wrapper (written by Prof. Hummel). The test diagrams I wrote and used are in a series of google docs at the moment, I'll upload those here when I get a chance.

A demonstration of the OTTER running a full test script: </br>
[![OTTER runs test script](http://img.youtube.com/vi/a2BAeu-PlXg/0.jpg)](http://www.youtube.com/watch?v=a2BAeu-PlXg) <br>
(http://www.youtube.com/watch?v=a2BAeu-PlXg)

### Architecture
I built the OTTER for a computer architecture course I took (CPE 233), submitting it with a small group for one of our final projects (we each built our own MCUs, demonstrating programmability on one of them). 
The OTTER's original architecture was designed by Prof. Joseph Callenes-Sloan and the assembler manual was written by Prof. James Mealy and Prof. Paul Hummel. 

All code in the OTTER is my own, with the exception of the otter_memory module written by Prof. Paul Hummel. 

***Please do not attempt to pass this code off as your own for your CPE 233 class.***
