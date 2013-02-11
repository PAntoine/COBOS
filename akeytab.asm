comment	#======================================================= 

		 ASCII Keyboard table
		(For the MFII keyboard)
                                                                         
	        Concurrent Object Based Operating System         
	         	         (COBOS)                         
	         	                                         
	 This table has four bytes for every key press number. 
	 The first is for a standard press, the second is for the
	 shift press, 3rd control press, and finally 4th for the
	 Alt press.

	    Version No. 1.1  - Post degree Alpha
	 	        	                                         
	        	     (c) 1997 P.Antoine                  
	                                                         
	#========================================================

;		norm - shift - ctrl - alt
	db	-1 , -1 , -1 , -1	; Key tab starts at entry 1 - so dummy entry 0
	db	01bh, 01bh, 01bh, 001h	; <esc>
	db	31h, 21h, -1 , 78h	; 1 !
	db	32h, 22h, 03h, 79h	; 2 "
	db	33h, 33h, -1 , 7ah	; 3 œ
	db	34h, 24h, -1 , 7bh	; 4 $
	db	35h, 25h, -1 , 7ch	; 5 %
	db	36h, 5eh, 1eh, 7dh	; 6 ^
	db	37h, 26h, -1 , 7eh	; 7 &
	db	38h, 2ah, -1 , 7fh	; 8 *
	db	39h, 28h, -1 , 80h	; 9 (
	db	30h, 29h, -1 , 81h	; 0 )
	db	2dh, 5fh, 1fh, 82h	; - _
	db	3dh, 2bh, -1 , 83h	; = +
	db	08h, 08h, 7fh, -1	; <bksp>
	db	09h, 0fh, -1 , -1	; <tab>
	db	71h, 51h, 11h, 10h	; Q
	db	77h, 57h, 17h, 11h	; W
	db	65h, 45h, 05h, 12h	; E
	db	72h, 52h, 12h, 13h	; R
	db	74h, 54h, 14h, 14h	; T
	db	79h, 59h, 19h, 15h	; Y
	db	75h, 55h, 15h, 16h	; U
	db	69h, 49h, 09h, 17h	; I
	db	6fh, 4fh, 0fh, 18h	; O
	db	70h, 50h, 10h, 19h	; P
	db	5bh, 7bh, 1bh, -1	; [ {
	db	5dh, 7dh, 1dh, -1	; ] }
	db	0dh, 0dh, 0ah, 1ch	; <enter>
	db	-1 , -1 , -1 , -1 	; <ctrl>
	db	61h, 41h, 01h, 1eh	; A
	db	73h, 53h, 13h, 1fh	; S
	db	64h, 44h, 04h, 20h	; D
	db	66h, 46h, 06h, 21h	; F
	db	67h, 47h, 07h, 22h	; G
	db	68h, 48h, 08h, 23h	; H
	db	6ah, 4ah, 0ah, 24h	; J
	db	6bh, 4bh, 0bh, 25h	; K
	db	6ch, 4ch, 0ch, 26h	; L
	db	3bh, 3ah, -1 , -1 	; ; :
	db	2ch, 40h, -1 , -1 	; ' @
	db	0aah, 60h, -1 , -1	; ` ª
	db	-1 , -1 , -1 , -1	; <shft left>
	db	23h, 7eh, -1 , -1 	; # ~
	db	7ah, 5ah, 1ah, 2ch	; Z
	db	78h, 58h, 18h, 2dh	; X
	db	63h, 43h, 03h, 2eh	; C
	db	76h, 56h, 16h, 2fh	; V
	db	62h, 42h, 02h, 30h	; B
	db	6eh, 4eh, 0eh, 31h	; N
	db	6dh, 4dh, 0dh, 32h	; M
	db	2ch, 3ch, -1 , -1 	; , <
	db	2eh, 3eh, -1 , -1 	; . >
	db	2fh, 3fh, -1 , -1 	; / ?
	db	-1 , -1 , -1 , -1	; <shft right>
	db	2ah, -1 , -1 , -1	; <print screen>
	db	-1 , -1 , -1 , -1	; <alt>
	db	20h, 20h, 20h, 20h	; <space>
	db	-1 , -1 , -1 , -1	; <caps lock>
	db	3bh, 54h, 5eh, 5eh	; F1
	db	3ch, 55h, 5fh, 5fh	; F2
	db	3dh, 56h, 60h, 60h	; F3
	db	3eh, 57h, 61h, 61h	; F4
	db	3fh, 58h, 62h, 62h	; F5
	db	40h, 59h, 63h, 63h	; F6
	db	41h, 5ah, 64h, 64h	; F7
	db	42h, 5bh, 65h, 65h	; F8
	db	43h, 5ch, 66h, 66h	; F9
	db	44h, 5dh, 67h, 66h 	; F10
	db	-1 , -1 , -1 , -1	; <pause> and <num lock>
	db	-1 , -1 , -1 , -1	; <scroll>
	db	47h, 37h, 77h, -1 	; <home>
	db	48h, 38h, -1 , -1 	; <csr up>
	db	49h, 39h, 84h, -1 	; <page up>
	db	2dh, 2dh, -1 , -1 	; -
	db	4bh, 34h, 73h, -1 	; <csr left>
	db	-1 , 35h, 8fh, -1 	; 5
	db	4dh, 36h, 74h, -1 	; <csr right>
	db	2bh, 2bh, 90h, 4eh	; +
	db	4fh, 31h, 75h, -1 	; <end>
	db	50h, 32h, 91h, -1  	; <csr down>
	db	51h, 33h, 76h, -1 	; <page down>
	db	52h, 30h, 92h, -1	; <ins>
	db	53h, 2ch, 93h, -1	; <del>
	db	5ch, 7ch, -1 , -1  	; \ |
	db	85h, 87h, 89h, 8bh 	; F11
	db	86h, 88h, 8ah, 8ch	; F12
	
	dd	39 dup (0FFFFh)		; fill the rest of the key tab that is not in use
