comment	#======================================================= 

		 BASIC Keyboard table
		(For the MFII keyboard)
                                                                         
	        Concurrent Object Based Operating System         
	         	         (COBOS)                         
	         	                                         
	 This table has four bytes for every key press number. 
	 The first is for a standard press, the second is for the
	 shift press, 3rd control press, and finally 4th for the
	 Alt press.

	 Note: the basic keytable is non-ascii, and all system
	       functions use this key code format.

	    Version No. 1.1  - Post degree Alpha
	 	        	                                         
	        	     (c) 1997 P.Antoine                  
	                                                         
	#========================================================

;		norm - shift - ctrl - alt
	db	 -1 , -1 , -1 , -1	; Key tab starts at entry 1 - so dummy entry 0
	db	 -1 , -1 , -1 , -1	; <esc>
	db	 01h, 3eh, -1 , -1	; 1 !
	db	 02h, 51h, -1 , -1	; 2 "
	db	 03h, 52h, -1 , -1	; 3 œ
	db	 04h, 53h, -1 , -1	; 4 $
	db	 05h, 54h, -1 , -1	; 5 %
	db	 06h, 55h, -1 , -1	; 6 ^
	db	 07h, 56h, -1 , -1	; 7 &
	db	 08h, 42h, -1 , -1	; 8 *
	db	 09h, 47h, -1 , -1	; 9 (
	db	 00h, 48h, -1 , -1	; 0 )
	db	 43h, 44h, -1 , -1	; - _
	db	 4fh, 5ch, -1 , -1	; = +
	db	 69h, 69h, 69h, 69h	; <bksp>
	db	 61h, 61h, 61h, 61h	; <tab>
	db	 2bh, 2ah, -1 , -1	; Q
	db	 37h, 36h, -1 , -1	; W
	db	 13h, 12h, -1 , -1	; E
	db	 2dh, 2ch, -1 , -1	; R
	db	 31h, 30h, -1 , -1	; T
	db	 3bh, 3ah, -1 , -1	; Y
	db	 33h, 32h, -1 , -1	; U
	db	 1bh, 1ah, -1 , -1	; I
	db	 27h, 26h, -1 , -1	; O
	db	 29h, 28h, -1 , -1	; P
	db	 45h, 49h, -1 , -1	; [ {
	db	 46h, 4ah, -1 , -1	; ] }
	db	 62h, 62h, 62h, 62h	; <enter>	
	db	 -1 , -1 , -1 , -1	; <ctrl>
	db	 0bh, 0ah, -1 , -1	; A
	db	 2fh, 2eh, -1 , -1	; S
	db	 11h, 10h, -1 , -1	; D
	db	 15h, 14h, -1 , -1	; F
	db	 17h, 16h, -1 , -1	; G
	db	 19h, 18h, -1 , -1	; H
	db	 1dh, 1ch, -1 , -1	; J
	db	 1fh, 1eh, -1 , -1	; K
	db	 21h, 20h, -1 , -1	; L
	db	 4dh, 4eh, -1 , -1	; ; :
	db	 5ah, 57h, -1 , -1	; ' @
	db	 59h, -1 , -1 , -1	; ` ª
	db	 -1 , -1 , -1 , -1	; <shft left>
	db	 3fh, 58h, -1 , -1	; # ~
	db	 3dh, 3ch, -1 , -1	; Z
	db	 39h, 38h, -1 , -1	; X
	db	 0fh, 0eh, -1 , -1	; C
	db	 35h, 34h, -1 , -1	; V
	db	 0dh, 0ch, -1 , -1	; B
	db	 25h, 24h, -1 , -1	; N
	db	 23h, 22h, -1 , -1	; M
	db	 5dh, 40h, -1 , -1	; , <
	db	 5eh, 41h, -1 , -1	; . >
	db	 4bh, 50h, -1 , -1	; / ?
	db	 -1 , -1 , -1 , -1	; <shft right>
	db	 -1 , -1 , -1 , -1	; <print screen>
	db	 -1 , -1 , -1 , -1	; <alt>
	db	 60h, 60h, 60h, 60h	; <space>
	db	 -1 , -1 , -1 , -1	; <caps lock>
	db	 -1 , -1 , -1 , -1	; F1
	db	 -1 , -1 , -1 , -1	; F2
	db	 -1 , -1 , -1 , -1	; F3
	db	 -1 , -1 , -1 , -1	; F4
	db	 -1 , -1 , -1 , -1	; F5
	db	 -1 , -1 , -1 , -1	; F6
	db	 -1 , -1 , -1 , -1	; F7
	db	 -1 , -1 , -1 , -1	; F8
	db	 -1 , -1 , -1 , -1	; F9
	db	 -1 , -1 , -1 , -1 	; F10
	db	 -1 , -1 , -1 , -1	; <pause> and <num lock>
	db	 -1 , -1 , -1 , -1	; <scroll>
	db	 68h, -1 , -1 , -1	; <home>
	db	 64h, -1 , -1 , -1	; <csr up>
	db	 -1 , -1 , -1 , -1	; <page up>
	db	 43h, -1 , -1 , -1	; -
	db	 67h, -1 , -1 , -1	; <csr left>
	db	 05h, -1 , -1 , -1	; 5
	db	 65h, -1 , -1 , -1	; <csr right>
	db	 5ch, -1 , -1 , -1	; +
	db	 -1 , -1 , -1 , -1	; <end>
	db	 66h, -1 , -1 , -1 	; <csr down>
	db	 -1 , -1 , -1 , -1	; <page down>
	db	 -1 , -1 , -1 , -1	; <ins>
	db	 -1 , -1 , -1 , -1	; <del>
	db	 4ch, 5bh, -1 , -1 	; \ |
	db	 -1 , -1 , -1 , -1 	; F11
	db	 -1 , -1 , -1 , -1	; F12
	
	dd	39 dup (0FFFFh)		; fill the rest of the key tab that is not in use
