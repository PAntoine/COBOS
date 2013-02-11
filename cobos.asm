comment	#=========================================================

	        Concurrent Object Based Operating System
		        (COBOS)
		 
	          BEng (Hons) Software Engineering for
	    	   Real Time Systems
	 	3rd Year Project 1996/97
		  
		  (c) 1996 P.Antoine
			     
	This program is kernal for the COBOS system. All the 
	talbes used here are defined in the loader program 
	COBOSLDR.ASM. This kernal is designed to run in 32bit
	PMODE, and will only use memeory above 1 meg.

	NOTE: This program assumes that the area above 1meg is
	      not being used at all - it will mess up any block
	      (EMM or XMS) that are used above 1meg!!!
	
	#========================================================
	
.386p
.model huge
	assume CS:_TEXT
	assume ss:astack

	include source\cobosh.asm       ; holds the structure definitions

;----------------------------------
; GLOBAL CONSTANTS

sys_segment     equ     08h     ; If the g_sys_segment is moved this must be changed 

;----------------------------------
;         DOS LOADER CODE
;----------------------------------
; This 16 bit segment is holds both
; the loader code and the return to
; DOS code.
;
	segment _TEXT public use16 'CODE'
start:

;==============================
; call cobos_find_disk to get
; the location of the DSK file

	mov	ax, astack
	mov	ss, ax
	mov	esp, 100h
	mov	ebp, esp

	assume	ds:disk_segment

	mov	ax, disk_segment
	mov	ds, ax		; points to the disk space segment

	call	cobos_find_dsk		; eax - returns the REAL sector number

	mov	edx, ds:[max_sector]	; the max number of sectors
	mov	cl, ds:[disk_heads]	; the number of heads
	mov	ch, ds:[disk_sector]	; number of sectors per track

	mov	bx, SYSTEM_SPACE
	mov	ds, bx

	mov	ds:[SYS.DOS_sector], ch
	mov	ds:[SYS.DOS_Heads], cl
	mov	ds:[SYS.DOS_max_sector], edx
	mov	ds:[SYS.DOS_srt_sector], eax	; realm block is changed in the start up!
	mov	ds:[SYS.realm_block], eax       ; save the offset in the system space

;===========================
; Set up the BASE addresses
; for the descriptors
;
	assume	ds:GDT

	mov	ax,0012h                ; set VGA to mode 12 640 x 480 16 colours
	int	10h

	mov	ax, GDT
	mov	ds, ax          ; load the Descriptor table
	
	xor	eax, eax

	mov	ax, _SYSTEM
	shl	eax, 4
	mov	word ptr ds:g_cobos[2], ax      ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_cobos[4], al      ; next byte of Descriptor

	mov	ax, SYSTEM_SPACE
	shl	eax, 4
	mov	word ptr ds:g_sys_segment[2],ax ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_sys_segment[4],al ; next byte of Descriptor

	mov	ax, TASKLIST
	shl	eax, 4
	mov	word ptr ds:g_tasklist[2], ax   ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_tasklist[4], al   ; next byte of Descriptor

	mov	ax, MALLOC_SPACE
	shl	eax, 4
	mov	word ptr ds:g_memlist[2], ax    ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_memlist[4], al    ; next byte of Descriptor

	mov	ax, DEVTABLE
	shl	eax, 4
	mov	word ptr ds:g_devlist[2], ax    ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_devlist[4], al    ; next byte of Descriptor

	mov	ax, OBJECT_SPACE
	shl	eax, 4
	mov	word ptr ds:g_object[2], ax     ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_object[4], al     ; next byte of Descriptor

	mov	ax, MDSIO_SPACE
	shl	eax, 4
	mov	word ptr ds:g_MDSIO[2], ax      ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_MDSIO[4], al      ; next byte of Descriptor

	mov	ax, HOTSPOTS
	shl	eax, 4
	mov	word ptr ds:g_HOTS[2], ax       ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_HOTS[4], al       ; next byte of Descriptor

	mov	ax, GDT
	shl	eax, 4
	mov	word ptr ds:g_gdt[2], ax        ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_gdt[4], al        ; next byte of Descriptor

	mov	ax, IDT
	shl	eax, 4
	mov	word ptr ds:g_idt[2], ax        ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_idt[4], al        ; next byte of Descriptor

	mov	ax, BASIC_CHARSET
	shl	eax, 4
	mov	word ptr ds:g_charset[2], ax    ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_charset[4], al    ; next byte of Descriptor

	mov	ax, BASIC_KEY_TAB
	shl	eax, 4
	mov	word ptr ds:g_keytab[2], ax	; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_keytab[4], al	; next byte of Descriptor

	mov	ax, ASCII_KEY_TAB
	shl	eax, 4
	mov	word ptr ds:g_a_keytab[2], ax	; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_a_keytab[4], al	; next byte of Descriptor

	mov	ax, USER_COMMANDS
	shl	eax, 4
	mov	word ptr ds:g_us_comms[2], ax	; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_us_comms[4], al	; next byte of Descriptor

	mov	ax, SYS_MESSAGES
	shl	eax, 4
	mov	word ptr ds:g_messages[2], ax   ; base of Descriptor
	shr	eax, 16
	mov	byte ptr ds:g_messages[4], al   ; next byte of Descriptor

; tss's
	mov	ax, TSS_SPACE           ; base address for the TSS's
	shl	eax, 4
	mov	ebx, eax
	mov	word ptr ds:g_DOS_tss[2], bx    
	shr	ebx, 16
	mov	byte ptr ds:g_DOS_tss[4], bl    

	mov	ebx, eax                ; set up system TSS
	add	ebx, offset tss_COBOS
	mov	word ptr ds:g_cobos_tss[2], bx  
	shr	ebx, 16
	mov	byte ptr ds:g_cobos_tss[4], bl  
	
	mov	ebx, eax                ; set up int 8 TSS
	add	ebx, offset tss_int_8
	mov	word ptr ds:g_int_8_tss[2], bx  
	shr	ebx, 16
	mov	byte ptr ds:g_int_8_tss[4], bl  
	
	mov	ebx, eax                ; set up int a TSS
	add	ebx, offset tss_int_a
	mov	word ptr ds:g_int_a_tss[2], bx  
	shr	ebx, 16
	mov	byte ptr ds:g_int_a_tss[4], bl  
	
	mov	ebx, eax                ; set up int c TSS
	add	ebx, offset tss_int_c
	mov	word ptr ds:g_int_c_tss[2], bx
	shr	ebx, 16
	mov	byte ptr ds:g_int_c_tss[4], bl  
	
	mov	ebx, eax                ; set up exception TSS
	add	ebx, offset tss_excpt
	mov	word ptr ds:g_excpt_tss[2], bx  
	shr	ebx, 16
	mov	byte ptr ds:g_excpt_tss[4], bl  

	mov	ebx, eax                ; set up timer TSS and data seg
	add	ebx, offset tss_Timer
	mov	word ptr ds:g_timer[2], bx      
	mov	word ptr ds:g_timer_dta[2],bx
	shr	ebx, 16
	mov	byte ptr ds:g_timer[4], bl      
	mov	byte ptr ds:g_timer_dta[4], bl
	
	mov	ebx, eax                ; set up user TSS
	add	ebx, offset tss_user
	mov	word ptr ds:g_user[2], bx       
	shr	ebx, 16
	mov	byte ptr ds:g_user[4], bl       
	
	mov	ebx, eax                ; set up serial mouse TSS
	add	ebx, offset tss_sermouse
	mov	word ptr ds:g_sermouse[2], bx   
	shr	ebx, 16
	mov	byte ptr ds:g_sermouse[4], bl   
; stacks
	xor	eax, eax
	mov	ax, ASTACK              ; base address for the STACKS
	shl	eax, 4
	mov	ebx, eax                ; set up level 0 stack
	add	ebx, offset stck_0
	mov	word ptr ds:g_stk_0[2], bx      
	shr	ebx, 16
	mov	byte ptr ds:g_stk_0[4], bl      

	mov	ebx, eax                ; set up level 1 stack
	add	ebx, offset stck_1
	mov	word ptr ds:g_stk_1[2], bx
	shr	ebx, 16
	mov	byte ptr ds:g_stk_1[4], bl

	mov	ebx, eax                ; set up level 2 stack
	add	ebx, offset stck_2
	mov	word ptr ds:g_stk_2[2], bx
	shr	ebx, 16
	mov	byte ptr ds:g_stk_2[4], bl

	mov	ebx, eax                ; set up level 0 crash stack
	add	ebx, offset crsh_0
	mov	word ptr ds:g_stk_csh0[2], bx
	shr	ebx, 16
	mov	byte ptr ds:g_stk_csh0[4], bl

	mov	ebx, eax                ; set up level 0 exception stack
	add	ebx, offset excpt_0
	mov	word ptr ds:g_stk_excpt[2], bx
	shr	ebx, 16
	mov	byte ptr ds:g_stk_excpt[4], bl

	mov	ebx, eax                ; set up stack for the timer task
	add	ebx, offset timr_stk
	mov	word ptr ds:g_stk_timer[2], bx  
	shr	ebx, 16
	mov	byte ptr ds:g_stk_timer[4], bl  

	mov	ebx, eax                ; set up stack for the user input task
	add	ebx, offset user_stk
	mov	word ptr ds:g_stk_user[2], bx   
	shr	ebx, 16
	mov	byte ptr ds:g_stk_user[4], bl   

	mov	ebx, eax                ; set up stack serial mouse task
	add	ebx, offset muse_stk
	mov	word ptr ds:g_stk_sermse[2], bx 
	shr	ebx, 16
	mov	byte ptr ds:g_stk_sermse[4], bl 
	
;=======================================
; Re-point PIC interrupts from the IBM 
; strange place, to after the exception
; interrupts (plus intel reserved)
;
; start interrupt must be div by 8, 
; bottom three bits are used internally
;
	cli                     ; turn off the interupts that we are about to amend
	
set_PIC_mast:   mov	al, 11h		; ICW1 (cascade, ICW4, Edge triggered, interval of 8)
	out	PIC_mast_a0, al		; send ICW1
	
	mov	al, 20h		; ICW2 ( start interupt number - 21h first non reserved)
	out	PIC_mast_a1, al

	mov	al, 04h		; ICW3 ( device IR2 is the slave)
	out	PIC_mast_a1, al

	mov	al, 01h		; ICW4 ( 8086/8088 mode - EOI = 0 , must aknowledge ints)
	out	PIC_mast_a1, al

set_PIC_slave:  mov	al, 11h		; ICW1
	out	PIC_slave_a0, al
	
	mov	al, 28h		; ICW2 ( next 8 interrupts )
	out	PIC_slave_a1, al
	
	mov	al, 02h		; ICW3 ( slave on IR2 of the master )
	out	PIC_slave_a1, al
	
	mov	al, 01h		; ICW4 
	out	PIC_slave_a1, al        

;========================
; set up DOS return ptr

	assume  ds:SYSTEM_SPACE

	mov	ax, SYSTEM_SPACE
	mov	ds, ax
	mov	ds:[DOS_seg], offset g_dos_code


	xor	eax, eax
	mov	ax, _TEXT
	shl	eax, 4
	add	eax, offset Drop_to_RM
	mov	ds:[DOS_return], eax    ; the linear address (segment starts at 0000)

;========================
; Swap to protected mode

	assume  ds: DATA_SPACE

	mov	ax, DATA_SPACE
	mov	ds, ax
	mov	word ptr ds:[data_seg], ds      ; must know where the data_seg is 
	mov	word ptr ds:[stack_seg], ss     ; must know where the stack is
	mov	word ptr ds:[stack_pnt], sp     ; must know where the stack pointer is
	mov	word ptr ds:[base_ptr], bp      ; save the base ptr

	sgdt	fword ptr ds:[save_gdt] ;save the global descriptor table
	sidt	fword ptr ds:[save_idt] ;save the interrupt descriptor table
	
	xor	eax, eax
	mov	ax, GDT
	shl	eax, 4
	mov	word ptr ds:[load_gdt], 0800h   ; the limit of the gdt
	mov	dword ptr ds:2[load_gdt], eax   ; the linear offset of the gdt
	
	xor	eax, eax
	mov	ax, IDT
	shl	eax, 4
	mov	word ptr ds:[load_idt], 0800h   ; the limit of the gdt
	mov	dword ptr ds:2[load_idt], eax   ; the linear offset of the gdt

	lgdt	fword ptr ds:[load_gdt] ;loads the gdt
	lidt	fword ptr ds:[load_idt] ; load the idt
	
	mov	eax, cr0
	or	eax, 01		; set the PM bit
	mov	cr0, eax		; now in PMODE
	jmp	c_here		; clear the prefetcher

c_here:	mov	ax, offset g_DOS_tss	; the dummy tss for the task switch
	ltr	ax
	
	fjmp16	g_cobos_tss,0000	; jump to initial system TSS 

;========================
; restore machine to a
; state that DOS likes

drop_to_RM:     mov	ax, offset g_DOS_data	; dos type data segment
	mov	ds, ax          
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax
	
	xor	eax, eax
	xor	ebx, ebx
	xor	ecx, ecx
	xor	edx, edx
	xor	edi, edi
	xor	esi, esi
	xor	esp, esp
	xor	ebp, ebp

	mov	eax,cr0		; get CR0 into EAX
	and	eax,not 1		; clear Protected Mode bit
	mov	cr0,eax		; after this we are back in Real Mode!

	mov	ax, DATA_SPACE
	mov	ds, ax		; the data segment name

	cli
	lgdt	fword ptr ds:[save_gdt] ; restore the DOS gdt
	lidt	fword ptr ds:[save_idt] ; restore the DOS ints

;=========================================
; Re-point PIC interrupts back to the IBM 
; strange place.
;
reset_PIC_mast: mov	al, 11h		; ICW1 (cascade, ICW4, Edge triggered, interval of 8)
	out	PIC_mast_a0, al		; send ICW1
	
	mov	al, 08h		; ICW2 ( start interupt number - 08h first IBM )
	out	PIC_mast_a1, al
	
	mov	al, 04h		; ICW3 ( device IR2 is the slave)
	out	PIC_mast_a1, al
	
	mov	al, 01h		; ICW4 ( 8086/8088 mode - EOI = 0 , must aknowledge ints)
	out	PIC_mast_a1, al

rset_PIC_slave: mov	al, 11h		; ICW1
	out	PIC_slave_a0, al

	mov	al, 70h		; ICW2 ( start at 70h (DOS standard)  )
	out	PIC_slave_a1, al
	
	mov	al, 02h		; ICW3 ( slave on IR2 of the master )
	out	PIC_slave_a1, al
	
	mov	al, 01h		; ICW4 
	out	PIC_slave_a1, al        

;=========================
; restore segments & exit

	mov	ds, word ptr ds:[data_seg]
	mov	ss, word ptr ds:[stack_seg]
	mov	sp, word ptr ds:[stack_pnt]
	mov	bp, word ptr ds:[base_ptr]
	sti			; restart interrupts

	mov	ax,4c00h
	int	21h		; exit back to DOS
	ret

;-----------------------
; Find disk file code 

	include source\cfinddsk.asm

	_TEXT ENDS      

;======================================
;          SYSTEM SEGMENT
;--------------------------------------
; Basically this is the 32bit 
; code for the Kernal
;
	segment _SYSTEM use32 'CODE'
	assume cs:_SYSTEM
.386p

cobos_system:   mov	ax, sys_segment
	mov	ds, ax
	bts	ds:[sys.semaphores], ss_system  ; on error dont set the task error

;---------------------------------
; set PIT mode - fire once @ 40Hz

	mov	al, 30h
	out	43h, al         ; mode 0 - LSB & MSB
	mov	al, 85h
	out	40h, al
	mov	al, 78h
	out	40h, al

;--------------------------------
; create realm buffer

	push	word ptr ax		; owner - the device task
	push	word ptr 4092h		; type (32bit data)
	push	dword ptr 400h		; 1024 bytes (2 device blocks)
	call	allocate_memory
	mov	ds:[sys.realm_buffer], ax

;--------------------------------
; initialise the exception task

	fcall	g_excpt_tss, 0000           ; call the exception task

;--------------------------------
; create the video task

	push	word ptr 0100h		; stack size
	push	word ptr 0020h		; index size
	push	word ptr 0300h		; message size
	call	create_tcb
	push	eax

	shr	eax, 16
	mov	fs, ax		; load FS with TSS

	mov	fs:[TSS.tsk_cs],offset g_cobos	; it is in the system code segment
	mov	fs:[TSS.tsk_EIP],offset cw_init	; starts at check_winds initialiser

	call	add_task

	xor	eax, eax
	mov	ax, offset g_gdt	; the gdt data segment
	mov	gs, ax
	mov	ax, fs		; TSS segment
	mov	gs:5[eax], byte ptr 8bh	; make it a TSS (active)
	mov	ax, 00h
	mov	fs, ax		; clear FS so stops TSS load errors

;--------------------------------
; create postbox task

	push	word ptr 0100h		; stack size
	push	word ptr 0010h		; index size
	push	word ptr 0050h		; message size
	call	create_tcb
	push	eax

	shr	eax, 16
	mov	fs, ax		; load FS with TSS

	mov	fs:[TSS.tsk_cs],offset g_cobos	; it is in the system code segment
	mov	fs:[TSS.tsk_EIP],offset postbox	; starts at postbox initialiser

	call	add_task

	xor	eax, eax
	mov	ax, offset g_gdt	; the gdt data segment
	mov	gs, ax
	mov	ax, fs		; TSS segment
	mov	gs:5[eax], byte ptr 8bh	; make it a TSS (active)
	mov	ax, 00h
	mov	fs, ax		; clear FS so stops TSS load errors

;-----------------------------------
; load the default device driver

	push	word ptr 0100h		; stack size
	push	word ptr 0020h		; index size
	push	word ptr 0300h		; message size
	call	create_tcb
	push	eax

	mov	fs, ax		; load the TCB
	bts	fs:[TCB.status], t_suspended	; task suspended - activate when needed
	shr	eax, 16
	mov	fs, ax		; load FS with TSS

	mov	fs:[TSS.tsk_cs],offset g_cobos	; it is in the system code segment
	mov	fs:[TSS.tsk_EIP],offset idedev	; starts at ide device driver
	call	add_task

	mov	gs, ds:[sys.device_list]	; get the device table
	mov	ebx, ds:[sys.realm_block]	; temp hold for the FAT
	mov	gs:[DEVICE.d_FAT], ebx
	mov	gs:[DEVICE.d_handler],ax	; store the task of the device 

	push	word ptr ax		; owner - the device task
	push	word ptr 4092h		; type (32bit data)
	push	dword ptr 200h		; 512 bytes (1 device block)
	call	allocate_memory
	
	mov	gs:[DEVICE.d_FAT_buffer], ax	; the fat buffer
	mov	gs:[DEVICE.d_FAT_block], 00h	; no block in the FAT buffer

	push	word ptr ax		; owner - the device task
	push	word ptr 4092h		; type (32bit data)
	push	dword ptr (br_r_size * 30)+12	; 30 queue request entries
	call	allocate_memory

	mov	gs:[DEVICE.d_queue_seg], ax	; the queue segment
	mov	fs:[TSS.tsk_es], ax	; let the task know where it is
	mov	gs, ax
	mov	gs:[BRD.brd_size], 30	; 30 entries
	mov	gs:[BRD.brd_head], 00	; queue empty
	mov	gs:[BRD.brd_tail], 00	; queue empty	

	xor	eax, eax
	mov	ax, offset g_gdt	; the gdt data segment
	mov	gs, ax
	mov	ax, fs		; TSS segment
	mov	gs:5[eax], byte ptr 8bh	; make it a TSS (active)
	mov	ax, 00h
	mov	fs, ax		; clear FS so stops TSS load errors

;-----------------------------------
; load the command and control task

	push	word ptr 0200h		; stack size
	push	word ptr 0020h		; index size
	push	word ptr 0300h		; message size
	call	create_tcb
	push	eax

	mov	fs, ax		; load the TCB
	bts	fs:[TCB.status], t_KB	; allow key board input to the task
	bts	fs:[TCB.status], t_MOUSE	; allow mouse input to the task
	shr	eax, 16
	mov	fs, ax		; load FS with TSS

	mov	fs:[TSS.tsk_cs],offset g_cobos	; it is in the system code segment
	mov	fs:[TSS.tsk_EIP],offset comcon	; starts at command and control init
	call	add_task

	mov	ds:[sys.user_task], ax	; make the com-control the user task

	xor	eax, eax
	mov	ax, offset g_gdt	; the gdt data segment
	mov	gs, ax
	mov	ax, fs		; TSS segment
	mov	gs:5[eax], byte ptr 8bh	; make it a TSS (active)
	mov	ax, 00h
	mov	fs, ax		; clear FS so stops TSS load errors

;--------------------------------
; end of initialisation

	btr	ds:[sys.semaphores], ss_system	; clear the "system" bit
	btr	ds:[sys.semaphores], ss_screen	; free the screen
	sti			; let the system run

cobos_loop:     hlt    			; main loop - system interupt driven
	jmp	cobos_loop

;--------------------------------
; return to DOS jump 

x_int_nu:				; crash exit - interrupt not definied
cobos_exit:     call	clear_mouse
	
	mov	al, 34h
	out	43h, al		; PIT command byte: mode 2 -LSB&MSB
	mov	al, 00
	out	40h, al		; max counter range -just how DOS likes it
	out	40h, al

	mov	ax, sys_segment
	mov	es, ax
	jmp	fword ptr es:[dos_return]	; far jmp to 16bit segment 

;--------------------------------
; The System functions
; the (A) functions are API

	include source\sttskerr.asm		; set the error code and bit in the calling task
	include source\crgendsc.asm		; create general descriptor
	include source\deldesc.asm		; will clear a GDT descriptor
	include source\malloc.asm		; memory allocation function
	include source\freemem.asm		; will free a memory allocation
	include source\creattcb.asm		; creates the task control block
	include source\deltcb.asm		; deletes the task control block
	include source\addtask.asm		; will add a task to the task list
	include source\deltask.asm		; will remove a task from the task list
	include source\sendmess.asm		; (A) send message to a task
	include source\readmess.asm		; (A) reads a message from the task
	include source\mousedrw.asm		; will draw a mouse pointer on screen
	include source\mouseclr.asm		; clears the mouse pointer from the screen
	include source\chkmouse.asm		; this will check the mouse action
	include source\drwwidw.asm		; will redraw the window
	include source\clrwidw.asm		; will draw a black box where the window is
	include source\buildmap.asm		; will build a screen map
	include source\xsection.asm		; part of build map - extends the x-sections
	include source\cpyxchn.asm		; part of build map - copys the x chain
	include source\chkwidws.asm		; a task that will check the state of the screen funiture
	include source\drwbordr.asm		; (A) draws a pretty border around the screen
	include source\addhtspt.asm		; (A) will add a hotspot to the hotspot table
;	include source\remhtspt.asm		; (A) will delete a hot spot from the table
;	include source\amdhtspt.asm		; (A) changes the hot spot values
	include source\disptext.asm		; (A) displays inside a screen text
	include source\blkreqst.asm		; (A) the block request function
	include source\allocblk.asm		; function allocates 1 block from the device
	include source\freeblk.asm		; function frees an given block from the device
	include source\chkperm.asm		; checks the permissions and locates the file
	include source\creatrlm.asm		; (A) adds a realm to the realm table
	include source\deletrlm.asm		; (A) removes a realm from the realm table
	include source\opnmdsio.asm		; (A) opens a MDSIO object
	include source\clsmdsio.asm		; (A) closes a MDSIO object
	include source\crtmdsio.asm		; (A) creates an MDSIO object
	include source\wrtmdsio.asm		; (A) writes a block to the MDSIO object
	include source\rdmdsio.asm		; (A) reads a block from the MDSIO object
	include source\extmdsio.asm		; (A) extends a MDSIO object
	include source\convkey.asm		; (A) converts the keyboard to a charset
	include source\instring.asm		; (A) this function reads a string from the keyboard
	include source\shell.asm		; (A) this is the user shell
	
;--------------------------------
; interrupt handler code

	include	source\excepton.asm	; the code to handle the exceptions
timer:	include	source\timerint.asm	; The task switch code
user:	include	source\userinpt.asm	; the keyboard and PS\2 mouse code
smouse:	include	source\sermouse.asm	; handles the serial mouse
comcon:	include	source\comctrl.asm	; the command and control code
postbox:	include	source\postbox.asm	; the system to user postbox
idedev:	include	source\idedrive.asm	; the IDE device driver code
idehand:	include	source\idehand.asm	; the IDE interrupt handler

;---------------------------------
; The PIC is set up in aknowledge
; mode, so this code acknoldges
; both PIC's
;
ack_PIC:        push	eax
	mov	al, 20h		; OCW2 ( nonspecific end of interrupt - release the PIC )
	out	PIC_slave_a0, al        
	out	PIC_mast_a0, al
	pop	eax
	ret

	assume cs:_TEXT
	_SYSTEM ENDS

;--------------------------------
;      SYSTEM TABLES
;--------------------------------
; This is the data space for the
; system tables, with the default
; values that will be needed on
; start up.
;
	segment GDT use16
	SegDesc <0000h,0000h,00h,00h,00h,00h>	; Null segment not used
g_sys_segment	SegDesc <0ffffh,0000h,00h,92h,40h,00h>	; system data segment (32bit)
g_cobos	SegDesc <0ffffh,0000h,00h,9ah,40h,00h>	; COBOS Code segment  (32bit)
g_DOS_tss	SegDesc <0068h,0000h,00h,89h,00h,00h>	; DOS TSS needed for initial task switch
g_cobos_tss	SegDesc <0068h,0000h,00h,89h,00h,00h>	; COBOS opsys task
g_int_8_tss	SegDesc <0068h,0000h,00h,89h,00h,00h>	; Double Fault task
g_int_a_tss	SegDesc <0068h,0000h,00h,89h,00h,00h>	; Stack fault task
g_int_c_tss	SegDesc <0068h,0000h,00h,89h,00h,00h>	; Invaild TSS TSS
g_excpt_tss	SegDesc <0068h,0000h,00h,89h,00h,00h>	; exception TSS
g_stk_0	SegDesc <0100h,0000h,00h,92h,40h,00h>	; level 0 stack (32bit)
g_stk_1	SegDesc <0100h,0000h,00h,0a2h,40h,00h>	; level 1 stack (32bit)
g_stk_2	SegDesc <0100h,0000h,00h,0c2h,40h,00h>	; level 2 stack (32bit)
g_stk_csh0	SegDesc <0100h,0000h,00h,92h,40h,00h>	; level 0 crash stack (32bit)
g_stk_excpt	SegDesc <0100h,0000h,00h,92h,40h,00h>	; level 0 exception stack (32bit)
g_stk_timer	SegDesc <0050h,0000h,00h,92h,40h,00h>	; level 0 timer int stack (32bit)
g_stk_user	SegDesc <0050h,0000h,00h,92h,40h,00h>	; level 0 user int stack (32bit)
g_stk_sermse	SegDesc <0100h,0000h,00h,92h,40h,00h>	; level 0 serial mouse stack (32bit)
g_stk_IDEDrv	SegDesc <0050h,0000h,00h,92h,40h,00h>	; level 0 IDE Driver stack (32bit)
g_tasklist	SegDesc <0800h,0000h,00h,92h,40h,00h>	; task list segment (32bit)
g_memlist	SegDesc <0bf4h,0000h,00h,92h,40h,00h>	; memory allocation (32bit)
g_devlist	SegDesc <21deh,0000h,00h,92h,40h,00h>	; dev list (32bit)
g_sftint	SegDesc <0320h,0000h,00h,92h,40h,00h>	; soft ints (32bit)
g_hrdint	SegDesc <0258h,0000h,00h,92h,40h,00h>	; hard ints (32bit)
g_object	SegDesc <18e7h,0000h,00h,92h,40h,00h>	; object table (32bit)
g_lobject	SegDesc <0000h,0000h,00h,92h,40h,00h>	; loaded objects (32bit)
g_MDSIO	SegDesc <6d92h,0000h,00h,92h,40h,00h>	; MDSIO table (32bit)
g_IDT	SegDesc <0220h,0000h,00h,92h,40h,00h>	; IDT data segment (32bit)
g_GDT	SegDesc <0838h,0000h,00h,92h,40h,00h>	; GDT data segemnt (32bit)
g_HOTS	SegDesc <0ed8h,0000h,00h,92h,40h,00h>	; HOTSPOT data segment (32Bit)
g_DOS_code	SegDesc <0ffffh,0000h,00h,9ah,0fh,00h>	; DOS code segment (16bit)
g_DOS_data	SegDesc <0ffffh,0000h,00h,92h,0fh,00h>	; DOS data segment (16bit)
g_real_srn	SegDesc <0ffffh,0000h,0ah,92h,41h,00h>	; 16 colour screen (640x480)
g_timer	SegDesc <0068h,0000h,00h,89h,00h,00h>	; TSS for timer interrupt task
g_timer_dta	SegDesc <0068h,0000h,00h,92h,40h,00h>	; Data segment that points to timer TSS
g_user	SegDesc <0068h,0000h,00h,89h,00h,00h>	; TSS for the PS/2 and Keyboard task
g_sermouse	SegDesc <0068h,0000h,00h,89h,00h,00h>	; TSS for the serial mouse task
g_IDEDrive	SegDesc <0068h,0000h,00h,89h,00h,00h>	; TSS for the IDE driver task
g_charset	SegDesc <08d0h,0000h,00h,92h,40h,00h>	; Basic Charater set
g_keytab	SegDesc <01f8h,0000h,00h,92h,40h,00h>	; Basic Keyboard table
g_a_keytab	SegDesc <01f8h,0000h,00h,92h,40h,00h>	; ASCII Keyboard table
g_us_comms	SegDesc <0027h,0000h,00h,92h,40h,00h>	; Shell command table
g_messages	SegDesc <00ffh,0000h,00h,92h,40h,00h>	; system message text - COBOS format
	SegDesc 221 dup (<>)    
	GDT     ENDS

	segment IDT use16
;**** Exceptions ****
i_divide       	SegDesc <x_int_0,g_cobos,00,8eh,00,00>	; devide error (gate)
i_debug	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; debugger error (gate)
i_NMI  	SegDesc <x_int_2,g_cobos,00,8eh,00,00>	; NMI error (gate)
i_Break	SegDesc <x_int_3,g_cobos,00,8eh,00,00>	; Breakpoint error (gate)
i_Overflow     	SegDesc <x_int_4,g_cobos,00,8eh,00,00>	; Overflow error (gate)
i_Array	SegDesc <x_int_5,g_cobos,00,8eh,00,00>	; Array bound error (gate)
i_Opcode       	SegDesc <x_int_6,g_cobos,00,8eh,00,00>	; invaild opcode error (gate)
i_CoPro	SegDesc <x_int_7,g_cobos,00,8eh,00,00>	; Coprocessor not available error (gate)
i_Double       	SegDesc <x_int_8,g_cobos,00,8eh,00,00>	; double fault error (task)
i_CoProSeg     	SegDesc <x_int_9,g_cobos,00,8eh,00,00>	; Co pro segment error (gate)
i_invTSS       	SegDesc <x_int_a,g_cobos,00,8eh,00,00>	; Invalid tss (task)
i_Present      	SegDesc <x_int_b,g_cobos,00,8eh,00,00>	; devide error (gate)
i_Stack	SegDesc <x_int_c,g_cobos,00,8eh,00,00>	; stack fault (task)
i_GPF  	SegDesc <x_int_d,g_cobos,00,8eh,00,00>	; General Protection fault (gate)
i_Page 	SegDesc <x_int_e,g_cobos,00,8eh,00,00>	; page Fault (gate)
i_RESEVED_1    	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; <Intel Reseved>
i_CoProErr     	SegDesc <x_int_10,g_cobos,00,8eh,00,00>	; Co Pro error (gate)
i_Alinment     	SegDesc <x_int_11,g_cobos,00,8eh,00,00>	; (486) alinment error (gate)
	SegDesc 14 dup (<>)		; <INTEL RESERVED>
;**** Hardware ****
i_Timer	SegDesc <0000,g_timer,00,85h,00,00>	; timer task (H/W 1)
i_keyboard     	SegDesc <0000,g_user,00,85h,00,00>	; User input (H/W 2)
i_unused       	SegDesc <0000,g_timer,00,85h,00,00>	; Cant be actioned by H/W
i_COM2 	SegDesc <0000,g_sermouse,00,85h,00,00>	; COM 1 (H/W 4)
i_COM1 	SegDesc <0000,g_sermouse,00,85h,00,00>	; COM 2 (H/w 4)
i_Fixed	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; LPT2
i_Floppy       	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; Floppy disk
i_printer      	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; LPT1
i_unsed_2      	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; Real Time Clock
i_unsed_3      	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; PIC ints unassigned
i_unsed_4      	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; PIC ints unassigned
i_unsed_5      	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; PIC ints unassigned
i_unsed_6      	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; PIC ints unassigned
i_unsed_7      	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; Co-Processor
i_unsed_8      	SegDesc <idehand,g_cobos,00,8eh,00,00>	; Hard Disk (IDE)
i_unsed_9      	SegDesc <x_int_nu,g_cobos,00,8eh,00,00>	; PIC ints unassigned
	SegDesc 20 dup (<>)
	IDT     ENDS

	segment MALLOC_SPACE use16
	MALLOC  <300000h,00,00,10ffefh>		; mem space from 1meg - 4meg
	MALLOC  254 dup (<>)
	MALLOC_SPACE    ENDS

	segment DEVTABLE use16
	DEVICE  255 dup (<>)
	DEVTABLE        ENDS

	segment TASKLIST use16
	TASK    256 dup (<>)
	TASKLIST        ENDS

	segment MDSIO_SPACE use16
	MDSIO   255 dup (<>)
	MDSIO_SPACE     ENDS    

	segment OBJECT_SPACE use16
	OBJECT  255 dup (<>)
	OBJECT_SPACE    ENDS

	segment HOTSPOTS use16
	HOTSPOT 100 dup (<>)
	HOTSPOTS        ENDS

	segment HARDINTS use16
	HARD_INT        100 dup (<>)
	HARDINTS        ENDS

	segment SOFTINTS use16
	SOFT_INT        100 dup (<>)
	SOFTINTS        ENDS    

	segment SYSTEM_SPACE use16
	SYS     <,0,g_real_srn,g_tasklist,255,g_memlist,255,g_devlist,255,g_IDT,255,g_GDT,255,g_sftint,100,g_hrdint,100,g_object,255,g_lobject,0,g_MDSIO,255,g_HOTS,100,,,,,,,,,,640,480,g_charset,,g_messages>
	SYSTEM_SPACE    ENDS

;------------------------------
; COBOS system data areas
;------------------------------
; Data areas that are used by 
; cobos system. These are read
; only areas.
;
	segment BASIC_CHARSET use32
	include	source\bcharset.asm
	BASIC_CHARSET   ENDS
	
	segment	BASIC_KEY_TAB use32
	include	source\bkeytab.asm
	BASIC_KEY_TAB	ENDS

	segment	ASCII_KEY_TAB use32
	include	source\akeytab.asm
	ASCII_KEY_TAB	ENDS

usc_num_comms	equ	3

	segment	USER_COMMANDS use32
usc_index	USC_IND	<usc_comm_exit,us_exit>,<usc_comm_disp,us_exit>,<usc_comm_dump,us_exit>
usc_comm_exit	db	04h,12h,38h,1ah,30h		; EXIT
usc_comm_disp	db	07h,10h,1ah,2eh,28h,20h,0ah,3ah		; DISPLAY
usc_comm_dump	db	04h,10h,32h,22h,28h		; DUMP
	USER_COMMANDS	ENDS

	segment SYS_MESSAGES use32
mess_cobos      db	05h,0eh,26h,0ch,26h,2eh                 ; COBOS
mess_excpt      db	0bh,0ffh,12h,38h,0eh,12h,28h,30h,1ah,26h,24h,0ffh       ; EXCEPTION
mess_error      db	05h,12h,2ch,2ch,26h,2ch                 ; ERROR
mess_eax        db	04h,12h,0ah,038h,0ffh                   ; EAX
mess_ebx        db	04h,12h,0ch,038h,0ffh                   ; EBX
mess_ecx        db	04h,12h,0eh,038h,0ffh                   ; ECX
mess_edx        db	04h,12h,10h,038h,0ffh                   ; EDX
mess_esi        db	04h,12h,02eh,01ah,0ffh                  
mess_edi        db	04h,12h,10h,01ah,0ffh                   
mess_ds	db	03h,10h,02eh,0ffh                  
mess_es	db	03h,12h,02eh,0ffh                  
mess_fs	db	03h,14h,02eh,0ffh                  
mess_gs	db	03h,16h,02eh,0ffh                  
mess_task	db	05h,030h,0ah,02eh,01eh,0ffh
mess_code	db	05h,0eh,026h,10h,12h,0ffh
mess_stack	db	06h,02eh,030h,0ah,0eh,01eh,0ffh
mess_copyright  db	0eh,0eh,26h,28h,3ah,2ch,1ah,16h,18h,30h,060h,01,09,09,06        ; (C) message
mess_version	db	11h,0ah,20h,28h,18h,0ah,60h,34h,12h,2ch,2eh,1ah,26h,24h,60h,01h,60h,01h
mess_un_comm	db	0fh,32h,24h,1eh,24h,26h,36h,24h,60h,0eh,26h,22h,22h,0ah,24h,10h
mess_goodbye	db	07h,16h,26h,26h,10h,0ch,3ah,12h			; goodbye
	SYS_MESSAGES    ENDS

;------------------------------
;      PMODE system TSS's
;------------------------------
; This segment holds the task
; segments the the system will
; need.
;
	segment TSS_SPACE use16
tss_DOS TSS     <>
tss_COBOS       TSS     <,,0100h,g_stk_0,,0100h,g_stk_1,,0100h,g_stk_2,,0,0,0,0,0,0,0,0100h,0100h,0,0,0,,g_cobos,,g_stk_0,,0,,0,,0,,0,,0>
tss_INT_8       TSS     <,,,,,,,,,,,0,x_int_nu,0,0,0,0,0,0100h,0100h,0,0,g_sys_segment,,g_cobos,,g_stk_csh0,,g_tasklist,,0,,0,,0,,0>
tss_INT_A       TSS     <,,,,,,,,,,,0,x_int_nu,0,0,0,0,0,0100h,0100h,0,0,g_sys_segment,,g_cobos,,g_stk_csh0,,g_tasklist,,0,,0,,0,,0>
tss_INT_C       TSS     <,,,,,,,,,,,0,x_int_nu,0,0,0,0,0,0100h,0100h,0,0,g_sys_segment,,g_cobos,,g_stk_csh0,,g_tasklist,,0,,0,,0,,0>
tss_EXCPT       TSS     <,,,,,,,,,,,0,offset exception,0,0,0,0,0,0100h,0100h,0,0,g_sys_segment,,g_cobos,,g_stk_excpt,,0,,0,,0,,0,,0>
tss_Timer       TSS     <,,,,,,,,,,,0,offset timer,0,0,0,0,0,0050h,0050h,0,0,g_sys_segment,,g_cobos,,g_stk_timer,,g_tasklist,,0,,g_timer_dta,,0,,0>
tss_User        TSS     <,,,,,,,,,,,0,offset user,0,0,0,0,0,0050h,0050h,0,0,g_sys_segment,,g_cobos,,g_stk_user,,g_tasklist,,0,,0,,0,,0>
tss_sermouse    TSS     <,,,,,,,,,,,0,offset smouse,0,0,0,0,0,0100h,0100h,0,0,g_sys_segment,,g_cobos,,g_stk_sermse,,g_tasklist,,0,,0,,0,,0>
	TSS_SPACE       ENDS
	
;----------------------------
;      DOS DATA
;----------------------------
; This segment holds the data
; that the DOS part (LOADER)
; will need.
;
	segment DATA_SPACE use16
data_seg        dw      0
stack_seg       dw      0
stack_pnt       dw      0
base_ptr        dw      0
e_flags	dd      0
save_idt        df      0
save_gdt        df      0
load_idt        df      0
load_gdt        df      0
	DATA_SPACE ENDS

	segment disk_segment public use16
	db	512 dup (00)
dsk_name        db	"COBOS   "
dsk_ext	db	"DSK"
max_sector	dd	0
disk_heads	db	0
disk_sector	db	0
	disk_segment ENDS

	segment astack use16 stack
	db	100h dup (00)
stck_0	db	100h dup (00)
stck_1	db	100h dup (00)
stck_2	db	100h dup (00)
crsh_0	db	100h dup (00)
excpt_0	db	100h dup (00)
timr_stk        db	50h dup (00)
user_stk        db	50h dup (00)
muse_stk        db	100h dup (00)
	astack ENDS
	END
