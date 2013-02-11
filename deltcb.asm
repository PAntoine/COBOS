comment	#====================================================
	              Delete Task Control Block
		
	This function will delete the specified TCB, from the
	TCB selector provided.
	
	      Version 2 copyright 1995 & 1996 P.Antoine
		32Bit call version	   
	Input:
		(word) TCB selector number
	Output:
		<none>
		
	#=====================================================
	
dt_selector	equ	8

delete_TCB:	enter	0,0		;save base pointer, mov ESP to EBP
	push	eax
	push	ds

	mov	ds, ss:dt_selector[ebp]	; load TCB selector

	push	word ptr ds:[TCB.Stack_alloc]
	call	free_memory		; free stack memory
	
	push	word ptr ds:[TCB.lt_stack]
	call	free_memory		; free level transition stack memory

	push	word ptr ds:[TCB.code_alloc]
	call	free_memory		; free screen memory

	push	word ptr ds:[TCB.data_alloc]
	call	free_memory

	push	word ptr ds:[TCB.TSS_alloc]
	call	free_memory		; Task state segment GONE!!

	push	word ptr ds:[TCB.TCB_alloc]
	xor	eax, eax
	mov	ds, ax		; can't delete a segment in use	
	call	free_memory		; delete the segment

	pop	ds
	pop	eax
	leave
	ret	2