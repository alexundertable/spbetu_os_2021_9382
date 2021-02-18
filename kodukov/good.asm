.model small
.data
VERSION db "DOS version:  $"
MODNUM db 13, 10, "Modification number:  $"
SERIAL db 13, 10, "Serial number:       $" ; 16 symbols
OEM db 13, 10, "OEM:     $"; 6 sybmols

TYPEPCSTRING db 13, 10, "PC type: $"
TYPEPC db "PC$"
TYPEPCXT db "PC/XT$"
TYPEAT db "AT$"
TYPEPS2M30 db "PS2 (30 model)$"
TYPEPS2M5060 db "PS2 (50 or 60 model)$"
TYPEPS2M80 db "PS2 (80 model)$"
TYPEPCJR db "PC jr$"
TYPEPCCONV db "PC Convertible$"

.stack 100h

.code
;-------------------------------
WRITE PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP
;-------------------------------
DOSVER PROC near
	mov ah, 30h
	int 21h
	; al - version number
	; ah - modification number
	; bh - OEM serial number
	; bl:cx - user serial number
	push ax
	
	mov si, offset VERSION
	add si, 12
	call BYTE_TO_DEC
	mov dx, offset VERSION
	call WRITE
	
	mov si, offset MODNUM
	add si, 23
	pop ax
	mov al, ah
	call BYTE_TO_DEC
	mov dx, offset MODNUM
	call WRITE
	
	mov si, offset OEM
	add si, 9
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset OEM
	call WRITE
	
	mov di, offset SERIAL
	add di, 22
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset SERIAL
	call WRITE
	ret
DOSVER ENDP
;-------------------------------
PCTYPE PROC near
	mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]
	mov dx, offset TYPEPCSTRING
	call WRITE
	cmp al, 0ffh
	jz pc
	cmp al, 0feh
	jz pcxt
	cmp al, 0fbh
	jz pcxt
	cmp al, 0fch
	jz pcat
	cmp al, 0fah
	jz pcps2m30
	cmp al, 0f8h
	jz pcps2m80
	cmp al, 0fdh
	jz pcjr
	cmp al, 0f9h
	jz pcconv
	pc:
		mov dx, offset TYPEPC
		jmp writestring
	pcxt:
		mov dx, offset TYPEPCXT
		jmp writestring
	pcat:
		mov dx, offset TYPEAT
		jmp writestring
	pcps2m30:
		mov dx, offset TYPEPS2M30
		jmp writestring
	pcps2m5060:
		mov dx, offset TYPEPS2M5060
		jmp writestring
	pcps2m80:
		mov dx, offset TYPEPS2M80
		jmp writestring
	pcjr:
		mov dx, offset TYPEPCJR
		jmp writestring
	pcconv:
		mov dx, offset TYPEPCCONV
		jmp writestring
	writestring:
		call WRITE
	ret
PCTYPE ENDP
;-------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;-------------------------------
BYTE_TO_HEX   PROC  near
; ���� � AL ����������� � ��� ������� �����. ����� � AX
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX ;в AL старшая цифра
           pop      CX          ;в AH младшая
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
;������� � 16 �/� 16-�� ���������� �����
; � AX - �����, DI - ����� ���������� �������
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC   PROC  near
; ������� � 10�/�, SI - ����� ���� ������� �����
           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
           or       DL,30h
           mov      [SI],DL
	   dec      SI
           xor      DX,DX
           cmp      AX,10
           jae      loop_bd
           cmp      AL,00h
           je       end_l
           or       AL,30h
           mov      [SI],AL
		   
end_l:     pop      DX
           pop      CX
           ret
BYTE_TO_DEC    ENDP
;-------------------------------
; ���
BEGIN:
	   mov ax, @data
	   mov ds, ax
	   call DOSVER
	   call PCTYPE
	   mov ah, 10h
	   int 16h
           ; ����� � DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H
		   
END       BEGIN     ;����� ������
