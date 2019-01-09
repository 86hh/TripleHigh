;TripleHigh by hh86
;It is a cross-platform Hello World for Windows/Linux/macOS
;Tested on Windows 10/Ubuntu/macOS High Sierra
;
;To compile this thing on Windows:
;yasm -f win32 triplehigh.obj triplehigh.asm
;link triplehigh.obj /entry:main /section:.text,erw /subsystem:console
;
;To compile this thing on Linux:
;yasm -f elf32 triplehigh.obj triplehigh.asm
;ld -e _main2 -o triplehigh triplehigh.obj
;
;To compile this thing on macOS:
;yasm -f macho32 triplehigh.obj triplehigh.asm
;ld -arch i386 -e _main2 -o triplehigh triplehigh.obj -lSystem

bits32
%include "triplehigh.inc"

global _main  ;for Windows only
global _main2 ;for Linux/macOS only
section .text
_main:
        call    set_seh
        pop     edx
        pop     eax
        push    edx
        mov     eax, dword [eax + ExceptionAddress]
        mov     eax, dword [eax]
        cmp     ax, 80cdh                    ;int 80h
        jne     leave_seh
        pushad
        mov     ebp, esp
        mov     ebx, dword [esp + 20h + ContextRecord - 4]
        add     ebx, 7fh
        mov     esi, dword [ebx + ContextEsp - 7fh]
        lodsd                                ;pop first dword
        mov     eax, 1986h

store_ssoff:                                 ;for patch use "reg - 4"
        movzx   ecx, al
        sub     esp, ecx
        mov     edi, esp
        rep     movsb
        mov     cl, ah

store_apistk:
        call    dword [ecx + 1986h]
        add     dword [ebx + ContextEip - 7fh], 2  ;skip int 80h
        mov     dword [ebx + ContextEax - 7fh], eax
        mov     esp, ebp
        popad
        xor     eax, eax
        ret

leave_seh:
        pop     eax
        pop     esp
        xor     eax, eax
        fs pop  dword [eax]
        pop     eax
        popad
        ret

set_seh:
        xor     eax, eax
        fs push dword [eax]
        fs mov  dword [eax], esp
        mov     eax, dword [ebx + pebLdr]
        mov     esi, dword [eax + ldrInLoadOrderModuleList]
        lodsd
        xchg    esi, eax
        lodsd
        mov     ebp, dword [eax + mlDllBase]
        call    parse_exports

;-----------------------------------------------------------------------------
;API CRC table, null terminated
;-----------------------------------------------------------------------------

        dd      03FC1BD8Dh                   ;LoadLibraryA
        db      0

;-----------------------------------------------------------------------------
;API CRC table, null terminated
;-----------------------------------------------------------------------------

        call    load_crtdll

msvcrt: 
        db      "msvcrt", 0, 0               ;null-terminator, and a dummy byte

crtcrcbegin:
        dd      0C92CF415h                   ;_exit
        dd      0F75396C3h                   ;_write
        db      0

copy_esp:
        lea     edi, dword [esi - (copy_esp - store_ssoff)]
                                             ;switch to edi because in Linux
                                             ;it is the last register to be used
                                             ;for params in calls, so fewer saves
        mov     dword [edi + (store_apistk - store_ssoff) + 2], esp
                                             ;store platform APIs
        jmp     skip_main2

        ;here begins the common entrypoint for Linux and macOS

_main2:
        mov     edi, esp
        push    eax
        push    eax

skip_main2:
        call    skip_msg
msg:
        db      "Hello World! (TripleHigh by hh86)", 0ah
len equ $-msg                                ;in true Hello World fashion :)

skip_msg:
        pop     ecx
        push    len
        pop     edx
        push    1                            ;stdout
        pop     ebx
        push    edx
        push    ecx
        push    ebx
        push    4                            ;sys_write
        pop     eax
        mov     word [edi - 4], (crtcrcstk.write << 8) + 0ch
        push    eax                          ;align needed for macOS 
                                             ;in Windows this needs to be adjusted
        int     80h
        
        ;you can clean up the stack here if you want, e.g add esp, 10h

        mov     eax, ebx                     ;sys_exit
        dec     ebx
        push    ebx
        mov     word [edi - 4], (crtcrcstk.exit << 8) + 4
        push    eax                          ;align needed for macOS 
                                             ;in Windows this needs to be adjusted
        int     80h                          ;once only imagined

;-----------------------------------------------------------------------------
;parse export table
;-----------------------------------------------------------------------------

load_crtdll:
        pop     esi
        push    esi
        call    dword [esp + 4 + kLoadLibraryA]
        xchg    ebp, eax
        lodsd
        lodsd
        push   esi

;-----------------------------------------------------------------------------
;parse export table
;-----------------------------------------------------------------------------

parse_exports:
        pop     esi
        mov     ebx, ebp
        mov     eax, dword [ebp + IMAGE_DOS_HEADER_lfanew]
        add     ebx, dword [ebp + eax + 78h] ;exp dir rva
        cdq

walk_names:
        mov     eax, ebp
        mov     edi, ebp
        inc     edx
        add     eax, dword [ebx + IMAGE_EXPORT_DIRECTORY.AddressOfNames]
        add     edi, dword [eax + edx * 4]
        or      eax, -1

crc_outer:
        xor     al, byte [edi]
        push    8
        pop     ecx

crc_inner:
        shr     eax, 1
        jnc     crc_skip
        xor     eax, 0edb88320h

crc_skip:
        loop    crc_inner
        inc     edi
        cmp     byte [edi], cl
        jne     crc_outer
        not     eax
        cmp     dword [esi], eax
        jne     walk_names
        mov     edi, ebp
        mov     eax, ebp
        add     edi, dword [ebx + IMAGE_EXPORT_DIRECTORY.AddressOfNameOrdinals]
        movzx   edi, word [edi + edx * 2]
        add     eax, dword [ebx + IMAGE_EXPORT_DIRECTORY.AddressOfFunctions]
        mov     eax, dword [eax + edi * 4]
        add     eax, ebp
        push    eax
        lodsd
        sub     cl, byte [esi]
        jnz     walk_names
        inc     esi
        jmp     esi