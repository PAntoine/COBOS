comment	#======================================================= 

		   COBOSFD.ASM 
		 (COBOS_FIND_DSK)
                                                                         
	    Concurrent Object Based Operating System         
	         	     (COBOS)                         
	         	                                         
	         BEng (Hons) Software Engineering for          
	                Real Time Systems                   
	             3rd Year Project 1996/97               
	        	                                         
	               (c) 1996 P.Antoine                  
	                 
	This function will locate the COBOS.DSK file on the 
	primary IDE device on the system. It will return the
	relative block number of the file. This file MUST have
	been set up previously to be a block_chain file, with
	the realm table in the first blocks.                                        

	#========================================================

	.386

cfd_sect	equ	-2
cfd_trak	equ	-4
cfd_cyln	equ	-6
cfd_heads	equ	-9
cfd_sec_pt	equ	-11
cfd_root_srt	equ	-16
cfd_root_size	equ	-18
	
cobos_find_dsk:	enter	18,0		; space for the local vars
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	esi
	
	xor	eax, eax
	mov	ax, disk_segment	; load the disk segment
	mov	es, ax

	xor	bx, bx		; start of disk buffer 
			
	mov	ah, 02h		; read the partition table
	mov	al, 01h
	mov	ch, 00h
	mov	cl, 01h
	mov	dh, 00h
	mov	dl, 80h
	int	13h

; find the boot partition
	
	mov	ax, part_table_1
	cmp	es:[part_table_1],byte ptr 80h	; is the boot partiton part 1
	je	cfd_found
	
	mov	ax, part_table_2
	cmp	es:[part_table_2],byte ptr 80h	; is the boot partiton part 2
	je	cfd_found
	
	mov	ax, part_table_3
	cmp	es:[part_table_3],byte ptr 80h	; is the boot partiton part 3
	je	cfd_found
	
	mov	ax, part_table_4
	cmp	es:[part_table_4],byte ptr 80h	; is the boot partiton part 4
	je	cfd_found
	
; read the boot sector

cfd_found:	mov	esi,es:rel_start[eax]
	mov	ss:cfd_root_srt[ebp], esi	; save the rel start of the partition

	mov	esi, es:num_sectors[eax]
	mov	es:[max_sector],esi	; save the number of sectors in the partition

	mov	dh, es:part_head[eax]	; read the boot sector
	mov	cl, es:part_sect[eax]
	mov	ch, es:part_cyln[eax]
	mov	dl, 80h
	mov	ax, 0201h		; read command
	int	13h

; save some values that are needed later

	xor	eax, eax
	mov	ax, es:num_heads[bx]
	mov	ss:cfd_heads[ebp], al	; store the number of heads
	mov	es:[disk_heads], al
	mov	ax, es:sec_per_track[bx]
	mov	ss:cfd_sec_pt[ebp], al	; store sectors per track
	mov	es:[disk_sector], al

; find the root directory	

	mov	esi, ss:cfd_root_srt[ebp]	; only interested in the bottom word	
	movzx	ax, es:[cluster_size]
	push	ax		; number of sectors per cluster
	push	es:[root_entries]	; save the root dir size

	mov	ax, es:fat_size[bx]	; sectors per fat  			
	xor	cx, cx
	mov	cl, es:num_fats[bx]	; number of fats  
	mul	cx
	add	ax, si		; boot sector relative + boot sector offset within patitiion  
	add	ax, es:res_sectors[bx]	; the number of reserved sectors  
	inc	ax
	mov	ss:cfd_root_srt[ebp], eax	; save the pointer to the start of root

	xor	esi, esi
	xor	ecx, ecx
	mov	cx, es:sec_per_track[bx]	; sectors per track  
	div	cx		; divide ax by bx  
	mov	si, dx		; save the sector number  
	xor	dx, dx
	mov	cx, es:num_heads[bx]	; devide by the nuber of heads  
	div	cx		; ax - clyinder number dx - what head  
	mov	dh, dl		; move the head number  
		
	mov	cx, si		; the sector number  - low 8  
	mov	ch, al		; track number  
	mov	ax, 0201h		; read block - 1 block  
	mov	dl, 80h		; the drive number  
	int	13h		; read the drive  

; find the DSK file

	xor	eax, eax
	pop	ax		; root entries
	shr	eax, 4		; div 16 - number of sectors
	mov	ss:cfd_root_size[ebp], ax	; save the root size

	mov	ss:cfd_sect[ebp], bx	; save the disk positions
	mov	ss:cfd_trak[ebp], cx
	mov	ss:cfd_cyln[ebp], dx
	xor	esi, esi

cfd_big_loop:	xor	edi, edi

cfd_loop:	mov	si, offset dsk_name	; offset of the name space
	mov	cx, 8		; search first 8 bytes					
	repe cmpsb
	jne	cfd_next		; if name
	mov	si, offset dsk_ext
	mov	cx, 3
	repe cmpsb
	je	cfd_found_ini		; name & ext = 'cobos.dsk'
	
cfd_next:	add	di, 32		; next entry
	and	di, 0fe0h		; round down to multiples of 32
	cmp	di, 512
	jb	cfd_loop

	push	ax
	mov	ax, 0201h
	mov	bx, ss:cfd_sect[ebp]	; get old sectors
	mov	cx, ss:cfd_trak[ebp]
	mov	dx, ss:cfd_cyln[ebp]

; increment the sector

	inc	cl
	cmp	cl, ss:cfd_sec_pt[ebp]	; sectors per track
	jb	cfd_size		; not on next head
	
	mov	cl, 01
	inc	dh		; back to sector 1 then next head
	cmp	dh, ss:cfd_heads[ebp]	
	jb	cfd_size		; if = no heads, then next cylinder
	
	mov	dh, 00
	mov	ax, cx
	and	cl, 3fh		; clear all but the top two bits
	rol	cl, 2		; make top two bottom two
	ror	cx, 8		; place the whole thing at 0
	inc	cx		; increment the cylinder number

; it does NOT check to see if it runs off the end of the Disk

	rol	cx, 8
	ror	cl, 2
	and	al, 0c0h		; every thing but the top two bits
	and	al, cl		; new alls in place

; save the new sector & read it

cfd_size:	mov	ss:cfd_sect[ebp], bx	; save the new disk position
	mov	ss:cfd_trak[ebp], cx
	mov	ss:cfd_cyln[ebp], dx
	mov	ax, 0201h		; read 1 sector command
	int	13h		; read the sector
	
	pop	ax
	dec	ax
	jne	cfd_big_loop		; if 0 then exit

; Crash exit - DSK file not found!
	
cfd_crash:	mov	ax,4c00h
	int 21h			; exit back to DOS
	
cfd_found_ini:	and	edi, 0fe0h		; back to start of entry
	movzx	eax, word ptr es:f_cluster[edi]	; the start cluster
	sub	eax, 2		; first data cluster is 2
	xor	ebx, ebx
	pop	bx		; the cluster size
	imul	eax, ebx		; the block reative to the start
	add	eax, ss:cfd_root_srt[ebp]	; add the relative start of root (cluster 1)
	movzx	ebx, word ptr ss:cfd_root_size[ebp]
	add	eax, ebx		; add the size of the root directory

	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	leave
	ret
