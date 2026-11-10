# CSE3120Contest

# Sinking Submarine - Flappy Bird Style Game

## Team - Dylin Irons, Dominick Morales

A console game written in MASM assembly with the Irvine32 library. Your submarine keeps rising, so tap to dive and steer it through the gaps in the rocks without hitting the surface or the seabed.

## How to compile and run

Requirements:
- Windows with Visual Studio. Then, whichever options you choose, it needs to install MASM.
- The Irvine32 library in `C:\Irvine`

Steps:
1. Open `Project.sln` in Visual Studio.
2. Select the `Debug` configuration and the `Win32` platform
3. Build with **Build > Build Solution**.
4. Run with **Debug > Start Without Debugging**.

Alternatively, you might need to use project.vcxproj in order for it to work.

## Controls

- SPACE or W: rise
- ESC: quit
- R: play again after game over
