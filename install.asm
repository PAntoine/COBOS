comment	#==============================================================

		  COBOS Install program

	        Concurrent Object Based Operating System
		        (COBOS)
				 
	           BEng (Hons) Software Engineering for
		      Real Time Systems
		  3rd Year Project 1996/97
			  
		     (c) 1997 P.Antoine
			     
	 This program will install a DSK file for the COBOS operating
	 system on the primary drive of the PC. It will attempt to
	 create a file that is contigous. If it cannot find enought
	 blocks in order it will fail. The file it will create is 
	 called COBOS.DSK and the file will be a HIDDEN SYSTEM file.
	 As a note, this file must not be moved as COBOS allocates
	 and uses blocks by there direct block numbers and if this
	 file is moved in anyway - it WILL corrupt the COBOS file
	 system, and possibly any other file that is placed where
	 the COBOS file used to be.
	 
	#==============================================================

DOSSEG
.model medium
.386p
.stack	100h

inst_size	equ	640		; the number of clusters to allocate

	include	source\cobosh.asm	; the COBOS structure files

;--------------------------
; Data structures

.data
root_buffer	db	512 dup (00)		; buffer for the root
fat_buffer	dw	256 dup (00)		; buffer for the FAT
cobos_rt_buffer	dd	0ffffffffh		; end of chain marker
	dw	0ffffh		; end of chain marker
	dw	253 dup (00)		; buffer for the COBOS realm table
root_entry	dw	0		; the root sector directory entry for DSK file
fat_count	dw	0
fat_length	dw	0
start_fat	dw	0		; the fat that the free space starts in
start_entry	dw	0		; the entry in the fat that the fat starts in
start_cluster	dw	0		; the DOS cluster number
cluster_num	dw	0
free_count	dw	0		; the count of the sectors that are free
dsk_size	dw	0		; the size of the the DSK file needed (in clusters)
file_name	db	"\cobos.dsk",0		; file name to be created
dsk_name	db	"COBOS   "		; file name : makes the search easier
dsk_ext	db	"DSK"		; file extention
clust_size	dw	0
root_start	dd	0		; where the root patition starts
boot_start	dd	0		; where the boot sector starts
cfd_heads	db	0		; number of heads
cfd_sec_pt	db	0		; sectors per track
sector	dw	0		; current sector
track	dw	0		; current tract
cylinder	dw	0		; current cylinder
boot_sect	dw	0		; start pos of the boot
boot_track	dw	0		;  *** the FAT starts after the boot ***
boot_cylinder	dw	0
root_track	dw	0		; the track of the root dir with the dsk file in
root_cylinder	dw	0		; the cylinder with the DSK file in it
bit_left_over	dd	0
root_size	dd	0		; size of the root directory

;-------------------------
; the program

.code

start:	

;-------------------------
; create the DSK file

	mov	ax, 5b00h		; create file
	mov	cx, 06h		; Hidden and System
	mov	bx, @DATA
	mov	ds, bx
	mov	dx, offset file_name	; set the name of the file
	int	21h		; create the file
	jnc	find_file		; if the carry flag set then error

	mov	ax, 4c01h		; error exit
	int	21h

;--------------------------
; find the file

find_file:	mov	ax, @DATA
	mov	es, ax		; int 13h 02 - reads into ES:BX
	mov	bx, offset root_buffer
	
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
	je	boot_found
	
	mov	ax, part_table_2
	cmp	es:[part_table_2],byte ptr 80h	; is the boot partiton part 2
	je	boot_found
	
	mov	ax, part_table_3
	cmp	es:[part_table_3],byte ptr 80h	; is the boot partiton part 3
	je	boot_found
	
	mov	ax, part_table_4
	cmp	es:[part_table_4],byte ptr 80h	; is the boot partiton part 4
	je	boot_found
	
; read the boot sector

boot_found:	mov	esi,es:rel_start[eax]
	mov	es:[root_start], esi	; save the rel start of the partition
	mov	es:[boot_start], esi	; save the rel start

	mov	dh, es:part_head[eax]	; read the boot sector
	mov	cl, es:part_sect[eax]
	mov	ch, es:part_cyln[eax]
	mov	dl, 80h
	mov	ax, 0201h		; read command
	int	13h

; save some values that are needed later

	mov	es:[boot_sect], bx	; save the disk positions
	mov	es:[boot_track], cx
	mov	es:[boot_cylinder], dx

	movzx	ax, es:cluster_size[bx]	; get the cluster size
	mov	es:[clust_size], ax
	mov	ax, es:root_entries[bx]	; number of entries in the root directory
	mov	es:[root_size], eax
	mov	ax, es:num_heads[bx]
	mov	es:[cfd_heads], al	; store the number of heads
	mov	ax, es:sec_per_track[bx]
	mov	es:[cfd_sec_pt], al	; store sectors per track
	mov	ax, es:fat_size[bx]	; sectors per fat  			
	mov	es:[fat_length], ax	; save it

; find the root directory	

	mov	esi, es:[root_start]	; only interested in the bottom word	
	mov	al, es:[cluster_size]
	push	ax		; number of sectors per cluster
	push	es:[root_entries]	; save the root dir size
	
	xor	dx, dx
	movzx	eax, es:fat_size[bx]	; sectors per fat  			
	xor	cx, cx
	mov	cl, es:num_fats[bx]	; number of fats  
	mul	cx
	add	ax, si		; boot sector relative + boot sector offset within patitiion  
	add	ax, es:res_sectors[bx]	; the number of reserved sectors  
	inc	ax
	mov	es:[root_start], eax	; save the pointer to the start of root

	xor	esi, esi
	xor	ecx, ecx
	mov	cx, es:sec_per_track[bx]	; sectors per track  
	div	cx		; divide ax by bx  
	mov	si, dx		; save the sector number  
	xor	dx, dx
	mov	cx, es:num_heads[bx]	; divide by the nuber of heads  
	div	cx		; ax - clyinder number dx - what head  
	mov	dh, dl		; move the head number  
		
	mov	cx, si		; the sector number  - low 8  
	mov	ch, al		; track number  
	mov	ax, 0201h		; read block - 1 block  
	mov	dl, 80h		; the drive number  
	int	13h		; read the drive  

; find the DSK file

	pop	ax		; root entries
	shr	ax ,4		; div by 16 - the of sectors that ROOT covers

	mov	es:sector, bx		; save the disk positions
	mov	es:track, cx
	mov	es:cylinder, dx
	xor	esi, esi

cfd_big_loop:	xor	edi, edi

cfd_loop:	mov	si, offset dsk_name	; offset of the name space
	mov	cx, 8		; search first 8 bytes					
	repe cmpsb
	jne	cfd_next		; if name
	mov	si, offset dsk_ext
	mov	cx, 3
	repe cmpsb
	je	file_found		; name & ext = 'cobos.ini'
	
cfd_next:	add	di, 32		; next entry
	and	di, 0fe0h		; round down to multiples of 32
	cmp	di, 512
	jb	cfd_loop

	push	ax
	mov	ax, 0201h
	mov	bx, es:sector		; get old sectors
	mov	cx, es:track
	mov	dx, es:cylinder

; increment the sector

	inc	cl
	cmp	cl, es:[cfd_sec_pt]	; sectors per track
	jbe	cfd_size		; not on next head
	
	mov	cl, 01
	inc	dh		; back to sector 1 then next head
	cmp	dh, es:[cfd_heads]	
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

cfd_size:	mov	es:sector, bx		; save the disk positions
	mov	es:track, cx
	mov	es:cylinder, dx
	xor	bx, bx		; buffer start at 0
	mov	ax, 0201h		; read 1 sector command
	int	13h		; read the sector
	
	pop	ax
	dec	ax
	jne	cfd_big_loop		; if 0 then exit

; Crash exit - DSK file not found!
	
cfd_crash:	mov	ax,4c04h
	int 21h			; exit back to DOS

;--------------------------
; Find the space in the FAT

file_found:	and	di, 0fe0h		; round down to multiples of 32
	mov	es:[root_entry], di	; save the disk file root entry
	mov	cx, es:[track]		; save the disk location
	mov	es:[root_track], cx
	mov	cx, es:[cylinder]
	mov	es:[root_cylinder], cx
	
	mov	es:[fat_count], 0
	xor	ecx, ecx
	mov	ax, es:[boot_sect]
	mov	es:[sector] ,ax
	mov	ax, es:[boot_track]
	mov	es:[track], ax
	mov	ax, es:[boot_cylinder]
	mov	es:[cylinder], ax
	jmp	find_inc		; read the first fat sector
	
find_loop:	cmp	es:fat_buffer[ecx*2],word ptr 0h	; read in words
	jne	find_not_free
	inc	es:[free_count]		; found a free cluster
	cmp	es:[free_count], inst_size	; need inst_size CLUSTERS	
	je	fill_FAT
	
find_ret:	inc	cx
	cmp	cx, 256		; if it rolls back to zero - 256 words read
	jne	find_loop

find_inc:	mov	bx, es:[sector]		; get old sectors
	mov	cx, es:[track]
	mov	dx, es:[cylinder]

; increment the sector

	inc	cl
	cmp	cl, es:[cfd_sec_pt]	; sectors per track
	jbe	find_size		; not on next head
	
	mov	cl, 01
	inc	dh		; back to sector 1 then next head
	cmp	dh, es:[cfd_heads]	
	jb	find_size		; if = no heads, then next cylinder
	
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

find_size:	mov	es:[sector], bx		; restore the disk positions
	mov	es:[track], cx
	mov	es:[cylinder], dx
	mov	ax, 0201h		; read 1 sector command
	mov	bx, offset fat_buffer	; load data into fat buffer
	int	13h		; read the sector
	
	inc	word ptr es:[fat_count]
	mov	ax, es:[fat_length]
	xor	ecx, ecx
	cmp	es:[fat_count], ax
	jb	find_loop		; if fat count reaches fat length
	
	mov	ax, 4c01h
	int	21h		; error - not enought free space
		
find_not_free:	mov	ax, es:[fat_count]
	dec	ax		; cluster is: (fat-1)*256+entry_number+1
	shl	ax, 8		; ax * 256
	add	ax, cx		; ax + entry_number
	mov	es:[start_cluster], ax	; cluster start number
	inc	ax
	and	ax, 0ff00h
	shr	ax, 8		; just incase the fat number increments	
	mov	es:[start_fat], ax	; start in this fat
	
	mov	es:[start_entry], cx
	inc	es:[start_entry]	; start is the next entry	
	mov	es:[free_count], 00	; set the count back to zero	
	jmp	find_ret

;--------------------------
; Fill the FAT

Fill_FAT:	movzx	eax, es:[start_fat]	; the starting fat entry
	add	eax, es:[boot_start]	; where the partition starts
	inc	eax		; starts after the boot sector
	inc	eax		; add 1 as the FAT the cluster is in is 1 greater

	xor	esi, esi
	xor	ecx, ecx
	movzx	cx, es:[cfd_sec_pt]	; sectors per track  
	xor	dx, dx
	div	cx		; divide ax by bx  
	mov	si, dx		; save the sector number  
	xor	dx, dx
	movzx	cx, es:[cfd_heads]	; divide by the nuber of heads  
	div	cx		; ax - clyinder number dx - what head  
	mov	dh, dl		; move the head number  
		
	mov	cx, si		; the sector number  - low 8  
	mov	ch, al		; track number  
	mov	ax, 0201h		; read block - 1 block  
	mov	dl, 80h		; the drive number  
	int	13h		; read the drive  

	mov	es:[track], cx
	mov	es:[cylinder], dx
	movzx	ecx, es:[start_entry]	; where to start the count from
	mov	ax, [start_cluster]
	mov	es:[cluster_num], ax
	
Fill_loop:	inc	es:[cluster_num]	; fill the cluster chain
	mov	ax, es:[cluster_num]
	mov	es:fat_buffer[ecx*2], ax
	
	dec	es:[free_count]		; has all the bits been written
	cmp	es:[free_count], 00
	je	Fill_exit

	inc	ecx
	cmp	ecx, 256
	jb	Fill_loop

	mov	cx, es:[track]
	mov	dx, es:[cylinder]
	mov	ax, 0301h		; write the block to disk
	int	13h	

; read next sector

	inc	cl
	cmp	cl, es:[cfd_sec_pt]	; sectors per track
	jbe	fill_size		; not on next head
	
	mov	cl, 01
	inc	dh		; back to sector 1 then next head
	cmp	dh, es:[cfd_heads]	
	jb	fill_size		; if = no heads, then next cylinder
	
	mov	dh, 00
	mov	ax, cx
	and	cl, 3fh		; clear all but the top two bits
	rol	cl, 2		; make top two bottom two
	ror	cx, 8		; place the whole thing at 0
	inc	cx		; increment the cylinder number

	rol	cx, 8
	ror	cl, 2
	and	al, 0c0h		; every thing but the top two bits
	and	al, cl		; new alls in place

fill_size:	mov	es:[track], cx		; restore the disk positions
	mov	es:[cylinder], dx
	mov	ax, 0201h		; read 1 sector command
	mov	bx, offset fat_buffer	; load data into fat buffer
	int	13h		; read the sector
	
	xor	ecx, ecx
	jmp	Fill_loop	

Fill_exit:	mov	es:fat_buffer[ecx*2], 0ffffh	; write the end of file line
	mov	cx, es:[track]
	mov	dx, es:[cylinder]
	mov	ax, 0301h		; write the block to disk
	int	13h	

;--------------------------
; create the COBOS FAT

; fill the FAT
	mov	ax, 0ffffh
	mov	ebx, offset fat_buffer
	mov	ecx, 1feh		; 256 fills
ccfl:	mov	es:[ebx+ecx], ax
	dec	ecx
	loop	ccfl
		
; calculate the fat size

	xor	edx, edx		; clear the high dword
	movzx	eax, es:[clust_size]
	imul	eax, inst_size		; cluster_size * inst-size = number of blocks
	mov	ecx, dword ptr 4096
	idiv	ecx		; (eax * inst-size) / (512 * 8) = number of bit fats
	
	mov	es:[bit_left_over], edx	; save the remainder	
	mov	edi, eax 

	mov	es:[fat_buffer], word ptr 00	; clear the FAT buffer
	cmp	edx, 00		; is it a whole FAT
	setne	byte ptr es:[fat_buffer]	; if roll over in the fat then set fat_buffer to 1
	add	es:[fat_buffer], ax	; the size of the FAT
	mov	es:2[fat_buffer], 0fffeh	; the realm table follows the FAT - 0 allocates block

; set the root size

	xor	edx, edx
	mov	eax, es:[root_size]
	imul	eax, 32		; root_entries * 32 = bytes of the root
	mov	ecx, 512		; sectors that the root uses
	div	ecx
	mov	es:[root_size], eax

; find and write the fat

	movzx	eax, es:[start_cluster]	; locate the fat
	sub	eax, 2
	movzx	ebx, es:[clust_size]
	imul	eax, ebx
	add	eax, es:[root_start]
	add	eax, es:[root_size]	; now positioned at the start of the COBOS.DSK
	mov	ebx, offset fat_buffer

	xor	esi, esi
	xor	ecx, ecx
	movzx	cx, es:[cfd_sec_pt]	; sectors per track  
	xor	edx, edx
	div	ecx		; divide ax by bx  
	mov	esi, edx		; save the sector number  
	xor	edx, edx
	movzx	ecx, es:[cfd_heads]	; divide by the nuber of heads  
	div	ecx		; ax - clyinder number dx - what head  
	mov	dh, dl		; move the head number  
		
	mov	cl, ah		; I want bits 9 and 10
	and	cl, 03h
	shl	cl, 06h		; need to be bits 7 & 8
	and	si, 003fh		; only uses 6 bits
	or	cx, si		; the sector number  - low 8  

	mov	ch, al		; track number  
	mov	dl, 80h		; the drive number  

	mov	es:[track], cx		; set the track
	mov	es:[cylinder], dx	; set the cylinder

	cmp	edi, 00
	je	write_part
	
write_next_fat:	mov	cx, es:[track]
	mov	dx, es:[cylinder]
	mov	ax, 0301h		; write the block to disk
	int	13h	

	mov	es:[ebx], word ptr 0ffffh	; clear the fat size

	mov	ah, cl
	and	ah, 0c0h		; only want the two top bits
	and	cl, 03fh		; only want the 6ix lower bits
	inc	cl
	cmp	cl, es:[cfd_sec_pt]	; sectors per track
	jbe	wrt_size		; not on next head
	
	mov	cl, 01
	inc	dh		; back to sector 1 then next head
	cmp	dh, es:[cfd_heads]	
	jb	wrt_size		; if = no heads, then next cylinder
	
	mov	dh, 00
	mov	ax, cx
	rol	cl, 2		; make top two bottom two
	ror	cx, 8		; place the whole thing at 0
	inc	cx		; increment the cylinder number

	rol	cx, 8
	ror	cl, 2
	and	al, 0c0h		; every thing but the top two bits
	and	al, cl		; new alls in place
	jmp	wrt_size2

wrt_size:	or	cl, ah		; replace the top two bits
wrt_size2:	mov	es:[track], cx		; restore the disk positions
	mov	es:[cylinder], dx

	dec	edi
	jne	write_next_fat

write_part:	mov	edi, es:[bit_left_over]
	and	eax, 07h		; bits inside a byte
	mov	edx, es:[bit_left_over]
	shr	edx, 3		; divide by 8

	mov	ebx, offset fat_buffer
	mov	ecx, 01ffh		; 512 fills
ccfl2:	mov	es:[ebx+ecx], byte ptr 00h
	dec	ecx		; clear down to tthe last bit
	cmp	ecx, edx
	jne	ccfl2	

	mov	cx, es:[track]
	mov	dx, es:[cylinder]
	mov	ax, 0302h		; write block - 2 blocks  
	int	13h		; write the drive  

;--------------------------
; amend the root entry

	movzx	ecx, es:[root_entry]	; get the position of the DSK file
	mov	ax, es:[start_cluster]	; set the start point of the cluster
	mov	es:f_cluster[ecx], ax

	movzx	eax, es:[clust_size]	; number of sectors in a cluster
	imul	eax, inst_size		; number of clusters allocated
	imul	eax, 200h		; 512 bytes per sector
	mov	es:f_length[ecx], eax
	
	mov	bx, offset root_buffer	; write the amended root buffer
	mov	cx, es:[root_track]
	mov	dx, es:[root_cylinder]
	mov	ax, 0301h
	int	13h
	
;--------------------------
; return back to DOS

exit_dos:	mov	ax,4c00h
	int	21h		; exit back to DOS

end	start 