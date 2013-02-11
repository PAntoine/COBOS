comment	#=========================================================

		      EXCEPTIONS

	      Concurrent Object Based Operating System
		        (COBOS)
				 
	        BEng (Hons) Software Engineering for
		     Real Time Systems
		  3rd Year Project 1996/97
			  
		     (c) 1996 P.Antoine
			     
	 This file contains the code the handle the 386/486 PMODE
	 exceptions. All exceptions are called INT_n, where n is
	 the interrupt number.
	
	#========================================================

x_int_0:	push	eax		; Divide by zero error
	push	ds
	
	mov	ax, sys_segment
	mov	ds, ax

	mov	ds:[sys.exception_code], 00h 	; no code for this error
	mov	ds:[sys.exception_num], 00h	; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:8[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_cs], ax
	mov	byte ptr ds:[xc_spc.xc_fatal], 0ffh	; this error is fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 00h	; no need to tidy stack
	jmp	dump_registers

x_int_2:        push	eax		; Non-Maskable interrupt
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	ds:[exception_code], 00h	; no code for this error
	mov	ds:[exception_num], 02h	; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:8[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_cs], ax
	and	byte ptr ds:[xc_spc.xc_fatal], 00h	; this error is not fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 00h	; no need to tidy stack
	jmp	dump_registers

x_int_3:        push	eax		; Breakpoint
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	ds:[exception_code], 00h	; no code for this error
	mov	ds:[exception_num], 03h	; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:8[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_cs], ax
	and	byte ptr ds:[xc_spc.xc_fatal], 00h	; this error is not fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 00h	; no need to tidy stack
	jmp	dump_registers

x_int_4:        push	eax		; Overflow
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	ds:[exception_code], 00h	; no code for this error
	mov	ds:[exception_num], 04h	; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:8[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_cs], ax
	and	byte ptr ds:[xc_spc.xc_fatal], 00h	; this error is not fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 00h	; no need to tidy stack
	jmp	dump_registers

x_int_5:        push	eax		; Bounds check
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	ds:[exception_code], 00h        ; no code for this error
	mov	ds:[exception_num], 05h	; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:8[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_cs], ax
	and	byte ptr ds:[xc_spc.xc_fatal], 00h	; this error is not fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 00h	; no need to tidy stack
	jmp	dump_registers

x_int_6:        push	eax		; Invaild op code
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	ds:[exception_code], 00h        ; no code for this error
	mov	ds:[exception_num], 06h	; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:8[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_cs], ax
	mov	byte ptr ds:[xc_spc.xc_fatal], 0ffh	; this error is fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 00h	; no need to tidy stack
	jmp	dump_registers

x_int_7:        push	eax		; Co processor not available
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	ds:[exception_code], 00h	; no code for this error
	mov	ds:[exception_num], 07h	; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:8[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_cs], ax
	and	byte ptr ds:[xc_spc.xc_fatal], 00h	; this error is not fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 00h	; no need to tidy stack
	jmp	dump_registers

x_int_8:	push	eax		; Double Fault (task)
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	eax, ss:8[esp]		; get the error code
	mov	ds:[exception_code], eax
	mov	ds:[exception_num], 08h	; the exception number
	call	cobos_exit
	pop	ds
	pop	eax
	add	esp, 4
	iret
	jmp	x_int_8

x_int_9:        push	eax		; Co processor overrun
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	ds:[exception_code], 00h	; no code for this error
	mov	ds:[exception_num], 09h	; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:8[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_cs], ax
	mov	byte ptr ds:[xc_spc.xc_fatal], 0ffh	; this error is fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 00h	; no need to tidy stack
	jmp	dump_registers

x_int_a:	push	eax		; Invalid task state (task)
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	eax, ss:8[esp]		; get the error code
	mov	ds:[exception_code], eax
	mov	ds:[exception_num], 0ah ; the exception number
	call	cobos_exit
	pop	ds
	pop	eax
	add	esp, 4
	iret
	jmp	x_int_a

x_int_b:	push	eax		; Not present
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	eax, ss:8[esp]		; get the error code
	mov	ds:[exception_code], eax
	mov	ds:[exception_num], 0bh 	; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	byte ptr ds:[xc_spc.xc_fatal], 0ffh	; this error is fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 01h	; tidy stack
	jmp	dump_registers

x_int_c:	push	eax             ; Stack Fault (task)
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	eax, ss:8[esp]		; get the error code
	mov	ds:[exception_code], eax
	mov	ds:[exception_num], 0ch ; the exception number
	call	cobos_exit
	pop	ds
	pop	eax
	add	esp, 4
	iret
	jmp	x_int_c
	
x_int_d:	push	eax			; General Protection Fault
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	eax, ss:8[esp]		; get the error code
	mov	ds:[exception_code], eax
	mov	ds:[exception_num], 0dh		; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:16[esp]
	mov	ds:[xc_spc.xc_cs], ax
	mov	byte ptr ds:[xc_spc.xc_fatal], 0ffh	; this error is fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 01h	; tidy stack
	jmp	dump_registers

x_int_e:	push	eax			; Page Fault
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	eax, ss:8[esp]		; get the error code
	mov	ds:[exception_code], eax
	mov	ds:[exception_num], 0eh		; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:16[esp]
	mov	ds:[xc_spc.xc_cs], ax
	mov	byte ptr ds:[xc_spc.xc_fatal], 0ffh	; this error is fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 01h	; tidy stack
	jmp	dump_registers

x_int_10:       push	eax			; Coprocessor Error
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	ds:[exception_code], 00h		; no code for this error
	mov	ds:[exception_num], 10h		; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:8[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_cs], ax
	mov	byte ptr ds:[xc_spc.xc_fatal], 0ffh	; this error is fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 00h	; no need to tidy stack
	jmp	dump_registers

x_int_11:	push	eax			; Alignment Check
	push	ds
	mov	ax, sys_segment
	mov	ds, ax
	mov	eax, ss:8[esp]		; get the error code
	mov	ds:[exception_code], eax
	mov	ds:[exception_num], 11h		; the exception number
	mov	ds, ds:[sys.exception_spc]		; load the dump space
	mov	eax, ss:12[esp]
	mov	ds:[xc_spc.xc_eip], eax
	mov	eax, ss:16[esp]
	mov	ds:[xc_spc.xc_cs], ax
	and	byte ptr ds:[xc_spc.xc_fatal], 00h	; this error is not fatal
	mov	byte ptr ds:[xc_spc.xc_tidy], 01h	; tidy stack
	jmp	dump_registers

;===============================================
;	DUMP REGISTERS
;-----------------------------------------------
; This function loads the exception space segment
; then loads it with the registers from the task
; that has just failed. Then calls the exception
; task below.
;
dump_registers:	mov	eax, ss:[esp]
	mov	ds:[xc_spc.xc_ds], ax	; get DS from the stack
	mov	eax, ss:4[esp]		; get eax from the stack
	mov	ds:[xc_spc.xc_eax], eax
	mov	ds:[xc_spc.xc_ebx], ebx
	mov	ds:[xc_spc.xc_ecx], ecx
	mov	ds:[xc_spc.xc_edx], edx
	mov	ds:[xc_spc.xc_edi], edi
	mov	ds:[xc_spc.xc_esi], esi
	mov	ds:[xc_spc.xc_ebp], ebp
	mov	ds:[xc_spc.xc_es], es
	mov	ds:[xc_spc.xc_fs], fs
	mov	ds:[xc_spc.xc_gs], gs

	fcall	g_excpt_tss, 0000	; far call to a TSS no offset needed

	cmp	byte ptr ds:[xc_spc.xc_fatal],00h	 ; is the error	fatal
	je	dr_exit		; NO!

;------------------------
; close the failing task

;	mov	ax, sys_segment
;	mov	ds, ax
;	push	word ptr ds:[sys.current_task]	; push the task number
;	fcall	g_cobos, close_task	; this will close the current task

	int	20h		; call the task switcher

;------------------------
; return to failing task

dr_exit:	pop	ds
	pop	eax
	cmp	es:[xc_spc.xc_tidy], 00	; do we need to tidy the stack
	je	dr_ret		; no!
	add	esp, 4		; tidy the stack
dr_ret:	iretd

;==========================================
;	 Exception
;-------------------------------------------
; This is a 32 bit task. The first part of
; the code sets up the task then does a far
; return to the code that called it. The
; second section is a task loop that will
; handle the exceptions.
;
;	 DS - System Segment

 exception:	 mov	ax, sys_segment
	 mov	ds, ax

;--------------------------------
; Allocate memory for exceptions

	push	word ptr 0FFFFh	 ; owner - system
	push	word ptr 4092h		 ; type (32bit data)
	push	dword ptr 200h		 ; 512 bytes
	call	allocate_memory
	cmp	ebx, 00
	jne	cobos_exit		 ; memory allocation fault - dump exit system
	mov	ds:[sys.exception_spc], ax
	mov	es, ax		 ; load es with ax

	push	word ptr 0FFFFh	 ; owner - system
	push	word ptr 4092h		 ; type (32bit data)
	push	dword ptr 44e8h		; (126 * 35 * 8) / 2 bytes
	call	allocate_memory
	cmp	ebx, 00
	jne	cobos_exit		 ; memory allocation fault - dump exit system
	mov	es:[xc_spc.xc_win_seg], ax	 ; save the segment

;---------------------------
; set up exception window

	push	word ptr 01000011b
	push	word ptr ax		; graphic segment
	push	dword ptr 00		; graphic offset
	push	word ptr 00		; message segment
	push	dword ptr 00		; message offset
	push	word ptr 00		; message length
	push	word ptr ds:[sys.current_task]	; target task for window
	push	word ptr 00		; window relative start y		
	push	word ptr 00		; window realtive start x
	push	word ptr 07eh		 ; 480 lines (max y)
	push	word ptr 0118h		 ; 640 pixels (max x)
	push	word ptr 10ah		 ; bot y	
	push	word ptr 19Bh		 ; bot x
	push	word ptr 08ch		 ; top y
	push	word ptr 083h		 ; top x
	push	word ptr 0ffffh		 ; owner (system)
	fcall	g_cobos, add_hot_spot	 ; add the hot spot

	mov	es:[xc_spc.xc_window],ax	 ; save the screen number

;	push	word ptr 0501h		 ; background colour
;	push	word ptr ax
;	call	draw_border

;----------------------------
; put text in window

	mov	ax, offset g_messages
	mov	fs, ax		 ; load FS with the system messages area

	mov	eax, offset mess_excpt	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 0		 ; y position
	push	word ptr 10		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_error	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 1		 ; y position
	push	word ptr 0		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_eax	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 2		 ; y position
	push	word ptr 0		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_ebx	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 3		 ; y position
	push	word ptr 0		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_ecx	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 2		 ; y position
	push	word ptr 15		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_edx	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 3		 ; y position
	push	word ptr 15		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_edi	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 4		 ; y position
	push	word ptr 0		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_esi	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 4		 ; y position
	push	word ptr 15		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_ds	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 5		 ; y position
	push	word ptr 0		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_es	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 5		 ; y position
	push	word ptr 15		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_fs	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 6		 ; y position
	push	word ptr 0		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_gs	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 6		 ; y position
	push	word ptr 15		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_task	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 8		 ; y position
	push	word ptr 5		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_code	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 9		 ; y position
	push	word ptr 5		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, offset mess_stack	 ; the message to displayed
	push	word ptr fs		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 10		 ; y position
	push	word ptr 5		 ; x position
	push	word ptr 010fh		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

;----------------------------
; intialise windows
	movzx	eax, es:[xc_spc.xc_window]

	imul	eax, hs_size		 ; position in table
	mov	fs, ds:[sys.hot_spot]	 ; load the hot spot table
	btr	fs:hs_status[eax], hs_active	 ; set the window to be unactive
	iret

;-------------------
; exception code

exct_loop:	mov	ax, sys_segment
	mov	ds, ax

	bts	ds:[sys.semaphores], ss_exception ; set the system exception bit

	mov	es:[xc_spc.xc_message], byte ptr 02h
	movzx	eax, ds:[sys.exception_num]

	mov	bl, al
	and	bx, 0fh
	cmp	bl, 0ah
	jbe	exl_do

	sub	bl, 0ah
	shl	bx, 1
	add	bl, 0ah

exl_do:	mov	es:1[xc_spc.xc_hex], bl
	shr	eax, 4
	mov	es:[xc_spc.xc_hex], al
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 1		 ; y position
	push	word ptr 6		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, es:[xc_spc.xc_eax]
	call	hex_to_char
	mov	es:[xc_spc.xc_message], 08h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 2		 ; y position
	push	word ptr 6		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, es:[xc_spc.xc_ebx]
	call	hex_to_char
	mov	es:[xc_spc.xc_message], 08h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 3		 ; y position
	push	word ptr 6		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, es:[xc_spc.xc_ecx]
	call	hex_to_char
	mov	es:[xc_spc.xc_message], 08h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 2		 ; y position
	push	word ptr 19		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, es:[xc_spc.xc_edx]
	call	hex_to_char
	mov	es:[xc_spc.xc_message], 08h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 3		 ; y position
	push	word ptr 19		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, es:[xc_spc.xc_edi]
	call	hex_to_char
	mov	es:[xc_spc.xc_message], 08h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 4		 ; y position
	push	word ptr 6		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, es:[xc_spc.xc_esi]
	call	hex_to_char
	mov	es:[xc_spc.xc_message], 08h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 4		 ; y position
	push	word ptr 19		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	movzx	eax, es:[xc_spc.xc_ds]
	call	word_to_char
	mov	es:[xc_spc.xc_message], 04h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 5		 ; y position
	push	word ptr 06		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	movzx	eax, es:[xc_spc.xc_es]
	call	word_to_char
	mov	es:[xc_spc.xc_message], 04h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 5		 ; y position
	push	word ptr 19		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	movzx	eax, es:[xc_spc.xc_fs]
	call	word_to_char
	mov	es:[xc_spc.xc_message], 04h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 6		 ; y position
	push	word ptr 06		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	movzx	eax, es:[xc_spc.xc_gs]
	call	word_to_char
	mov	es:[xc_spc.xc_message], 04h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 6		 ; y position
	push	word ptr 19		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	movzx	eax, ds:[sys.current_task]
	call	word_to_char
	mov	es:[xc_spc.xc_message], 04h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 8		 ; y position
	push	word ptr 11		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	movzx	eax, es:[xc_spc.xc_cs]
	call	word_to_char
	mov	es:[xc_spc.xc_message], 04h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 9		 ; y position
	push	word ptr 11		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

	mov	eax, es:[xc_spc.xc_eip]
	call	hex_to_char
	mov	es:[xc_spc.xc_message], 08h
	mov	eax, offset xc_message

	push	word ptr es		 ; segment of message
	push	eax		 ; offset of message
	push	word ptr 9		 ; y position
	push	word ptr 16		 ; x position
	push	word ptr 0104h		 ; bg / fg colours
	push	word ptr es:[xc_spc.xc_window]	 ; screen number
	fcall	g_cobos, display_text

;-------------------------
; set the windows state

	movzx	eax, es:[xc_spc.xc_window]
	imul	eax, hs_size		 ; position in table
	mov	fs, ds:[sys.hot_spot]	 ; load the hot spot table
	bts	fs:hs_status[eax], hs_active	 ; set the window to be active
	bts	fs:hs_status[eax], hs_redraw	 ; and the screen is to be redrawn

;-------------------------
; finished exception dump

	bt	ds:[sys.semaphores], ss_system	 ; was it a system function that failed
	jc	ec_exit		 ; YES!!!
	
	mov	gs, ds:[sys.task_list]
	movzx	eax,word ptr ds:[sys.current_task]
	mov	fs, gs:TCB_seg[eax*8]	 ; get the TCB segment
	bts	fs:[TCB.status], t_exception	 ; set the tasks exception bit

;-----------------------------
; return to exception dump

ec_exit:	iretd			 ; if the error	is recovered return
	jmp	exct_loop		 ; it is a task	loop

;------------------------------
; convert eax to charaters

word_to_char:	push	eax		 ; save registers
	push	ebx
	push	ecx
	shl	eax, 16		; lose the top word
	mov	ecx, 04h
	xor	edx, edx
	jmp	htc_loop

hex_to_char:	push	eax		 ; save registers
	push	ebx
	push	ecx
	mov	ecx, 08h
	xor	edx, edx
	
htc_loop:	shld	ebx, eax, 4
	shl	eax, 4
	and	ebx, 0fh		 ; get last nibble
	cmp	bl, 0ah
	jbe	htc_write

	sub	bl,0ah		; sort out B to F
	shl	bx, 1
	add	bl,0ah 

htc_write:	mov	es:xc_hex[edx], bl
	inc	edx
	loop	htc_loop

	pop	ecx
	pop	ebx
	pop	eax
	ret