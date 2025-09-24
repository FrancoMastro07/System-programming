; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - Arquitectura y Organizacion de Computadoras - FCEN
; ==============================================================================

%include "print.mac"

global start


; Agreguen declaraciones extern según vayan necesitando
extern GDT_DESC
extern IDT_DESC
extern idt_init
extern screen_draw_layout
extern mmu_init_kernel_dir
extern copy_page
extern mmu_init_task_dir
extern tss_init
extern sched_init
extern tasks_screen_draw
extern tasks_init
extern GDT_IDX_TASK_INITIAL
extern pic_reset
extern pic_enable

; Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL 0x8
%define DS_RING_0_SEL 0x18   
%define C_FG_GREEN 0x2
%define C_FG_BLUE 0x1

%define LTR_INITIAL (11 << 3)
%define TASK_IDLE (12 << 3)

%define DIVISOR 0x500

BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; Deshabilitar interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; Imprimir mensaje de bienvenida - MODO REAL
    ; (revisar las funciones definidas en print.mac y los mensajes se encuentran en la
    ; sección de datos)
    print_text_rm start_rm_msg, start_rm_len, C_FG_GREEN, 0, 0

    ; Habilitar A20
    ; (revisar las funciones definidas en a20.asm)
    call A20_check
    call A20_enable

    ; Cargar la GDT
    lgdt [GDT_DESC]

    ; Setear el bit PE del registro CR0
    mov edi, cr0
    or edi, 1
    mov cr0, edi

    ; Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    jmp CS_RING_0_SEL:modo_protegido

BITS 32
modo_protegido:
    ; A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo
    mov ax, DS_RING_0_SEL
    mov DS, ax
    mov ES, ax
    mov GS, ax
    mov FS, ax
    mov SS, ax

    ; Establecer el tope y la base de la pila
    mov esp, 0x25000
    mov ebp, 0x25000

    ; Imprimir mensaje de bienvenida - MODO PROTEGIDO
    print_text_pm start_pm_msg, start_pm_len, C_FG_BLUE, 10, 0

    ; Inicializar pantalla
    call screen_draw_layout
    
   
    ; Inicializar el directorio de paginas
    call mmu_init_kernel_dir

    ; Cargar directorio de paginas
    mov edi, cr3
    or eax, edi
    mov cr3, eax

    ; Habilitar paginacion
    mov edi, cr0
    mov eax, 0x80000000
    or edi, eax
    mov cr0, edi

    ; INICIAMOS TAREAS
    call tss_init
    call sched_init
    call tasks_init

    ; CONFIGURAMOS EL PIT
    mov ax, DIVISOR
    out 0x40, al
    rol ax, 8
    out 0x40, al

    ; Inicializar y cargar la IDT
    call idt_init
    lidt [IDT_DESC]

    ; Reiniciar y habilitar el controlador de interrupciones
    call pic_reset
    call pic_enable

    ; Habilitar interrupciones
    ; sti   
    ; NOTA: Pueden chequear que las interrupciones funcionen forzando a que se
    ;       dispare alguna excepción (lo más sencillo es usar la instrucción
    ;       `int3`)
    ;POBAMOS INTERRUPCIONES 88 Y 98
    ; int 88
    ; int 98

    ; PROBAR COPY
    ; mov edi, 0x1000
    ; mov esi, 0x7000
    ; push edi
    ; push esi
    ; call copy_page
    ; pop esi
    ; pop edi

    ; Inicializar el directorio de paginas de la tarea de prueba
    ; mov edi, cr3
    ; push edi
    ; mov edi, 0x18000
    ; push edi
    ; call mmu_init_task_dir
    ; pop edi

    ; ; Cargar directorio de paginas de la tarea
    ; mov edi, cr3
    ; and edi, 0xFFF
    ; or eax, edi
    ; mov cr3, eax

    ; ; Escrituras en on demand
    ; mov dword [0x07000300], 20
    ; mov dword [0x07000300], 62

    ; ; Restaurar directorio de paginas del kernel
    ; pop edi
    ; mov cr3, edi

    ; Tareas
    mov ax, LTR_INITIAL
    ltr ax

    jmp TASK_IDLE:0

    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"
