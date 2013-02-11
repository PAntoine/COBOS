comment	#===========================================================

		        Check Mouse
		
	 This procedure will take in the movement of the mouse point
	 from the mouse driver. If the mouse has moved, then this
	 function will set the new screen position, and redraw the
	 mouse pointer. The function also takes a mouse status byte.
	 If any of the mouse buttons have been pressed, then the
	 function will check the hotspot table,and action any
	 messages that are nessary.
	
	           Version 1 Copyright 1996 P.Antoine

	 Input:
	 	word: mouse_x
	 	word: mouse_y
	 	word: mouse_status   (bottom byte only)
	
	#===========================================================

chm_mouse_x	equ	8
chm_mouse_y	equ	10
chm_mouse_st	equ	12

check_mouse:	enter	0,0
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	ds
	push	es
	push	fs
	push	gs

	mov	ax, sys_segment
	mov	ds, ax

	cmp	ss:chm_mouse_x[ebp],word ptr 00	; has it moved in the x or y direction
	jne	chm_redraw
	cmp	ss:chm_mouse_y[ebp],word ptr 00
	je	chm_chk_click	
		
chm_redraw:	bt	ds:[sys.semaphores], ss_screen
	jc	chm_exit		; if the screen is in use dont move the mouse
	call	clear_mouse		; clear the mouse pointer

chm_here_2:	mov	ax, ds:[sys.mouse_x]	; set the new x value
	add	ax, ss:chm_mouse_x[ebp]
	cmp	ax, 00		; off the side of the screen?
	jb	chm_r_y
	cmp	ax, ds:[sys.screen_x]	; off the other side of the screen?
	ja	chm_r_y
	mov	ds:[sys.mouse_x], ax	

chm_r_y:	mov	ax, ds:[sys.mouse_y]	; set the new y value
	add	ax, ss:chm_mouse_y[ebp]
	cmp	ax, 00		; off the side of the screen?
	jb	chm_drw_mse
	cmp	ax, ds:[sys.screen_y]	; off the other side of the screen?
	ja	chm_drw_mse
	mov	ds:[sys.mouse_y], ax	

chm_drw_mse:	call	draw_mouse		; draw the mouse pointer on screen

chm_chk_click:	cmp	word ptr ss:chm_mouse_st[ebp], 00
	je	chm_exit		; no mouse buttons pressed
	
chm_wait:;	bts	ds:[sys.semaphores], ss_hots	; wait for the hot spot table
;	jc	chm_wait
	
;----------------------------
; critical region (hot spot)

	xor	ecx ,ecx
	mov	es, ds:[sys.hot_spot]	; load the hot spot table
	movzx	ecx, ds:[sys.top_hs_entry]	; start of the hot spot chain

chm_loop:	cmp	ecx, 00		
	je	chm_cr_exit		; end of chain then exit
	
	imul	ecx, hs_size		; position in table (multiply by entry size)
	
	mov	ax, es:hs_top_x[ecx]	; get the x pos of hot spot
	cmp	ds:[sys.mouse_x], ax
	jb	chm_chk_nxt
	
	mov	ax, es:hs_top_y[ecx]	; get the top y
	cmp	ds:[sys.mouse_y], ax
	jb	chm_chk_nxt
	
	mov	ax, es:hs_bot_x[ecx]	; bottom x
	cmp	ds:[sys.mouse_x], ax
	ja	chm_chk_nxt
	
	mov	ax, es:hs_bot_y[ecx]	; bottom y
	cmp	ds:[sys.mouse_y], ax
	jb	chm_chk_found

chm_chk_nxt:	movzx	ecx, es:hs_chain[ecx]	; get next entry
	jmp	chm_loop

chm_chk_found:	bt	word ptr es:hs_status[ecx],hs_user	; does the hs_task become top
	jnc	chm_chk_mess

	; *** make screen top and user task ***

	
chm_chk_mess:	bt	word ptr es:hs_status[ecx], hs_active	; is the hot spot alive
	jnc	chm_cr_exit

	xor	eax, eax
	mov	bx, es:hs_task[ecx]
	mov	fs, ds:[sys.task_list]
	mov	gs, fs:TCB_seg[ebx*8]		; load TCB of user task
	bt	gs:[TCB.status], t_mouse		; is the mouse bit set?
	jnc	chm_cr_exit			; no!

	bt	word ptr es:hs_status[ecx], hs_mess	; send a message or the mouse state
	jc	chm_snd_mess

;------------------------
; send mouse move to post

	mov	gs, ds:[sys.ms_post]		; get the post box
	bsf	eax, gs:[0]
	jz	chm_cr_exit			; post box is full!

	mov	ebx, eax
	imul	ebx, 12			; size of mouse post box
	
	mov	dx, ss:chm_mouse_st[ebp]
	mov	gs:pb_ms1_button[ebx], dx		; mouse button status
	
	mov	dx, ss:chm_mouse_x[ebp]		; x position
	sub	dx, es:hs_top_x[ecx]
	add	dx, es:hs_rel_x[ecx]		; now click rel to window 
	mov	gs:pb_ms1_x_pos[ebx], dx
	
	mov	dx, ss:chm_mouse_y[ebp]		; y position
	sub	dx, es:hs_top_y[ecx]
	add	dx, es:hs_rel_y[ecx]		; now click rel to window 
	mov	gs:pb_ms1_y_pos[ebx], dx
	
	mov	gs:pb_ms1_type[ebx], 01h		; type direct mouse move
	mov	dx, es:hs_task[ecx]
	mov	gs:pb_ms1_task[ebx], dx		; store the task

	btr	gs:[0], eax			; let the post box know entry filled	
	mov	gs, ds:[sys.post_box]
	btr	gs:[TCB.status], t_suspended		; unsuspend the post box	
	jmp	chm_cr_exit

;----------------------------
; send hot spot mess to post

chm_snd_mess:
	mov	gs, ds:[sys.ms_post]		; get the post box
	bsf	eax, gs:[0]
	jz	chm_cr_exit			; post box is full!
	
	mov	ebx, eax
	imul	ebx, 12			; size of mouse post box

	mov	dx, es:hs_mess_seg[ecx]		; segment (message)
	mov	gs:pb_ms2_seg[ebx], dx
	
	mov	edx, es:hs_message[ecx]		; offset (message)
	mov	gs:pb_ms2_offset[ebx], edx
	
	mov	dx, es:hs_mess_len[ecx]		; size (message)
	mov	gs:pb_ms2_size[ebx], dx
	
	mov	dx, es:hs_task[ecx]		; task to message
	mov	gs:pb_ms2_task[ebx], dx
	mov	gs:pb_ms2_type[ebx], 02h		; type "02" hot spot message

	btr	gs:[0], eax			; let the post box know entry filled	
	
;-------------------------------
; end critical region (hot spot)

chm_cr_exit:;	btr	ds:[sys.semaphores], ss_hots
	
chm_exit:	pop	gs
	pop	fs
	pop	es
	pop	ds
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	leave
	ret	6