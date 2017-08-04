TITLE  BULLET 
.MODEL SMALL 
.STACK 100H
.DATA
  
    button         				dw       0	
	bullet_fired	        	dw       0
	gamescore      				db       0	
	outtime 					dw       2 dup(0)
	bullet_x    				dw      73
	bullet_y      				dw       0
    random_y_position        	db       0	
	target_y         			db       0	
	previous_random_y_position  db       0
	ticks						dw		 2
	mouse_x	         			db       0 
	mouse_y	            		db      10
	
  .CODE
main PROC;------------------------------------------------------------------------------------------------

	mov AX, @DATA
	mov DS, AX		

	call VIDEOMODE3H     ;set mode 03h
	call INITIALIZEMOUSE  ;initialize mouse
	
AsyncWaitForKey:

	call BLACK_SCREEN; Clears screen to black
	call BULLET;Updates bullet position and draws the new position
	call TRIGGER;Checks the mouse position and button clicked
	call GUN ;Draws a blue box using the mouse input for position on mouse_y axis
	call RANDOM_TARGET_POSITION;This function uses a time dependent random number 0-25 to draw the target
	call BULLET_AND_RANDOM_TARGET_COLLISION;Checks the position of the bullet and target to determine if a collision event exists.
	call SCORE;Draws the score
	call PAUSE;Temporarily causes this loop (AsyncWaitForKey) to freeze for 2 ticks ( there are about 18.2 ticks per second)
	
	mov     ah, 01h
    int     16h
	jz      AsyncWaitForKey	

	 ;text mode
    mov     ax, 0003h
    int     10h  
	
	MOV 	ax, 4C00h
	INT 	21h

main ENDP;------------------------------------------------------------------------------------------------
GUN PROC;------------------------------------------------------------------------------------
    	
		mov [mouse_x], 70 		
		mov al, [mouse_y]         ;mouse_y position of mouse 
		shr al, 1
		shr al, 1
		shr al, 1
		mov [mouse_y], al
		mov ch, al
		mov cl, [mouse_x]        ; mouse_x at 70 of 80			  
		mov dx, cx     
		add dl, 5	  
		mov ah, 6          ; scroll up function   
		mov bh, 10010000b  ;0000111b  ; white chars on black background
		mov al, 0          ; scroll all lines
		int 10h 	
ret
GUN ENDP;------------------------------------------------------------------------------------
TRIGGER proc;----------------------------------------------------------------------------------    	
	      
		xor dx, dx
		xor bx, bx
		mov ax, 03h ;get button status
		int 33h
		mov [button], bx	
		mov [mouse_y], dl
		  
		cmp [bullet_fired],1
		je   exit_trigger

		cmp [button], 0001b
		je firebullet
		jmp exit_trigger
		
firebullet:
	
		mov [button], 0
		mov [bullet_fired], 1
		mov [bullet_x], 73 
		shr dl,1
		shr dl,1
		shr dl,1
		mov [bullet_y], dx
		
	exit_trigger:
	
	ret
TRIGGER endp;------------------------------------------------------------------------------------
BULLET proc	;------------------------------------------------------------------------------------------------
	
		cmp [bullet_fired],1
		je bulletfired
		jmp exitbullet
										;writes a block into memory
bulletfired:

		sub [bullet_x], 2	
		mov ax, [bullet_x]	
		cmp ax, 3
		jle cancelbullet
	   
		mov ah, 6        					
		mov cx, [bullet_y]
		mov ch, cl
		 
		mov cx, [bullet_y];the bullet is drawn here at ( bullet_x, bullet_y)
		mov ch, cl	 
		mov dx, [bullet_x] 
		mov cl, dl
		mov dx, cx      
		add dl, 4
		mov bh, 10110000b  		
		mov al, 0    
		mov ah, 6  
		int 10h
		
		jmp exitbullet

cancelbullet:

		mov [bullet_fired], 0		 
	
exitbullet:

	ret
BULLET endp;------------------------------------------------------------------------------------------------
BULLET_AND_RANDOM_TARGET_COLLISION proc

		mov ax, [bullet_fired]
		cmp ax, 0
		je exit_bullet_and_random_target_collision		
	
		mov ax, [bullet_x]
		cmp al, 14          ;if target_y y and bullet_x are equal and bullet_x is less than 10
		jle compare_y_positions
;else     
		jmp exit_bullet_and_random_target_collision		
compare_y_positions:
		mov ax, [bullet_y]
		mov bl, [target_y]
		cmp al, bl
		je update_score		
		jmp exit_bullet_and_random_target_collision		
update_score:
		inc [gamescore]
		mov [bullet_fired], 0	
		mov [bullet_x], 73		
exit_bullet_and_random_target_collision:

	ret
BULLET_AND_RANDOM_TARGET_COLLISION endp
RANDOM_TARGET_POSITION proc;------------------------------------------------------------------------------------------------

		xor ax, ax
		  ;get time random_y_position passed since last call 
		call GET_RANDOM_Y_POSITION
		mov al, [random_y_position]
		mov [target_y], al
		mov ah, [previous_random_y_position]
		sub al, ah
		cmp al, 5
		jle createtarget
		jmp drawtarget
		
createtarget:

		call GET_RANDOM_Y_POSITION
		mov al, [random_y_position]
		mov [previous_random_y_position], al 
						   ;This sets the y coordinate and the previous_random_y_position for the instance of the object, almost like OOP.
		mov [target_y], al
		
drawtarget:				      
		  
		mov ch, [target_y] ; y_i
		mov dh, [target_y] ; y_f		
		mov cl, 10  ; x_i
		mov dl, 14  ; x_f		
	
		mov bh, 11110000b ; 
		mov al, 0         ; 
		mov ah, 6         ;!
		int 10h		
	
ret
RANDOM_TARGET_POSITION endp;------------------------------------------------------------------------------------------------
GET_RANDOM_Y_POSITION proc;------------------------------------------------------------------------------------------------

	xor ax, ax
	xor dx, dx	
	
		mov ah, 02Ch
		int 21h	
					 ;this generates a random number between 0-25
		cmp dh, 10
		jle skip     ;if random_y_position is less than or equal to ten then skip this step, else get a -n for random value
		shr dh,1     ;this insures that any number 0-59 will be displayable if n/2-5 is at minimum 25, n - random_y_position 
		sub dh,5
	 skip:    
		mov [random_y_position],  dh   ;save random_y_position for countdown 

ret
GET_RANDOM_Y_POSITION endp;------------------------------------------------------------------------------------------------
SCORE proc;------------------------------------------------------------------------------------------------
;draw SCORE
    
		mov ah, 1h ;make cursor vanish
		mov ch, 20
		int 10h

	; move cursor
	
        mov ah, 2         ; move cursor function
        mov dx, 0000h     ; center of screen
        xor bh, bh        ; page 0
        int 10h

    ; display character with attribute
        mov ah, 09        ; display character function   
        mov bh, 0         ; page 0
        mov bl, 00001111b  ; blinking cyan char, red back
        mov cx, 1         ; display one character
        mov al, 'S'       ; character is 'S'
        int 10h

	      ; move cursor
        mov ah, 2         ; move cursor function
        inc dl
        xor bh, bh        ; page 0
        int 10h

    ; display character with attribute
        mov ah, 09        ; display character function   
        mov bh, 0         ; page 0
        mov bl, 00001111b  ; blinking cyan char, red back
        mov cx, 1         ; display one character
        mov al, 'C'       ; character is 'C'
        int 10h

	     ; move cursor
        mov ah, 2         ; move cursor function
        inc dl
        xor bh, bh        ; page 0
        int 10h

    ; display character with attribute
        mov ah, 09        ; display character function   
        mov bh, 0         ; page 0
        mov bl, 00001111b  ; blinking cyan char, red back
        mov cx, 1         ; display one character
        mov al, 'O'       ; character is 'O'
        int 10h
       
	      ; move cursor
        mov ah, 2         ; move cursor function
        inc dl
        xor bh, bh        ; page 0
        int 10h

    ; display character with attribute
        mov ah, 09        ; display character function   
        mov bh, 0         ; page 0
        mov bl, 00001111b  ; blinking cyan char, red back
        mov cx, 1         ; display one character
        mov al, 'R'       ; character is 'R'
        int 10h

	    ; move cursor
        mov ah, 2         ; move cursor function
        inc dl
        xor bh, bh        ; page 0
        int 10h

    ; display character with attribute
        mov ah, 09        ; display character function   
        mov bh, 0         ; page 0
        mov bl, 00001111b  ; blinking cyan char, red back
        mov cx, 1         ; display one character
        mov al, 'E'       ; character is 'E'
        int 10h	
	
		    ; move cursor
        mov ah, 2         ; move cursor function
        mov dl, 7
        xor bh, bh        ; page 0
        int 10h

	 ; display character with attribute
        mov ah, 09        ; display character function   
        mov bh, 0         ; page 0
        mov bl, 00001111b  ; blinking cyan char, red back
        mov cx, 1         ; display one character
	    cmp [gamescore], 9
	    je resetscore
	    jmp nextscore
		
resetscore:

	    mov  [gamescore], 0	
		
nextscore:		

	    add [gamescore],48
        mov al, [gamescore]   
        int 10h
	    sub [gamescore], 48	  

exitscore:   

ret
SCORE endp;------------------------------------------------------------------------------------------------
PAUSE PROC;-------------------------------------------------------------------------------
			
            xor ax, ax              ; bios get time 
            int 1ah                 ;  
            mov ax, [ticks]     	;   
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
BLACK_SCREEN proc;------------------------------------------------------------------------------------------------

	 ; clear window to black   
	mov ah, 6         
	mov cx, 0000     
	mov DX, 8025   
	mov bh, 00000000b 
	mov al, 0         
	int 10h	
ret
BLACK_SCREEN endp;------------------------------------------------------------------------------------------------
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
END   MAIN
