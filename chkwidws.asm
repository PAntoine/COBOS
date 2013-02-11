comment	#===================================================
		   Check Windows

	 This function will check the hot spot table, and
	 then if any of the redraw bits are set on any of
	 the screens in the hot spot table, then it will 
	 call the draw_window function, or draw_icon for the
	 icons.         

	    Version 2 Copyright (C) 1996 P.Antoine.
	            32Bit COBOS Project task

	Registers:
	
	ES - system segment     DS - Hot Spot list
	GS - section map        FS - scratch

	#===================================================

cw_init:	mov	ax, 0ffffh		; create section map
	push	ax		; owner FFFFh (system)
	push	word ptr 0092h		; data type
	push	dword ptr 0200h		; size
	call	allocate_memory

	mov	gs, ax		; store allocation of section map

	mov	ax, sys_segment
	mov	es, ax		; load the system segment
	mov	ds, es:[sys.hot_spot]	; load the hotspot table

;----------------------------
; main loop

check_windows:	movzx	ecx, es:[sys.top_hs_entry]	; top hot spot
	cmp	ecx, 00h
	jne	cw_wait
	int	20h		; swap out - no screens
	jmp	check_windows

cw_wait:        bts	es:[sys.semaphores], ss_hots	; is the hot spot table free
	jc	cw_wait

cw_loop:	mov	eax, ecx
	imul	eax, hs_size		; multiply by hot spot table size
	
	btr	word ptr ds:hs_status[eax], hs_clear    ; is this screen to be removed
	jc	cw_remove

cw_active:	bt	word ptr ds:hs_status[eax], hs_active   ; is the screen active
	jnc	cw_next

	btr	word ptr ds:hs_status[eax], hs_redraw   ; is the redraw bit set
	jnc	cw_next
	
	bt	word ptr ds:hs_status[eax], hs_screen   ; is it a screen
	jc	cw_window

;---------------------------
; draw the icon

	bts	es:[sys.semaphores], ss_screen	; hold the screen
		
;	push	word ptr cx
;	call	draw_icon		; draw the Icon

	btr	es:[sys.semaphores], ss_screen	; realese the screen

	mov	cx, ds:hs_chain[eax]	; get next hot spot
	cmp	ecx, 00h		; end of chain?
	jne	cw_loop		; NO!

	btr	es:[sys.semaphores], ss_hots
	int	20h		; swap the task out
	jmp	check_windows		; this is a task so loop
	
;----------------------------
; draw the window

cw_window:	call	clear_mouse
	bts	es:[sys.semaphores], ss_screen	; hold the screen

	push	word ptr cx		; window to be redrawn
	call	draw_window		; draw the window
	
	btr	es:[sys.semaphores], ss_screen	; realse the screen
	call	draw_mouse

cw_next:	movzx	ecx, word ptr ds:hs_chain[eax]	; get next hot spot
	cmp	ecx, 00h		; end of chain?
	jne	cw_loop		; NO!

	btr	es:[sys.semaphores], ss_hots
	int	20h		; swap the task out
	jmp	check_windows		; this is a task so loop
	
;----------------------------
; remove the window

cw_remove:	call	clear_mouse
	bts	es:[sys.semaphores], ss_screen

	push	word ptr cx		; window to be removed
	call	clear_window

	btr	es:[sys.semaphores], ss_screen
	call	draw_mouse
	jmp	cw_active		; now go check if it needs redrawing