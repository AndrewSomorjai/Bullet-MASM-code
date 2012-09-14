;Copyright (C) Sept 14th 2012 Andrew Somorjai

;Permission is hereby granted, free of charge, to any person obtaining a copy of this 
;software and associated documentation files (the "Software"), to deal in the 
;Software without restriction, including without limitation the rights to use, copy, 
;modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
;and to permit persons to whom the Software is furnished to do so, subject to the 
;following conditions:

;The above copyright notice and this permission notice shall be included in all 
;copies or substantial portions of the Software.

;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
;INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
;PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
;HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
;CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
;OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;Program description
;A simple assembly language program which is a game called "Bullet".
;Use MASM to compile and link. It has bugs and the collision
;detection doesn't work. It might help someone as
;a reference for various low level functions and thats about it;
;changing anything in it is really time consuming and prone
;to creating even more bugs.

extrn putdec:near, getdec:near
TITLE  INTERNAL EXAMPLE
  .MODEL SMALL 
  .STACK 100H
  .DATA
      outtime dw 2 dup(0)
	COUNT          DW     0
	BUTTON	   DW     0
	YCOOR		   DW	    0
	n		   Dw     0
	y		   db     0
	eight		   db     8
	x	         db     0 ;x coordinate of plane is initialized to 315
	temp		   DB	    0
	color		   DB     0
	eraser         dw     ?
	positionX      dw	    49h 
	positionY      dw     0
	fired		   dw     0
	excode         DB     0
	clok           DB     02Ch
	temprandom     DW     0
	active         db     0
	EIGHTY         DB     80
	TIMESTAMP      DB     0
      seconds         db     0
      target         db     ?
	gamescore      db     0
	lives          db     1
  .CODE
MAIN3 PROC;------------------------------------------------------------------------------------------------

WaitForKeyMAIN3:

	MOV AX, @DATA
	MOV DS, AX	
	
	;mov [gamescore], 0
	CALL SUB1	  ;contains the calls to mouse, pause and various other calls
      CALL ERASEPLANE
  	mov     ah,1
        int     16h
        jz      WaitForKeyMAIN3

	MOV AX, 4C00H
	INT 21H
MAIN3 ENDP;------------------------------------------------------------------------------------------------

SUB1  PROC;------------------------------------------------------------------------------

	CALL VIDEOMODE3H     ;set mode 03h
	CALL ERASEPLANE       ;eraseplane is called to clear memory with black
	CALL INITIALIZEMOUSE  ;initialize mouse
WaitForKey:
	CALL ERASEPLANE
	call DRAWPLANE ;draws a blue box and has a mouse call which checks for button clicked	
	call randomobject
	call bulletrandomobject
	mov ax, 2
	CALL PAUSE
	  mov     ah,1
        int     16h
        jz      WaitForKey
	
	RET
SUB1  ENDP;-------------------------------------------------------------------------------
PAUSE PROC;-------------------------------------------------------------------------------

            push ax                 ; ax = # ticks to delay 
            xor ax, ax              ; bios get time 
            int 1ah                 ;  
            pop ax                  ; 
            add dx, ax              ; low byte 
            mov outtime, dx         ; save low 
            xor ax, ax              ; 
            adc ax, cx              ; high byte         
            mov outtime + 2, ax     ; save high 
not_yet:             
            xor ax, ax              ; bios get time 
            int 1ah                 ;  
            cmp al, 0               ; has midnight passed 
            jne midnight            ; yup? reset outtime 
            cmp cx, outtime + 2     ; if current hi < outtime hi 
            jb  not_yet             ; then don't timeout 
            cmp dx, outtime         ; if current hi < outtime hi... 
                                    ; AND current low < outtime low 
            jb not_yet              ; then don't timeout 
            jmp its_time            ; 
midnight:                        
            sub outtime, 00B0h      ; since there are 1800B0h ticks a day 
            sbb outtime + 2, 0018h  ; outtime = 1800B0h - outtime 
            jmp not_yet             ; 
its_time:                             
            ret                     ; 

PAUSE ENDP;------------------------------------------------------------------------------------
mouse proc;----------------------------------------------------------------------------------    	
      sub dx, dx
	sub bx, bx
	mov ax,03h ;get button status
	int 33h
	mov [button],bx	
	mov [y],dl
      
	cmp [fired],1
	je   exitmouse

	cmp [button], 0001b
	je firebullet
	jmp exitmouse
firebullet:
	mov [fired], 1
	mov [positionX], 49h 
      shr dl,1
      shr dl,1
      shr dl,1
	mov [positionY], 	dx
exitmouse:

	ret
mouse endp;------------------------------------------------------------------------------------
INITIALIZEMOUSE PROC;------------------------------------------------------------------------------------------------
	mov ax,00h ;initialize the mouse
	int 33h
	
	mov ax,04h ; set pointer to 0,0
	mov bx,0
	mov cx, 0
	int 33h	
	ret
INITIALIZEMOUSE ENDP;------------------------------------------------------------------------------------------------

VIDEOMODE3H proc;------------------------------------------------------------------------------------
	mov ah, 0
	mov al, 3h	; 80x25
	int 10h	
	RET
VIDEOMODE3H endp;------------------------------------------------------------------------------------
DRAWPLANE PROC;------------------------------------------------------------------------------------
      call score
	CALL mouse	
	call bullet
	 mov [x], 46h
	
      
;drawplane
    	  MOV AH, 6          ; scroll up function
	  mov al,[y]         ;y position of mouse 
	  shr al, 1
	  shr al, 1
	  shr al, 1
	  mov [y],al

	  mov ch, al
	  MOV cl, [x]        ; x at 70 of 80
	  
	  
	  mov dx, cx      
        add dl,5
	  
	   
        MOV BH, 10010000b  ;0000111b  ; white chars on black background
        MOV AL, 0          ; scroll all lines
        INT 10H 
	ret
DRAWPLANE ENDP;------------------------------------------------------------------------------------
eraseplane proc;------------------------------------------------------------------------------------------------

	 ; clear window to black
    ;
        MOV AH, 6         
        MOV CX, 0000     
        MOV DX, 8025   
        MOV BH, 00000000b 
        MOV AL, 0         
        INT 10H	
ret
eraseplane endp;------------------------------------------------------------------------------------------------
bullet proc	;------------------------------------------------------------------------------------------------


	cmp [fired],1
	je bulletfired
	jmp exitbullet
 									;writes a block into memory
bulletfired:
	sub [positionX], 2	
	cmp [positionX], 4
	jle cancelbullet
   
  	  MOV AH, 6        					
	  MOV CX, [positionY]
	  mov CH, CL
	 
	  MOV dx, [positionX] 
	  mov cl, dl
	  mov dx, cx      
        add dl, 4
        MOV BH, 10110000b  					
        MOV AL, 0        					
        INT 10H
	jmp exitbullet


cancelbullet:
	mov [fired], 0
	mov [positionX], 49h  
	
exitbullet:

	ret
bullet endp;------------------------------------------------------------------------------------------------
bulletrandomobject proc


	sub ax, ax

	mov ax, [positionX]
	cmp al, 11          ;if target y and positionX are equal and positionX is less than 10
	jle score1
;else     
	jmp exitbulletrandomobject
	score1:
	mov ax, [positionY]
	mov bl, [target]
	cmp al, bl
	je score2
	jmp exitbulletrandomobject
score2:
	inc [gamescore]
	mov [fired], 0
	mov [positionX], 49h 

exitbulletrandomobject:
	ret
bulletrandomobject endp
randomobject proc;------------------------------------------------------------------------------------------------
	sub ax,ax
      ;get time seconds passed since last call 
	call gettime
	mov al, [seconds]
	mov ah, [timestamp]
	sub al, ah
	cmp al, 5
	jle createtarget
	jmp drawtarget
createtarget:
	call gettime
	mov al, [seconds]
	mov [timestamp],al 
	                   ;This sets the y coordinate and the timestamp for the instance of the object, almost like OOP.
	mov [target], al
		
drawtarget:
	   
        MOV AH, 6        
        MOV cl, 0ah       
	  mov ch, [target]  ;contains y coordinate of object called the target   temp
	  mov dl,cl
	  add dl,4
	  mov ch,dh
	
        MOV BH, 11110000b ; 
        MOV AL, 0         ; 
        INT 10H	
	
	ret
randomobject endp;------------------------------------------------------------------------------------------------
gettime proc;------------------------------------------------------------------------------------------------
	
	mov ah,[clok]
	int 21h
	mov [seconds], dh   ;save seconds for countdown
	             ;this generates a random number between 0-25
	cmp dh,10
	jle skip     ;if seconds is less than or equal to ten then skip this step, else get a -n for random value
	shr dh,1     ;this insures that any number 0-59 will be displayable if n/2-5 is at minimum 25, n - seconds 
	sub dh,5
 skip:
     
ret
gettime endp;------------------------------------------------------------------------------------------------
score proc;------------------------------------------------------------------------------------------------
;draw score
    
	mov ah, 1h ;make cursor vanish
	mov ch, 20
	int 10h


	; move cursor
	
        MOV AH, 2         ; move cursor function
        MOV DX, 0000H     ; center of screen
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'S'       ; character is 'S'
        INT 10H

	      ; move cursor
        MOV AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'C'       ; character is 'C'
        INT 10H

	     ; move cursor
        MOV AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'O'       ; character is 'O'
        INT 10H
       
	      ; move cursor
        MOV AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'R'       ; character is 'R'
        INT 10H

	    ; move cursor
        MOV AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'E'       ; character is 'E'
        INT 10H
	
	
		    ; move cursor
        MOV AH, 2         ; move cursor function
        mov dl, 7
        XOR BH, BH        ; page 0
        INT 10H


	 ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
	  cmp [gamescore], 9
	  je resetscore
	  jmp nextcore
resetscore:
	  mov [gamescore],0
	  inc [lives]
nextcore:		
	  add [gamescore],48
        MOV AL, [gamescore]       ; 
        INT 10H
	sub [gamescore], 48
	;mov al,[gamescore]
        ;call putdec

exitscore:
   
ret
score endp;------------------------------------------------------------------------------------------------
END   MAIN3