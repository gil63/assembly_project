IDEAL

MODEL small

STACK 100h

DATASEG

x_points dw 512 dup(0)
y_points dw 512 dup(0)
point_info dw 512 dup(0) ; first byte = color, second byte = mode (0 = doesn't exists, 1 = normal, 2 = highlighted, 3 = selected)
x_point dw 0
y_point dw 0
color db 15
line_resulution dw 1000
pressed_last_frame db 0
dot_sprite_size db 1
dot_hitbox_size dw 2
button_count db 2
mode db 2 ; 1 = move dots, 2 = create dots, 3 = select dots
highlighted_button db 2 ; 255 = none
button_images dw 32 dup(0)

CODESEG

proc clear_selected_points
    push cx

    mov cx, 256
    jmp next_point1

reset_point:
    mov ah, 1
    mov [point_info + bx], ax
    loop next_point1
    jmp finish3

next_point1:
    mov bx, cx
    dec bx
    add bx, bx
    mov ax, [point_info + bx]
    cmp ah, 3
    jz reset_point
    loop next_point1
    jmp finish3

finish3:
    pop cx
    ret
endp

proc clear_highlighted_point
    push cx

    mov cx, 256
    jmp next_point2

reset_point1:
    mov ah, 1
    mov [point_info + bx], ax
    jmp finish9

next_point2:
    mov bx, cx
    dec bx
    add bx, bx
    mov ax, [point_info + bx]
    cmp ah, 2
    jz reset_point1
    loop next_point2
    jmp finish9

finish9:
    pop cx
    ret
endp

proc draw_dot
    ; draws a dot at x_point, y_point
    push ax
    push bx
    push cx

    xor ch, ch
    mov cl, [dot_sprite_size]

    mov ax, [x_point]
    add ax, cx
    
    mov bx, [y_point]
    add bx, cx

    sub [x_point], cx
    sub [y_point], cx

go_right:
    call print_point

    inc [x_point]
    cmp [x_point], ax
    jg go_down
    jmp go_right

go_down:
    sub [x_point], cx
    sub [x_point], cx
    dec [x_point]
    inc [y_point]
    cmp [y_point], bx
    jg finish1
    jmp go_right

finish1:
    pop cx
    pop bx
    pop ax
    ret
endp

; proc draw_line ; change 4
;     ; requires selected_points
;     push ax
;     push bx
;     push cx
;     push dx
    
;     ; reset
;     mov cx, [line_resulution]

; draw_point:
;     ; calculate x
;     mov ax, cx
;     mul [selected_points_x]
;     div [line_resulution]

;     mov [x_point], ax

;     mov ax, [line_resulution]
;     sub ax, cx
;     mul [selected_points_x + 2]
;     div [line_resulution]

;     add [x_point], ax

;     ; calculate y
;     mov ax, cx
;     mul [selected_points_y]
;     div [line_resulution]

;     mov [y_point], ax

;     mov ax, [line_resulution]
;     sub ax, cx
;     mul [selected_points_y + 2]
;     div [line_resulution]

;     add [y_point], ax

;     ; print point
;     call print_point

;     ; go to next point
;     loop draw_point

;     pop dx
;     pop cx
;     pop bx
;     pop ax
; 	ret
; endp

proc exit_graphic_mode
    xor ah , ah
    mov al, 2
    int 10h
    ret
endp

proc clear_screen
    push ax

    mov ax, 13h
    int 10h

    pop ax
    ret
endp

proc show_mouse
	xor ax, ax
 	int 33h
	mov ax, 1h
	int 33h
	ret
endp

proc get_mouse_info
	; zf = 1 = pressed
	; x_point = X co-ordinate
	; y_point = y co-ordinate
    push ax
    push bx
    push cx
    push dx

	mov ax, 03h
	int 33h
	shr cx, 1
    mov [x_point], cx
    mov [y_point], dx
    sub [x_point], 1
    sub [y_point], 1
    not bx
    test bx, 1

    pop dx
    pop cx
    pop bx
    pop ax
	ret
endp

proc get_mouse_press_info
	; zf = 1 = pressed
	; x_point = X co-ordinate
	; y_point = y co-ordinate
    ; only call once per frame
    push ax
    push bx
    push cx
    push dx

	mov ax, 03h
    int 33h
    shr cx, 1
    mov [x_point], cx
    mov [y_point], dx
    sub [x_point], 1
    sub [y_point], 1

    and bl, 1
    mov al, [pressed_last_frame]
    mov [pressed_last_frame], bl
    not al
    and bl, al
    cmp bl, 1

    pop dx
    pop cx
    pop bx
    pop ax
	ret
endp

proc get_point_at_location ; might have a bug
    ; gets location in x_point, y_point
    ; zf = 1 = pressed a point
    ; returns in ax the index of the point if there is one
    push bx
    push cx
    push dx

    ; reset
    mov cx, 256
    jmp next_point

next_point:
    ; check if pressing the point
    mov bx, cx
    dec bx
    add bx, bx
    
    mov ax, [point_info + bx]
    cmp ah, 0
    jz loop_next

    ; calculate distance to point
    mov ax, [x_point]
    add ax, [y_point]
    mov dx, [x_points + bx]
    add dx, [y_points + bx]
    sub ax, dx

    ; compare distance to hitbox
    cmp [dot_hitbox_size], ax
    ja found_point
    neg ax
    cmp [dot_hitbox_size], ax
    ja found_point

    ; repeat if too far
    jmp loop_next

loop_next:
    loop next_point
    call toggle_zf_off
    jmp not_found_point

found_point:
    mov ax, cx
    dec ax
    call toggle_zf_on
    
    pop dx
    pop cx
    pop bx
    ret


not_found_point:
    call toggle_zf_off

    pop dx
    pop cx
    pop bx
    ret
endp

proc toggle_zf
    push ax

    jz toggle_off
    jmp toggle_on

toggle_on:
    call toggle_zf_on
    jmp finish7

toggle_off:
    call toggle_zf_off
    jmp finish7

finish7:
    pop ax
    ret
endp

proc toggle_zf_on
    push ax

    cmp ax, ax

    pop ax
    ret
endp

proc toggle_zf_off
    push ax

    mov ax, 1
    cmp ax, 0

    pop ax
    ret
endp

proc print_point
	; x = x_point
    ; y = y_point
    ; color = color
    push ax
    push bx
    push cx
    push dx

    xor bh, bh 
    mov cx, [x_point]
    mov dx, [y_point]
    mov al, [color] 
    mov ah, 0ch 
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp

proc update_buttons
    ; gets location in x_point, y_point
    ; gets mouse press info in zf (1 = pressed)
    ; zf = 1 = on buttons
    push ax
    push [x_point]
    push [y_point]

    jz change_both
    jmp change_highlighted

change_both:
    mov [highlighted_button], 255
    cmp [y_point], 16
    jg not_pressed

    shr [x_point], 4
    mov al, [button_count]
    xor ah, ah
    cmp [x_point], ax
    jge not_pressed

    sub ax, [x_point]
    mov [highlighted_button], al
    mov [mode], al
    jmp pressed

change_highlighted:
    mov [highlighted_button], 255
    cmp [y_point], 16
    jg not_pressed

    shr [x_point], 4
    mov al, [button_count]
    xor ah, ah
    cmp [x_point], ax
    jge not_pressed
    
    sub ax, [x_point]
    mov [highlighted_button], al
    jmp pressed

pressed:
    call toggle_zf_on
    jmp finish5

not_pressed:
    call toggle_zf_off
    jmp finish5

finish5:
    pop [y_point]
    pop [x_point]
    pop ax
    ret
endp

proc update_points ; fix
    ; gets location in x_point, y_point
    ; gets mouse press info in zf (1 = pressed)
    push ax
    push bx

    pushf
    call get_point_at_location
    jnz reset_points
    popf
    jz pressed_point
    jmp above_point

pressed_point:
    mov bx, ax
    add bx, ax
    mov ax, [point_info + bx]
    mov ah, 3
    mov [point_info + bx], ax
    call clear_highlighted_point
    jmp finish6

above_point:
    pushf
    call clear_highlighted_point
    popf
    mov bx, ax
    add bx, ax
    mov ax, [point_info + bx]
    mov ah, 2
    mov [point_info + bx], ax
    jmp finish6

reset_points:
    popf
    call clear_selected_points
    call clear_highlighted_point
    jmp finish6

finish6:
    pop bx
    pop ax
    ret
endp

proc save_point
    ; creates at (x_point, y_point)
    ; gets color in [color]
    push ax
    push bx
    push cx

    ; reset
    mov cx, 256
    jmp find_space

    ; find empty space in list
find_space:
    mov bx, cx
    dec bx
    add bx, bx

    ; check if empty
    mov ax, [point_info + bx]
    cmp ah, 0
    jnz next1

    ; replace info
    mov al, [color]
    mov ah, 1
    mov [point_info + bx], ax

    ; replace x
    mov ax, [x_point]
    mov [x_points + bx], ax

    ; replace y
    mov ax, [y_point]
    mov [y_points + bx], ax

    jmp finish8

next1:
    loop find_space

finish8:
    pop cx
    pop bx
    pop ax
    ret
endp

proc draw_saved_points
    push ax
    push bx
    push cx

    ; start
    mov cx, 256
    jmp find_next

find_next:
    ; check if exists
    mov bx, cx
    dec bx
    add bx, bx

    mov ax, [point_info + bx]
    cmp ah, 1
    jz draw_normal1
    cmp ah, 2
    jz draw_highlighted1
    cmp ah, 3
    jz draw_selected1
    
    loop find_next
    jmp finish

draw_normal1:
    mov [color], al
    mov ax, [x_points + bx]
    mov [x_point], ax
    mov ax, [y_points + bx]
    mov [y_point], ax
    call draw_dot

    loop find_next
    jmp finish

draw_selected1:
    mov ax, [x_points + bx]
    mov [x_point], ax
    mov ax, [y_points + bx]
    mov [y_point], ax
    mov [color], 12
    call draw_dot

    loop find_next
    jmp finish

draw_highlighted1:
    mov ax, [x_points + bx]
    mov [x_point], ax
    mov ax, [y_points + bx]
    mov [y_point], ax
    mov [color], 11
    call draw_dot

    loop find_next
    jmp finish

finish:
    pop cx
    pop bx
    pop ax
    ret
endp

proc draw_16x16_image
    ; gets pointer to start in ax
    ; gets top left point in x_point, y_point
    push ax
    push bx
    push cx

    mov bx, ax
    sub bx, 2
    mov ax, 8000h
    add [x_point], 17
    dec [y_point]
    mov cx, 17
    loop go_down3

go_down3:
    add bx, 2
    sub [x_point], 16
    inc [y_point]

    push cx

    mov cx, 17
    loop go_right3

print:
    call print_point

    jmp next

go_right3:
    test [bx], al
    jnz print

    test [bx + 1], ah
    jnz print

next:
    ror ax, 1
    inc [x_point]

    loop go_right3

    pop cx
    loop go_down3

    pop cx
    pop bx
    pop ax
    ret
endp

proc draw_buttons
    push ax
    push cx
    mov al, [color]
    push ax
    push [x_point]
    push [y_point]

    mov [x_point], 0
    mov [y_point], 0
    mov ax, offset button_images
    mov cl, [button_count]
    jmp draw_next1

draw_next1:
    cmp cl, [mode]
    jz draw_selected

    cmp cl, [highlighted_button]
    jz draw_highlighted

    jmp draw_normal

draw_normal:
    mov [color], 15
    call draw_16x16_image
    add ax, 32
    mov [y_point], 0
    loop draw_next1
    jmp finish4

draw_selected:
    mov [color], 12
    call draw_16x16_image
    add ax, 32
    mov [y_point], 0
    loop draw_next1
    jmp finish4

draw_highlighted:
    mov [color], 11
    call draw_16x16_image
    add ax, 32
    mov [y_point], 0
    loop draw_next1
    jmp finish4

finish4:
    pop [y_point]
    pop [x_point]
    pop ax
    mov [color], al
    pop cx
    pop ax
    ret
endp

proc change_background
    push cx
    
    mov [y_point], 0

    mov cx, 200
    loop go_down1

go_right1:
    call print_point
    inc [x_point]
    loop go_right1
    pop cx
    loop go_down1
    jmp finish2

go_down1:
    mov [x_point], 0
    inc [y_point]
    push cx
    mov cx, 320
    loop go_right1

finish2:
    pop cx
    ret
endp

start:
	mov ax, @data
	mov ds, ax
    
	call clear_screen
	call show_mouse

    mov [button_images],      0000000000000000b
    mov [button_images + 2],  0001111111111000b
    mov [button_images + 4],  0010000000000100b
    mov [button_images + 6],  0100000000000010b
    mov [button_images + 8],  0100110000000010b
    mov [button_images + 10], 0100111100000010b
    mov [button_images + 12], 0100011100000010b
    mov [button_images + 14], 0100011110000010b
    mov [button_images + 16], 0100000111000010b
    mov [button_images + 18], 0100000011100010b
    mov [button_images + 20], 0100000001100010b
    mov [button_images + 22], 0100000000010010b
    mov [button_images + 24], 0100000000000010b
    mov [button_images + 26], 0010000000000100b
    mov [button_images + 28], 0001111111111000b
    mov [button_images + 30], 0000000000000000b

    mov [button_images + 32], 0000000000000000b
    mov [button_images + 34], 0001111111111000b
    mov [button_images + 36], 0010000000000100b
    mov [button_images + 38], 0100000110000010b
    mov [button_images + 40], 0100001111000010b
    mov [button_images + 42], 0100000110000010b
    mov [button_images + 44], 0100100110010010b
    mov [button_images + 46], 0101111111111010b
    mov [button_images + 48], 0101111111111010b
    mov [button_images + 50], 0100100110010010b
    mov [button_images + 52], 0100000110000010b
    mov [button_images + 54], 0100001111000010b
    mov [button_images + 56], 0100000110000010b
    mov [button_images + 58], 0010000000000100b
    mov [button_images + 60], 0001111111111000b
    mov [button_images + 62], 0000000000000000b

    jmp mode2

    mov [x_point], 50
    mov [y_point], 100
    call save_point

    mov al, [color]
    mov ah, 2
    mov [point_info + 510], ax

    mov [x_point], 15
    mov [y_point], 30
    call save_point

    mov [x_point], 123
    mov [y_point], 35
    call save_point
    
    mov al, [color]
    mov ah, 3
    mov [point_info + 506], ax
    
    mov [x_point], 46
    mov [y_point], 152
    call save_point
    
    mov al, [color]
    mov ah, 3
    mov [point_info + 504], ax

    mov [x_point], 78
    mov [y_point], 24
    call save_point
    
    mov [x_point], 14
    mov [y_point], 98
    call save_point

    call draw_saved_points

    jmp exit_loop
    
switch_mode:
    call draw_buttons
    popf
    cmp [mode], 1
    ; jz mode1

    cmp [mode], 2
    jz mode2

mode1:
    ; get mouse data
    call get_mouse_press_info

    ; swich modes
    pushf
    call update_buttons
    jz switch_mode
    call draw_buttons
    popf

    call update_points
    call draw_saved_points
    jmp mode1

mode2:
    ; get mouse data
    call get_mouse_press_info

    ; swich modes
    pushf
    call update_buttons
    jz switch_mode
    call draw_buttons
    popf

    ; continue
    jnz mode2
    mov [color], 15
    call save_point
    call draw_saved_points
    jmp mode2

exit_loop:
    jmp exit_loop

exit:
	call exit_graphic_mode
	mov ax, 4c00h
	int 21h
END start
