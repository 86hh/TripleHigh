kLoadLibraryA                   equ     0

pebLdr                          equ     0ch

ldrInLoadOrderModuleList        equ     0ch

mlDllBase                       equ     18h

IMAGE_DOS_HEADER_lfanew         equ     3ch

ExceptionAddress                equ     0ch

ContextRecord                   equ     0ch

ContextEax                      equ     0b0h
ContextEip                      equ     0b8h
ContextEsp                      equ     0c4h

struc   crtcrcstk
        .write          :     resd    1
        .exit           :     resd    1
endstruc

struc   IMAGE_EXPORT_DIRECTORY
        .Characteristics      :     resd    1
        .TimeDateStamp        :     resd    1
        .MajorVersion         :     resw    1
        .MinorVersion         :     resw    1
        .pName                :     resd    1
        .Base                 :     resd    1
        .NumberOfFunctions    :     resd    1
        .NumberOfNames        :     resd    1
        .AddressOfFunctions   :     resd    1
        .AddressOfNames       :     resd    1
        .AddressOfNameOrdinals:     resd    1
endstruc