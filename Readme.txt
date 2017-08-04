Compiles fine on Xubuntu 16.04 with dosbox and wine installed.You need to 
find a DOS based 16-bit MASM to compile (this is why NASM is better for this 
here -> github.com/AndrewSomorjai/Bullet-NASM-code). 

Compiles with command:

  MASM barrel.asm

Links with:
  
  LINK barrel.obj
  
Use Wine to run and Dosbox should takeover from there.

Instructions to play:

Use the mouse to move the gun and use the left button to fire a bullet. 
Try to hit the target ( white rectangle) on the left.Press any key to end.
Most bugs have been fixed, this code is the MASM version similar to the 
NASM one, only the syntax is different.
