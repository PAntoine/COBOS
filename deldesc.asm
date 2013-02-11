comment	#=======================================================

	            Delete Gate & General Descriptor
		
	All this subroutine does is zero out the specified 
	Descriptor from the descriptor table.
	
	        Version 2 copyright 1995 & 1996 P.Antoine.
		32Bit Code Version	
	Input:
		word: selector
	Output:
		<none>
	#========================================================

dd_selector	equ	8
	
Delete_desc:	enter	0,0
	push	ds
	push	es
	push	eax
	
	mov	ax, sys_segment
	mov	ds, ax

dd_loop:	bts	ds:[sys.semaphores], ss_GDT		; wait for the descriptor table
	jc	dd_loop

	mov	es, ds:[sys.GDT_table]
	
	movzx	eax,word ptr ss:dd_selector[ebp]	; get selector
	mov	es:[eax], dword ptr 00h
	mov	es:[eax+4], dword ptr 00h		; descriptor removed
	
	btr	ds:[sys.semaphores], ss_GDT		; release the GDT
	pop	eax
	pop	es
	pop	ds
	leave
	ret	2