TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
; ������
MEM_ADRESS db 'Locked memory address:     h',13,10,'$'
ENV_ADRESS db 'Environment address:     h',13,10,'$'
TAIL db 'Command line tail:        ',13,10,'$'
NULL_TAIL db 'In Command tail no sybmols',13,10,'$'
CONTENT db 'Content:',13,10, '$'
END_STRING db 13, 10, '$'
PATH db 'Patch:  ',13,10,'$'

; ���������
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;���� � AL ����������� � ��� ������� ����. ����� � AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;� AL ������� �����
   pop CX ;� AH �������
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;������� � 16 �/� 16-�� ���������� �����
; � AX - �����, DI - ����� ���������� �������
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; ������� � 10�/�, SI - ����� ���� ������� �����
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP
;-------------------------------
WRITESTRING PROC near
   mov AH,09h
   int 21h
   ret
WRITESTRING ENDP
;-------------------------------

PSP_MEMORY PROC near
   ;MEMORY
   mov ax,ds:[02h]
   mov di, offset MEM_ADRESS
   add di, 26
   call WRD_TO_HEX
   mov dx, offset MEM_ADRESS
   call WRITESTRING
   ret
PSP_MEMORY ENDP

PSP_ENVIROMENT  PROC near 
   ;ENVIROMENT
   mov ax,ds:[2Ch]
   mov di, offset ENV_ADRESS
   add di, 24
   call WRD_TO_HEX
   mov dx, offset ENV_ADRESS
   call WRITESTRING
   ret
PSP_ENVIROMENT ENDP

PSP_TAIL PROC near   
   ;TAIL
   xor cx, cx
	mov cl, ds:[80h]
	mov si, offset TAIL
	add si, 19
   cmp cl, 0h
   je empty_tail
	xor di, di
	xor ax, ax
readtail: 
	mov al, ds:[81h+di]
   inc di
   mov [si], al
	inc si
	loop readtail
	mov dx, offset TAIL
	jmp end_tail
empty_tail:
		mov dx, offset NULL_TAIL
end_tail: 
   call WRITESTRING 
   ret
PSP_TAIL ENDP

PSP_CONTENT PROC near
   ;ENVIROMENT CONTENT
   mov dx, offset CONTENT
   call WRITESTRING
   xor di,di
   mov ds, ds:[2Ch]
read_string:
	cmp byte ptr [di], 00h
	jz end_str
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp find_end
end_str:
   cmp byte ptr [di+1],00h
   jz find_end
   push ds
   mov cx, cs
	mov ds, cx
	mov dx, offset END_STRING
	call WRITESTRING
	pop ds
find_end:
	inc di
	cmp word ptr [di], 0001h
	jz read_path
	jmp read_string
read_path:
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset PATH
	call WRITESTRING
	pop ds
	add di, 2
loop_path:
	cmp byte ptr [di], 00h
	jz complete
	mov dl, [di]
	mov ah, 02h
	int 21h
	inc di
	jmp loop_path
complete:
	ret
PSP_CONTENT ENDP

; ���
BEGIN:
   call PSP_MEMORY
   call PSP_ENVIROMENT
   call PSP_TAIL
   call PSP_CONTENT

   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START