;**************************************************************************
; sbm 2019. estructura básica de un programa en ensamblador
;
; pareja 14
;**************************************************************************
; definicion del segmento de datos
datos segment
orden		equ 3
numdatos	equ 9
left_offset	equ 7
cell_size	equ 4
instructions	db "================================= INSTRUCTIONS =================================", 10, 13
		db "", 10, 13
		db 9, "- YOU MUST INPUT 9 NUMBERS IN TOTAL FOR THE WHOLE MATRIX", 10, 13
		db 9, "- EACH NUMBER MUST BE BETWEEN -16 AND 15, BOTH INCLUDED", 10, 13
		db 9, "- EACH NUMBER MUST FOLLOW THE SYNTAX", 10, 13
		db 9, "- ZERO CAN ONLY BE POSITIVE", 10, 13
		db "", 10, 13
		db "==================================== SYNTAX ===================================", 10, 13
		db "", 10, 13
		db "YOU MUST ENTER 3 CHARACTERS AFTER THE > IS DISPLAYED", 10, 13
		db 9, "CHAR 1 - MUST BE EITHER + OR -", 10, 13
		db 9, "CHAR 2 - MUST BE A NUMBER BETWEEN 0 AND 9, BOTH INCLUDED", 10, 13
		db 9, "CHAR 3 - MUST BE A NUMBER BETWEEN 0 AND 9, BOTH INCLUDED", 10, 13
		db "", 10, 13
		db "================================================================================", 10, 13, '$'
choice	db "=================================== PICK ONE ===================================", 10, 13
		db 9, "INPUT 1 FOR PRELOADED MATRIX", 10, 13
		db 9, "INPUT 2 FOR PICKING YOUR OWN", 10, 13
		db "================================================================================", 10, 13, '$'

resultlow	dw 0
resulthigh	dw 0
error_string	db 10, "Error, YOU did something wrong!", 10, 13, '$'
error_choice	db 10, "Error, that's not a choice", 10, 13, '$'
matrixguard	db 1,2,15,-2,7,-11,0,-2,-16
top		db "      |   |   |   |", 10, 13, '$'
mid		db "|a| = |   |   |   | = ", '$'
bot		db "      |   |   |   |", 10, 13, '$'
dis_number	db 0
tmp_input	db 4, "000"
datos ends

;**************************************************************************
; definicion del segmento de pila
pila segment stack "stack"
pila ends

;**************************************************************************
; definicion del segmento extra
extra segment
result dw 0,0 ;ejemplo de inicialización. 2 palabras (4 bytes)
extra ends

;**************************************************************************
; definicion del segmento de codigo
code segment
assume cs: code, ds: datos, es: extra, ss: pila
; comienzo del procedimiento principal
inicio proc
; inicializa los registros de segmento con su valor
mov ax, datos
mov ds, ax
mov ax, pila
mov ss, ax
mov ax, extra
mov es, ax
mov sp, 64 ; carga el puntero de pila con el valor mas alto
; fin de las inicializaciones

;**************************************************************************
; comienzo del programa

main:
; takes nothing
; returns nothing
; main is a fair function

	call clear_screen
	call make_a_choice

	call clear_screen
	call multiply

	call clear_screen
	call print_matrix

	jmp end_end

make_a_choice:
; takes nothing
; returns either modifies preloaded matrix or nothing

	call print_choice

	mov ah, 1h	; get key
	int 21h

	cmp al, 31h			; key is 1
	je preloaded	
	cmp al, 32h			; key is 2
	je user_input
	call print_error	; key is something other than 1 or 2
	
	user_input:
		call clear_screen			;load the matrix with custom values
		call print_instructions
		call save_user_input
	preloaded:
		ret

save_user_input:
; takes nine numbers from user and saves them to matrixguard
; returns nothing, because it returns what you deserve

	; [bp - 4] is iterator (i) for numbers
	push bp
	mov bp, sp
	sub sp, 4

	xor ax, ax ; set (i) to zero
	mov [bp - 4], ax
	next_number:
		call num_input
		mov si, [bp - 4] ; load (i)
		xor bx, bx ; required by law to use bx and si for matrix
		mov matrixguard[bx][si], al ; save number to matrix

		add si, 1
		mov [bp - 4], si
		cmp si, 9 ; if finished, return
		jne next_number

	mov sp, bp
	pop bp
	ret

num_input:
; takes three keys from user checking for the sign value
; returns the number in ax

	push bp
	mov bp, sp

	call beautiful_input

	mov ah, 1h ; get first key (sign)
	int 21h

	cmp al, 2dh ; check if its a minus
	je negative_input
	cmp al, 2bh ; check if its a plus
	je positive_input
	jmp print_error ; if its neither, blame the user and exit

	negative_input:
		call get_two_digits
		cmp ax, 0 ; check if its negative zero
		jne not_negative_zero
		jmp print_error

		not_negative_zero:
		cmp ax, 16 ; check if its less than 16
		jle correct_neg
		jmp print_error

		correct_neg:
		neg ax
		jmp num_input_end

	positive_input:
		call get_two_digits
		cmp ax, 15 ; check if its less than 15
		jle num_input_end
		jmp print_error

	num_input_end:
	mov sp, bp
	pop bp
	ret

print_matrix:
; takes the values of matrixguard and prints them in a matrix
; returns nothing

; [bp - 4] is iterator (i) for lines
; [bp - 8] is iterator (j) for columns
push bp
mov bp, sp
sub sp, 8

xor ax, ax ; vertical iterator (i)
mov [bp - 4], ax
load_matrix:
	xor ax, ax ; horizontal iterator (j)
	mov [bp - 8], ax
	load_line:
		; load next number into ax (j + i * 3)
		mov ax, [bp - 4] ; load i
		mov cx, 3
		mul cx ; j * 3
		mov bx, ax ; for use in indexing
		mov si, [bp - 8] ; load j
		mov ah, 0
		mov al, matrixguard[bx][si] ; num to ax

		call num_to_negative

		push cx ; save sign
		push ax ; save fist digit
		push bx ; save second digit

		mov al, [bp - 8] ; calculate offset with i * cell_size
		mov cx, cell_size
		mul cx
		mov si, ax
		add si, left_offset ; add the space on the left

		pop bx ; recover second digit
		pop ax ; recover fist digit
		pop dx ; recover sign

		add ax, 48 ; turn it into ASCII
		add bx, 48

		mov cx, [bp - 4] ; check i for the line to print
		cmp cx, 1
		je mid_line
		jg bot_line

		top_line: ; if i < 1
			mov top[si], dl
			mov top[si + 1], al
			mov top[si + 2], bl

			jmp cont_line

		mid_line: ; if i == 1
			mov mid[si], dl
			mov mid[si + 1], al
			mov mid[si + 2], bl

			jmp cont_line

		bot_line: ; if i > 1
			mov bot[si], dl
			mov bot[si + 1], al
			mov bot[si + 2], bl

			jmp cont_line

		cont_line:
		mov ax, [bp - 8]  ; horizontal check (j)
		inc ax
		mov [bp - 8], ax
		cmp ax, orden ; if j == 3 then break
		je line_end
		jmp load_line

	line_end:
	mov ax, [bp - 4] ; vertical check (i)
	inc ax
	mov [bp - 4], ax
	cmp ax, orden ; if i == 3 then break
	je load_end
	jmp load_matrix

; print matrix and finish
load_end:
call print_lines
mov sp, bp
pop bp
ret

print_result:
; takes the value saved in resultlow, checks for negative and prints it to matrixguard
; returns nothing
	mov ax, resultlow
	test ax, ax ; check for the signed bit
	jns is_positive
	neg ax

	mov dl, 45 ; print -
	mov ah, 2
	int 21h

	mov ax, resultlow ; get arguments ready
	neg ax

	is_positive:
	call print_16bit_number ; print the number

	mov dl, 10 ; print \n
	mov ah, 2
	int 21h

	mov dl, 13 ; print \r
	mov ah, 2
	int 21h

	ret

print_lines:
; takes values saved in matrixguard and prints them
; returns nothing
	mov dx, offset top
	mov ah, 9h
	int 21h

	mov dx, offset mid
	mov ah, 9h
	int 21h

	call print_result

	mov dx, offset bot
	mov ah, 9h
	int 21h

	ret

num_dis:
; takes a number from ax to disassemble it
; returns ax and bx with first and second number
	mov dx, 0 ; first num
	mov ah, 0
	mov al, dis_number
	mov cx, 10
	div cx
	push ax ; save

	mul cx ; second num
	mov cx, ax
	mov ah, 0
	mov al, dis_number
	sub ax, cx
	push ax ; save

	pop bx
	pop ax

	ret

num_to_negative:
; takes a number in ax and turns it negative if needed
; returns ax, bx with first and second num and cx with negative or space
	cmp ax, 16 ; if its bigger than 16 goto negative
	jge negative
	positive:
		mov dis_number, al ; load whole number into ax
		call num_dis ; disassemble number into ax, bx
		mov ch, 0
		mov cl, 20h ; load space into cx
		ret
	negative:
		neg ax
		mov dis_number, al ; load whole number into ax
		call num_dis ; disassemble number into ax, bx
		mov ch, 0
		mov cl, 2dh ; load minus into cx
		ret

get_two_digits:
; takes no arguments
; returns a number in ax
	mov ah, 1h ; get second key (first digit)
	int 21h
	mov ah, 0
	call check_if_number
	sub ax, 48 ; turns first ASCII to number
	mov cx, 10
	mul cx ; multiply first digit by 10
	push ax ; save it

	mov ah, 1h ; get third key (second digit)
	int 21h
	mov ah, 0
	call check_if_number
	sub ax, 48 ; turns second ASCII to number
	pop bx ; get fist digit
	add bx, ax ; add first digit * 10 plus second digit

	mov ax, bx ; save number to ax and return

	ret

check_if_number:
; takes a character in ASCII from ax and checks if its a number
; returns if its a number and exits if its not a number
	cmp ax, 30h
	jge over_zero
	jmp print_error

	over_zero:
		cmp ax, 39h
		jle under_nine
		jmp print_error

	under_nine:
		ret

print_error:
; takes no arguments and prints error before exiting
; returns no arguments
	call clear_screen
	mov dx, offset error_string
	mov ah, 9h
	int 21h
	jmp end_end

beautiful_input:
; takes nothing
; returns beautiful things through your screen

	mov dl, 10 ; print \n
	mov ah, 2
	int 21h

	mov dl, 13 ; print \r
	mov ah, 2
	int 21h

	mov dl, 62 ; print ">"
	mov ah, 2
	int 21h

	mov dl, 32 ; print " "
	mov ah, 2
	int 21h

	ret

clear_screen:
	xor cx, cx
	nu_line:
		mov dl, 10 ; print 'n
		mov ah, 2
		int 21h
		inc cx
		cmp cx, 40
		jle nu_line

	mov dl, 13 ; print \r
	mov ah, 2
	int 21h

	ret

multiply:
; Takes matrixguard data and multiplies them
; returns resulthigh and resultlow

	xor ax, ax  ;First set of multiplications 11*22*33
	mov al, matrixguard[0]
	imul matrixguard[4]
	xor cx, cx
	mov ch, matrixguard[8]
	mov cl, 8
	sar cx, cl  ;Extend with sign
	imul cx
	add resultlow, ax ;positive
	adc resulthigh, dx ;add with carry

	xor ax, ax  ;13*22*31
	mov al, matrixguard[6]
	imul matrixguard[4]
	xor cx, cx
	mov ch, matrixguard[2]
	mov cl, 8
	sar cx, cl
	imul cx
	sub resultlow, ax ;negative
	sbb resulthigh, dx  ;sub with carry

	xor ax, ax  ;12*23*31
	mov al, matrixguard[1]
	imul matrixguard[5]
	xor cx, cx
	mov ch, matrixguard[6]
	mov cl, 8
	sar cx, cl
	imul cx
	add resultlow, ax
	adc resulthigh, dx

	xor ax, ax  ;12*21*33
	mov al, matrixguard[8]
	imul matrixguard[3]
	xor cx, cx
	mov ch, matrixguard[1]
	mov cl, 8
	sar cx, cl
	imul cx
	sub resultlow, ax
	sbb resulthigh, dx

	xor ax, ax  ;13*21*32
	mov al, matrixguard[2]
	imul matrixguard[3]
	xor cx, cx
	mov ch, matrixguard[7]
	mov cl, 8
	sar cx, cl
	imul cx
	add resultlow, ax
	adc resulthigh, dx

	xor ax, ax  ;11*23*32
	mov al, matrixguard[7]
	imul matrixguard[5]
	xor cx, cx
	mov ch, matrixguard[0]
	mov cl, 8
	sar cx, cl
	imul cx
	sub resultlow, ax
	sbb resulthigh, dx

	ret

print_16bit_number:
; takes a number of 16 bits in ax
; returns the number on the screen
	xor cx, cx
	get_remainders:
		xor dx, dx
		mov bx, 10
		div bx ; divide the given number by 10

		push dx ; keep pushing remainders

		inc cx
		cmp ax, 0 ; check if we are done
		jnz get_remainders

	print_remainders:
		pop dx ; pop remainders in reverse order

		add dl, 48 ; convert to ascii
		mov ah, 02h
		int 21h ; print it

		dec cx
		cmp cx, 0
		jnz print_remainders
	ret

print_instructions:
; takes the hardcoded instructions from the datasegment and prints them in order
; returns nothing

	mov dx, offset instructions
	mov ah, 9h
	int 21h

	ret

print_choice:
; takes the instructions for making a choice and prints them
; returns nothing

	mov dx, offset choice
	mov ah, 9h
	int 21h

	ret

end_end:
	mov ax, 4c00h
	int 21h

; fin del programa
;**************************************************************************

inicio endp
; fin del segmento de codigo
code ends
; fin del programa indicando donde comienza la ejecucion
end inicio
