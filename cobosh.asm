comment	#======================================================= 

		 COBOSH.ASM (header file)
                                                                         
	        Concurrent Object Based Operating System         
	         	         (COBOS)                         
	         	                                         
	           BEng (Hons) Software Engineering for          
	        	     Real Time Systems                   
	        	  3rd Year Project 1996/97               
	        	                                         
	        	     (c) 1996 P.Antoine                  
	                                                         
	#========================================================

;------------------------------
; file access locks

al_none	equ	0	; not being accessed
al_read	equ	1	; object opened for reading
al_write	equ	2	; object is being written
al_update	equ	3	; object is being updated
al_create	equ	4	; object being created
al_delete	equ	5	; onject is being deleted

;------------------------------
; object access types

oa_next	equ	0	; read next
oa_prev	equ	1	; read previous
oa_abso	equ	2	; read absolute position

;------------------------------
; System semaphore numbers

ss_task	equ	0
ss_malloc	equ	1
ss_device	equ	2
ss_IDT	equ	3
ss_GDT	equ	4
ss_Soft	equ	5
ss_Hard	equ	6
ss_Object	equ	7
ss_MDSIO	equ	8
ss_HOTS	equ	9
ss_Realm	equ	10

ss_exception	equ	13	; system has an outstanding exception
ss_screen	equ	14	; screen is being used bit (stop the mouse being written)
ss_system	equ	15	; system is set when a critical system function is running

;------------------------------
; hardware ports - standard

PIC_mast_a0	equ	20h	;PIC(8259A) I/O address master
PIC_mast_a1	equ	21h
PIC_slave_a0	equ	0a0h	;PIC I/O address slave
PIC_slave_a1	equ	0a1h

;------------------------------
; PMODE macros for MASM/TASM

fjmp16	macro	c_segment, j_offset	; 16 bit far jump
	db	0eah
	dw	j_offset
	dw	c_segment
endm

fjmp	macro	c_segment, j_offset	; 32 bit far jump
	db	0eah
	dd	j_offset
	dw	c_segment
endm


fcall	macro	c_segment, j_offset	; 32 bit far call
	db	09ah
	dd	j_offset
	dw	c_segment
endm

;-------------------------------
; 80386 descriptor formats
;	
SegDesc	STRUC
	LimitL	dw	?	; Low 16 Bit of segment limit
	BaseL	dw	?	; Low 16 Bit of segment base address
	BaseM	db	?	; Next 8 Bit of segment base address
	Rights	db	?	; Access rights 
	Gran	db	?	; Granuarity (16Mb or 4Gb), and others
	BaseH	db	?	; High 4 bits of base address
SegDesc	ENDS

GateDesc	STRUC
	OffsetL	dw	?	; low 16 bit of offset
	Select	dw	?	; selector (must be in gdt or ldt)
	Count	db	?	; should be zero for int,task,trap gates
	Rights	db	?	; access rights
	OffsetH	dw	?	; high 16 bit of offset
GateDesc	ENDS

PDT	RECORD	Present:1, DPL:2, Typ:5
GXOAL	RECORD	Granul:1, X:1, O:1, Avail:1, LimitM:4
	
;--------------------------
; DOS disk formats

partition	struc
part_prog	db	446 dup (00)	; partition checking programs
part_table_4	db	16 dup (00)	; partition table
part_table_3	db	16 dup (00)
part_table_2	db	16 dup (00)
part_table_1	db	16 dup (00)
part_signature	dw	0	; partition signature s/b aa55h
	partition ENDS
	
part_entry	struc
boot_flag	db	0	; boot flag
part_head	db	0	; start position - head
part_sect	db	0	;       ''       - sector
part_cyln	db	0	;       ''       - cylinder
sys_flag	db	0	; system flag
part_end	db	3 dup (00)	; end of partition
rel_start	dd	0	; relative start position
num_sectors	dd	0	; number of sectors in partition
	part_entry ENDS
	
boot_sector	struc
id	db	3 dup (00)
oem_name	db	8 dup (00)	; the name of the OS that created the disk
byte_per_sect	dw	0	; number of bytes in a sector
cluster_size	db	0	; number of sectors in a cluster
res_sectors	dw	0	; number of reserved sectors
num_fats	db	0	; number of copies of the fat
root_entries	dw	0	; number of entries in the root dir
logical_sec	dw	0	; logical sectors on the partition
medium_desc	db	0	; medium descriptor byte
fat_size	dw	0	; number of sectors in the FAT
sec_per_track	dw	0	; sectors per track
num_heads	dw	0	; heads on the drive
hidden	dw	0	; number of hidden sectors (???)
boot_code	db	0	; start of the boot code
	boot_sector ENDS	

directory	struc
f_name	db	8 dup (00)	; file name
f_ext	db	3 dup (00)	; extention name
f_attrib	db	0	; the atrribute byte
f_filler	db	10 dup (00)	; ** filler **
f_time	dw	0	; creation/update time
f_date	dw	0	; creation/update date
f_cluster	dw	0	; start cluster number
f_length	dd	0	; file length
	directory ENDS


;-----------------------------
; COBOS Disk formats

obj_data	equ	1	; MDSIO object type = data
obj_appl	equ	2	; MDSIO object type = application
obj_obj	equ	3	; MDSIO object type = object

object_pos	struc
op_device	dw	0	; device number
op_block	dd	0	; block that the device starts at
	object_pos	ENDS

realm_table	struc
rt_next_device	dw	0	; the device number for the next device block
rt_next_block	dd	0	; the starting block number
rt_name	db	32 dup (00)	; 32 bytes the realm name
rt_group	db	32 dup (00)	; 32 bytes the group that it belongs to
rt_date	dw	0	; creation date
rt_device	dw	0	; the device that the realm is on
rt_block	dd	0	; the block that the realm starts on
rt_permission	db	0	; permissions byte for the data 
	realm_table	ENDS

rt_size	equ	76	; size of the realm table entry (not encl. next block/device)
	
onode	struc		; object node
on_next_block	dd	0	; next block of the onode (all onode blocks are on the same device)
on_prev_block	dd	0	; previous block in the onode chain
on_permission	db	0	; permissions of the onode
on_group	db	32 dup (00)	; the name of the group that the file belongs to
on_owner	db	32 dup (00)	; the realm that created the file
on_amended	dw	0	; the date last amended
on_file_size	dd	0	; the file size in bytes
on_blocks_alloc	dd	0	; number of blocks allocated to the file
	onode	ENDS
	
on_head_size	equ	80	; the size of the header information (excl. on_next_block) m/b div by 4
on_last_entry	equ	(512/4)-1	; the last entry in the on_onode

realm_entry	struc
re_name	db	32 dup (00)	; the object name
re_date	dw	0	; creation date last updated	
re_type	dw	0	; size and type bits
re_data	object_pos	<0,0>	; where the objects data onode is
re_code	object_pos	<0,0>	; where the objects code onode is
re_inst	object_pos	<0,0>	; where the instance space onode is
	realm_entry	ENDS

re_size	equ	54	; size of the realm table entry

;----------------------------------------
; task request block - used by load task
;

TRB_stk_size	equ	0
TRB_srn_size	equ	2
TRB_dta_seg	equ	4	; data segment - both these will level amended by load_task
TRB_cde_seg	equ	6	; code segment
TRB_idx_size	equ	8
TRB_mes_size	equ	10
TRB_app_level	equ	12
TRB_status	equ	13
TRB_y_size	equ	14
TRB_x_size	equ	16
TRB_y_pos	equ	18
TRB_x_pos	equ	20

;--------------------------
; Task Control Block

TCB_size	equ	100

t_inuse	equ	0		; staus bit task inuse
t_suspended	equ	1		; task suspended
t_IO_wait	equ	3		; task waitting for IO
t_KB	equ	4		; allowed to recive keyboard input
t_mouse	equ	5		; allowed to recive mouse clicks
t_error	equ	6		; task has caused an error
t_exception	equ	7		; task caused an exception
t_system	equ	8		; task is a "system" task

	TCB	struc
Task_number	dw	0
Task_selector	dw	0
Last_Error	dd	0		; error code of the last error 
owner_realm	db	32 dup (00)		; name of the realm that the task belongs to
current_group	db	32 dup (00)		; the current group of the task
TCB_alloc	dw	0
Code_alloc	dw	0
Data_alloc	dw	0
TSS_alloc	dw	0
Stack_alloc	dw	0
lt_stack	dw	0		;level transition stack - used for all levels
Status	dw	0
mess_head	dw	0
mess_tail	dw	0
mess_start	dw	0
mess_end	dw	0
indx_head	db	0
indx_tail	db	0
indx_size	db	0
scrn_number	db	0
indx_start	dw	0
	TCB	ENDS
	
;--------------------------------
; block Request definition
;

blk_read	equ	1	; device command (read)
blk_write	equ	2	; device command (write)
	
	BRD	struc
brd_size	dd	0	; number of queue entries
brd_head	dd	0	; head of the queue
brd_tail	dd	0	; end of the queue - next to be actioned
brd_dev_number	db	0	; device number
brd_command	db	0	; the command to the device
brd_block_start	dd	0	; the starting block number of the request
brd_num_blocks	dw	0	; transfer size
brd_rqst_task	dw	0	; the task that requested the command
brd_buffer	dd	0	; offset of the data buffer
brd_buf_seg	dw	0	; segment of the data buffer
	BRD	ends

br_r_size	equ	16

;------------------------------------
; TSS description - 386/486 standard

	TSS	struc
back_link	dw	0	; calling task
not_used_1	dw	0
ESP0	dd	0	; stack pointer level 0
stack_0	dw	0	; stack segment 0
not_used_2	dw	0
ESP1	dd	0	; stack pointer 1
stack_1	dw	0	; stack segment 1
not_used_3	dw	0	
ESP2	dd	0	; stack pointer 2
stack_2	dw	0	; stack segment 2
not_used_4	dw	0
tsk_CR3	dd	0	; CR3 register
tsk_EIP	dd	0	; EIP of the task
tsk_EFLAGS	dd	0	; FLAGS
tsk_EAX	dd	0
tsk_ECX	dd	0
tsk_EDX	dd	0
tsk_EBX	dd	0
tsk_ESP	dd	0
tsk_EBP	dd	0
tsk_ESI	dd	0
tsk_EDI	dd	0
tsk_ES	dw	0
not_used_5	dw	0
tsk_CS	dw	0
not_used_6	dw	0
tsk_SS	dw	0
not_used_7	dw	0
tsk_DS	dw	0
not_used_8	dw	0
tsk_FS	dw	0
not_used_9	dw	0
tsk_GS	dw	0
not_used_a	dw	0
tsk_LDT	dw	0
not_used_b	dw	0
tsk_trap	dw	0	; bit 0 is the debug trap bit
	TSS	ENDS

;----------------------------
; COBOS main system data area
;
	SYS	struc
tick_count	dw	0	; timer tick count used internally
semaphores	dw	0	; space for the system seaphores 
real_screen	dw	0	; the screen location selector
task_list	dw	0	; selector for the task_list 
task_size	dw	0	; size of the task list
malloc_list	dw	0	; selector for the memory table 
malloc_size	dw	0	; size of the malloc list
device_list	dw	0	; selector - device_table
device_size	dw	0	; size of the dievice list 
IDT_table	dw	0	; selector to a data area that points to the IDT
IDT_size	dw	0	; size of the IDT table
GDT_table	dw	0	; ditto IDT 
GDT_size	dw	0	; size of the GDT table
soft_table	dw	0	; selector that points to the soft int table 
soft_size	dw	0	; soft interrupt table size
hard_table	dw	0	; selector to the hard int table
hard_size	dw	0	; size of the hard interrupt 
object_table	dw	0	; selector to the object table
object_size	dw	0	; size of the object table 
lobject_table	dw	0	; selector to the loaded object table 
lobject_size	dw	0	; size of the loaded object table
MDSIO_table	dw	0	; selector to the MDSIO table
MDSIO_size	dw	0	; size of the MDSIO table 
HOT_SPOT	dw	0	; selector - hot spot table
HOT_size	dw	0	; size of the hot spot table 
top_hs_entry	dw	0	; top hot spot table entry
current_task	dw	0	; hold the current task number
user_task	dw	0	; holds the task number where keyboard inputs go 
exception_num	dw	0	; holds the number of the last exception
exception_code	dd	0	; the exception code pushed for some exceptions
current_TCB	dw	0	; The TCB of the task that is currently running
post_box	dw	0	; The TCB of the post_box
mouse_x	dw	0	; mouse_x position
mouse_y	dw	0	; mouse_y position 
screen_x	dw	0	; max screen size (pixels - x) 
screen_y	dw	0	; ditto screen_x 
char_set	dw	0	; the basic charater set
exception_spc	dw	0	; data space for exception code
messages	dw	0	; system messages
mouse_sprite	db	0FCH,0FCH,0FCH,0FCH,0FCH	; 11111100  holds the mouse sprite data
	db	0FCH,0FCH,0FCH,0FCH,0FCH	; 11111100
	db	0F8H,0F8H,0F8H,0F8H,0F8H	; 11111000	
	db	0F8H,0F8H,0F8H,0F8H,0F8H	; 11111000
	db	0FCH,0FCH,0FCH,0FCH,0FCH	; 11111100
	db	0FEH,0FEH,0FEH,0FEH,0FEH	; 11111110
	db	0DFH,0DFH,0DFH,0DFH,0DFH	; 11011111
	db	00EH,00EH,00EH,00EH,00EH	; 00001110
	db	004H,004H,004H,004H,004H	; 00000100
	db	35 dup (00)
kb_post	dw	0	; keyboard post box segment
ms_post	dw	0	; mouse post box segment
screen_under	db	160 dup (00)	; holds the space under the mouse 
DOS_return	dd	0	; the offset (to be worked out at run-time)
DOS_seg	dw	0	; 16 bit code segment for dos
dubue_fill	dw	0	; just incase?
realm_device	dw	0	; the device that the realm table is on
realm_block	dd	0	; the block of the start of the realm table	
realm_buffer	dw	0	; the segment that holds the realm buffer
DOS_sector	db	0	; Drive C: sectors per track
DOS_Heads	db	0	;          the number of heads
DOS_max_sector	dd	0	;          max number of sctors
DOS_srt_sector	dd	0	;          the first sector of the dsk file
	SYS	ENDS

;----------------------------
; COBOS system tables
;

	TASK	struc	; the entry for the task_list 
back_link	dw	0
forward_link	dw	0
TCB_seg	dw	0
TSS_seg	dw	0
	TASK	ENDS
	
	MALLOC	struc	; malloc table entry 
m_size	dd	0
m_owner	dw	0
m_selector	dw	0
m_address	dd	0
	MALLOC	ENDS

d_active	equ	0	; the device active bit
d_FAT_use	equ	1	; the FAT is in use bit
d_size	equ	34	; the size of the device record

	DEVICE	struc	; The device table entry 
d_device_name	db	16 dup (00)
d_queue_seg	dw	0	; segment that holds the device queue 
d_handler	dw	0	; the task number of device handler 
d_status	dw	0	; holds the device specific flags
d_FAT	dd	0	; the sector of the devices FAT
d_FAT_buffer	dw	0	; segment for the FAT buffer
d_FAT_block	dd	0	; block number in the FAT buffer
d_FAT_size	dw	0	; the number of blocks the fat uses
	DEVICE	ENDS

	SOFT_INT	struc	; The software interrupts installed 
permission	dw	0
s_int_code	df	0
	SOFT_INT	ENDS

	HARD_INT	struc	; the Hardware interrupts 
h_int_code	df	0
	HARD_INT	ENDS

	OBJECT	struc	; the object table entries 
o_MDSIO_num	dw	0
o_connections	dw	0
o_block_num	dd	0
o_buffer	dw	0
o_service_code	dw	0
o_service_desc	dw	0
o_inst_size	dw	0
o_first_inst	dd	0
o_last_inst	dd	0
o_permis	db	0
	OBJECT	ENDS

	LOBJECT	struc	; The application - object connection 
lo_object_num	dw	0
lo_app_num	dw	0
lo_inst_num	dw	0
lo_inst_space	dw	0	; the data area for the instance 
	LOBJECT	ENDS

	MDSIO	struc	; the Mass Data structure record 
md_owner	dw	0
md_name	db	32 dup (00)
md_realm	db	32 dup (00)
md_group	db	32 dup (00)
md_MDSIO_pos	object_pos	<0,0>
md_access_lock	db	0
md_type	db	0
md_buffer	dw	0	; holds the object handle
md_alloc_num	dw	0	; holds the object handle number
	MDSIO	ENDS
	
md_size	equ	110	; the size of the MDSIO record
	
	MDSIO_HANDLE	struc	; the Mass Data Structure Handle structure
mdh_MDSIO_num	dw	0
mdh_device	dw	0
mdh_onode	dw	0	; the current onode in buffer (index from the first)
mdh_block	dw	0	; the index of the block in the buffer
mdh_owner	dw	0	; the owner
mdh_o_block	dd	0	; the block the is in the onode
mdh_access	db	2 dup (00)	; 1st byte is the access byte - the second is just a filler
mdh_buffer	dd	0	; the buffer for the onode
	MDSIO_HANDLE	ENDS

mdh_size	equ	528	; the size (incl. 512 bytes for the onode buffer)

	HOTSPOT	struc	; the screen hot spot table
hs_owner	dw	0	
hs_top_x	dw	0
hs_top_y	dw	0
hs_bot_x	dw	0
hs_bot_y	dw	0
hs_max_x	dw	0
hs_max_y	dw	0
hs_rel_x	dw	0
hs_rel_y	dw	0
hs_task	dw	0
hs_mess_len	dw	0
hs_message	dd	0	; offset of message
hs_mess_seg	dw	0	; segment of message
hs_graphic	dd	0	; offset of graphic
hs_grap_seg	dw	0	; segment of graphic
hs_status	dw	0	; status byte
hs_chain	dw	0	; what order the hots are in
	HOTSPOT	ENDS

hs_size	equ	38	; if the hotspot size is changed this MUST be changed

hs_screen	equ	0	; is this entry a screen
hs_active	equ	1	; is entry active
hs_user	equ	2	; does this entry make hs_task top
hs_mess	equ	3	; if active, 1 = send the message, 0 = send the mouse state
hs_move	equ	4	; 1 = object can be moved, 0 = is fixed
hs_expand	equ	5	; 1 = the size of the window can be changed
hs_redraw	equ	6	; 1 = the window can be redrawn
hs_clear	equ	7	; 1 = the window needs to be removed from the screen

	sc_chain	struc
sc_next	dw	0	; screen chain next entry
sc_prev	dw	0	; screen chain previous entry
sc_lower_y	dw	0	; lower bound of the y segment
sc_upper_y	dw	0	; the upper bound of the y segment
sc_x_chain	dw	0	; the first entry of the x chain
	sc_chain	ENDS
	
	sc_x_sec	struc
sc_x_start	dw	0	; start (in x) of the masked section
sc_x_end	dw	0	; end (in x) of the masked section
sc_x_next	dw	0	; the next x section
sc_x_prev	dw	0	; the previous section
	sc_x_sec	ENDS

;---------------------------------
; user shell parse index structure

	us_p_index	struc
us_idx_pos	dd	0	; next free index position
us_free_space	dd	0	; free space pointer into the data space
us_index_ent	dw	256 dup (00)	; the index pointers
us_data	db	0	; the start of the data space
	us_p_index	ENDS

;-----------------------------
; default post box structures

	pbkb	struc
pb_kb_index	dd	0	; just so its offset by the index
pb_kb_task	dw	0	; task number for the post message
pb_kb_bytes	db	0	; number of bytes in the message
pb_kb_mess	db	5 dup (0)	; the space for the messages
	pbkb	ENDS
	
	pbms_1	struc
pb_ms1_index	dd	0	; just so its offset by the index
pb_ms1_task	dw	0	; task number for the post message
pb_ms1_type	db	0	; type of post message
pb_ms1_mess	db	0	; start of message & the type byte
pb_ms1_button	dw	0	; buttons bit or message size 
pb_ms1_x_pos	dw	0	; x_position
pb_ms1_y_pos	dw	0	; y_position
	pbms_1	ENDS	
	
	pbms_2	struc
pb_ms2_index	dd	0	; just so its offset by the index
pb_ms2_task	dw	0	; task number for the post message
pb_ms2_type	db	0	; type of post message
pb_ms2_fill	db	0	; filler
pb_ms2_size	dw	0	; message size 
pb_ms2_seg	dw	0	; message segment
pb_ms2_offset	dd	0	; message offset
	pbms_2	ENDS	

;---------------------------
; user shell index 
	
	USC_IND	struc
usi_name	dw	0	; offset to the command name string
usi_command	dd	0	; the offset to the function for the command
	USC_IND	ENDS

;---------------------------
; exception space structure

	xc_spc	struc
xc_window	dw	0	; the window number of the exception
xc_win_seg	dw	0	; the segment of the exception window
xc_eax	dd	0	; save space for the reister eax
xc_ebx	dd	0
xc_ecx	dd	0
xc_edx	dd	0
xc_esi	dd	0
xc_edi	dd	0
xc_ebp	dd	0
xc_esp	dd	0
xc_eip	dd	0
xc_cs	dw	0
xc_ds	dw	0
xc_es	dw	0
xc_fs	dw	0
xc_gs	dw	0
xc_fatal	db	0	; this byte is SET if the exception is fatal
xc_message	db	08h	; size of hex dump space
xc_hex	db	8 dup (00)	; eight bytes message space for hex dumps
xc_tidy	db	0	; does the stack need tidying
	xc_spc	ENDS

;-------------------
; ERROR CODE format
;
error_code	RECORD system_part:3, severity:3, specifics:26

;-------------------
; Specifics
;
system_error	RECORD sfiller:1, sys_fail:4, sys_err:3,sys_type:2,sys_item:16
task_error	RECORD tfiller:2, task_part:4, task_err:4,task_item:16
device_error	RECORD dfiller:2, dev_error:8, dev_item:16		; dev_errors are device specific!!!
app_error	RECORD afiller:2, app_part:24

;---------------------
; Error code constants
;
; *system parts *
no_error	equ	000b
app_3	equ	010b
app_2	equ	011b
app_1	equ	100b
device_err	equ	101b
task_level	equ	110b
system_err	equ	111b

; * severity *
minior	equ 	100b
warning	equ	101b
failure	equ	110b
catastrophic	equ	111b

; * parts *
t_list	equ	0001b
m_list	equ	0010b
g_table	equ	0011b
d_table	equ	0100b
h_table	equ	0101b
o_table	equ	0110b
l_table	equ	0111b
md_table	equ	1000b

; * errors

e_ok	equ 	0
e_full	equ	1
e_currupt	equ	2
e_not_avail	equ	3
e_not_exist	equ	4
e_priv	equ	5
e_empty	equ	6
e_not_free	equ	7

; * task parts
tp_task	equ	1
tp_index	equ	2
tp_message	equ	3
tp_tcb	equ	4
tp_tss	equ	5
tp_data	equ	6

; * application errors

ape_realm_inuse	equ	1
ape_rlm_n_exist	equ	2
ape_object_inus	equ	3
ape_obj_n_exist	equ	4
ape_obj_perm	equ	5
ape_obj_n_prt	equ	6
ape_rlm_n_empty	equ	7
ape_n_own	equ	8
ape_obj_exist	equ	9
ape_range_err	equ	10
ape_cpl_err	equ	11
ape_acces_vio	equ	12
ape_parm_err	equ	13	; parameter error
ape_eof_error	equ	14
ape_bof_error	equ	15