
        mov al,13h                ;MCGA mode (320x200x256).
        int 10h                   ;Video interrupt request.

        push 0F000h
        pop gs
        
; { SET PALLETE

        mov dx,3C8h ; port for changing pallete
        mov ax,03908h ; ah = 63 - maximal value for a colour, al = 8

PALETA  out dx,al ; colour number 
        inc dx
        out dx,al ; r
        xchg al,ah
        out dx,al ; g
        xchg al,ah
        out dx,al ; b
        dec dx
        sub ah,08h
        dec al
        jnz PALETA
; }

; { FILL THE SCREEN 

        mov bl,1 ; - colour 
        
        xor dx,dx ; cursor - 0,0
        ;std
FILL lodsb ; load garbage from [ds:si] to ax and increase si
        cmp al,21h
        jb FILL ; take different char if that one is ugly 
        ;cmp al,0f4h
        ;ja FILL

        call PTCHAR
        
        inc dh ; row 
        cmp dh,25
        jb L1
        xor dh,dh
        
POSIT   lodsb
        cmp al,25
        ja POSIT
        push ax ; - position of the first char 
        
        inc dl ; column 
        
L1      mov ah,02h ; setcursor
        int 10h

        cmp dl,40
        jb FILL
        
; }


TICK    mov si,di

        mov dl,39
        mov di,sp

NEWCOL  mov al,[ss:di]
        
        mov dh,-1
        
LINE    inc dh
        cmp dh,al
        jne LINE

        mov bl,1
        call SET_READ_PUT

        inc dh
        cmp dh,25
        jb M1
        xor dh,dh

M1      mov [ss:di],dh

N1      inc bl
        call SET_READ_PUT

        inc dh
        cmp dh,25
        jb O1
        xor dh,dh

O1      cmp bl,8
        jb N1

        inc di
        inc di
        dec dl
        jns NEWCOL

; {

        mov dh,8

NXTROW  mov dl,39

R1      mov al,dl
        xor ah,ah
        mov bl,8
        div bl ; al = dl/8 - character ah = dl%8 - bit for comparition 
        mov cl,ah ; cl - bit for comparition 

        mov di,01FBh ; start of data
        xor ah,ah
        add di,ax ; data offset
        mov al,[cs:di] ; character from data 

        mov di,0FA6Eh ; start of BIOS font data

        shl ax,3 ; font offset (character * 8)
        add di,ax

        mov ch,dl
        xor dl,dl
        xchg dh,dl
        add di,dx ; next font offset (column)
        xchg dh,dl
        mov dl,ch

        sub di,8

        mov bl,[gs:di] ; a line from font 
        
        neg cl         ; cx1 = 7 - cx
        add cl,7
        xor ch,ch

        bt bx,cx
        jnc Q1

        mov bl,42 ; 9 - blue, 42 - orange 
        shr ax,3 ; reverse offset to a character 

        mov ah,02h ; setcursor
        int 10h

        call PTCHAR

Q1      dec dl
        jns R1

        inc dh
        cmp dh,16
        jb NXTROW

; }

MAIN     mov di,[fs:046ch]         ;Read a value from 0000046ch (the system
                                   ;clock, which ticks at 18.2 Hz) and use it
                                   ;as colour for the next pixel.

         cmp si,di
         jne TICK

         in ax,60h                 ;Read value from port 60h (keyboard) into
                                   ;al. This serves a double purpose, since
                                   ;it also adds a nice delay during which
                                   ;the clock can tick away and give me a
                                   ;different colour next time.

         dec ax                    ;See if the ESC key was pressed (BIOS scan
                                   ;code 1) by decreasing al and looking at
                                   ;the Zero Flag. So, demo or die? ;)

         jnz MAIN                 ;Not zero: demo.
		 mov al,3 ; mov ax,3
		 int 10h
		 int 20h                  ; not to upset DOS
         ;ret                     ;Zero: die.
         
         
SET_READ_PUT  mov ah,02h ; setcursor
              int 10h

              mov ah,08h ; readchar
              int 10h
              
              ;call PTCHAR
              ;ret

PTCHAR        mov cl,1 ; - 1 character only
              mov ah,09h ; putchar
              int 10h
              ret

db      'WECAN' ; 2012
