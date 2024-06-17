; Arquitectura del Computador 
; AUTOR: William Garzon

;Este segmento reserva 512 bytes para la pila utilizando un patrón de llenado 'DADA007 '.
;Esto es útil para la depuración, si se usan más de 512 bytes, los datos escritos sobrescribirán este patrón.
Stack  SEGMENT PARA STACK
	db      64 DUP('DADA007 ')              
Stack    ENDS                                
		
;Segmento de menú (Menu Segment):
;Incluye el título del juego, la descripción de la trama, instrucciones para jugar, y mensajes que se muestran en diferentes estados del juego.
Menu  SEGMENT PARA
	;Cadenas que se imprimirán en pantalla durante la ejecución del programa
		men1    db      '             ----> N E T W O R K S: D A T A  C O L L E C T O R S  <----',13,10,'$' ;30 CARACTERES -> 25 ESPACIOS A LA IZQUIERDA PARA CENTRAR
		men2    db      ' En un futuro cercano, la humanidad depende de una red cibernetica llamada la Grid para la comunicacion y el intercambio de informacion.',13,10,'$'
		men2b   db      ' Esta red es vital para la sociedad, pero esta llena de peligros como virus y datos corruptos.',13,10,'$'
		men3    db      ' Los Data Collectors son pilotos elite encargados de recolectar datos cruciales dispersos por la Grid. Recoger 1000 datos salvaras esta red.',13,10,'$'
		men4    db      ' Sin embargo, tu mision esta llena de peligros que atacaran tu escudo de proteccion.',13,10,'$'
		men4b   db      ' ---INSTRUCCIONES --- ',13,10,'$'
		men5b   db      ' Para mover tu nave usa las flechas Derecha e Izquierda.',13,10,'$'
		men6b	db 		' Flecha Arriba/Abajo: Aumenta/Disminuye las marchas de tu nave (velocidad).',13,10,'$'
		men5    db      ' ',13,10,'$'
		men6    db      ' ',13,10,'$'
		mEsc    db      ' ESC:             Salir inmediatamente del juego.',13,10,'$'
		mPausa  db      ' P:               Poner el juego en PAUSA.',13,10,'$'
		mInicio db      ' Pulsa ENTER para entrar a la RED.',13,10,'$'

		cInicio  db     '                                   ','$'        ;Para borrar mInicio sin hacer Clear Screen
		lEsc     db     'Pulsa ENTER para volver acabar el juego.  ','$'

		lPausa   db     'PAUSA                              ','$'
		lPerder  db     'FALLASTE TU MISION, NOS HACKEARON MANU','$'
		lGanar   db     'Lo Lograste, Recogiste los datos Manu!','$'

		fPuntuacion  db 'Puntuacion Final: ','$'
		fBarrera db     'Barreras Restantes: ','$'

		lMuerto  db     'TE ATACARON UNA BARRERA MENOS!','$'
		lBoton   db     'Presiona una Boton para continuar    ','$'
		lEnter   db     'Presiona ENTER para continuar       ','$'

		mBarrera db     'BARRERAS: ','$'
		mMarcha  db     'MARCHA: ','$'
		mPuntaje db     'DATOS: ','$'

		lBarrera db     '+1 BARRERA      ','$'
		lPuntaje db     '+1 DATO    ','$'
		lMarchaU db     '+1 Marcha     ','$'
		lMarchaD db     '-1 Marcha     ','$'
        ; Variables iniciales para el juego:
		barrera  dw     3       ;3 Barreras iniciales
		marcha   dw     1       ;marcha 1
		puntaje  dw     0H      ;puntuación 0
		tMarcha  dw     10H     ;ciclos en el primer marcha 16=10H
		maxPuntaje dw   100    ;puntuación máxima para terminar el juego
		lVacio  db      '                   ','$'
		; Variables para el generador de números aleatorios:
		PrimeroIN  DB   00H           ; Bandera de primera ejecución (= 0 sí; <> 0 no)
		Rnd_Lo     DW   ?             ; valor actual de 32 bits del número aleatorio
		Rnd_Hi     DW   ?
		Constante  DW   8405H         ; Valor del Multiplicador

Menu    ENDS
; Lógica del Juego
; SEGMENTO DE CÓDIGO PRINCIPAL----------------------------
_prog    SEGMENT  PARA 'CODE'    ; Asignar el Segmento de Stack y el Segmento de Datos
	ASSUME  CS:_prog,        SS:Stack,        DS:Menu        ;
	ORG 0100H       ; Dejar libres las primeras 100H ubicaciones
	INICIO: JMP     Principal    ; Saltar a la etiqueta Principal
	
    ; BOTÓN (CONSTANTES)

	kESC    EQU     1bh             ; Boton ESC
	kENTER  EQU     0dh             ; Boton ENTER
	kARR    EQU     4800h           ; Movimiento del cursor hacia arriba
	kABAJO   EQU     5000h           ; Movimiento del cursor hacia abajo
	kDERECHA     EQU     4d00h           ; Movimiento del cursor hacia la derecha
	kIZQUIERDA   EQU     4b00h           ; Movimiento del cursor hacia la izquierda
	limDerecha   EQU     27              ; Límite derecho para la nave (columna derecha del marco)
	limIzquierda   EQU     2               ; Límite izquierdo para la nave (columna izquierda del marco)
;------------MACROS----
; Macro para posicionar el cursor en la pantalla
setCur MACRO fila, columna       ; Macro que elige dónde colocar el cursor
	PUSH DX
	MOV DH, fila             ; fila
	MOV DL, columna          ; columna
	CALL posCur             ; llama a la procedimiento posCur
	POP DX
ENDM
; Macro para imprimir un carácter en modo TTY (actualiza el cursor)
stpChrT MACRO caracter              ; imprime en modo TTY (actualiza el cursor)
	PUSH AX
	MOV AL, caracter             ; elijo el carácter pasado como parámetro
	CALL writeTTY           ; llama a la procedimiento
	POP AX
ENDM
; Macro para imprimir n caracteres a color
stpChrC MACRO caracter, num, columna      ; imprime n caracteres a color
	PUSH AX
	PUSH CX
	MOV AL, caracter             ; elijo el carácter pasado como parámetro
	MOV CX, num
	MOV BL, columna
	CALL writeCOL           ; llama a la procedimiento
	POP CX
	POP AX
ENDM
; Macro para imprimir un carácter en blanco y negro
stpChrBN MACRO caracter             ; imprime un carácter en blanco y negro
	PUSH AX
	MOV AL, caracter             ; elijo el carácter pasado como parámetro
	CALL writeBN            ; llama a la procedimiento
	POP AX
ENDM
;Macro Importante para el randon-----------------------
; Macro para generar un número aleatorio
Random MACRO num       ; recordar hacer un PUSH AX si es necesario
			; el número aleatorio va de 0 a 9
	MOV AX, num      ; coloca en la entrada del procedimiento Random el valor de AX
	CALL rand
ENDM
; Descripciones:
; SEGMENTO DE CÓDIGO PRINCIPAL
; CONSTANTES DE TECLAS:
; Define las constantes para las teclas que se usarán en el juego.
; MACROS:
; Las macros definidas aquí simplifican operaciones repetitivas en el código del juego. 
; - setCur: Posiciona el cursor en una fila y columna específica usando la interrupción de BIOS correspondiente.
; - stpChrT: Imprime un carácter en modo TTY, actualizando la posición del cursor después de imprimir.
; - stpChrC: Imprime un número específico de caracteres con un color determinado.
; - stpChrBN: Imprime un carácter en blanco y negro.
; - Random: Genera un número aleatorio entre 0 y 9. La macro facilita la generación de números aleatorios en el juego, lo cual es útil para diversas mecánicas del juego, como la aparición de obstáculos o elementos aleatorios.
;-------------------------------------------------------------------------
; MACROS PARA MENSAJES Y RETARDOS--------------------------------
; Macro para imprimir mensajes del menú
stpMen  MACRO men     ; imprime un mensaje almacenado en la memoria (Segmento de Datos)
	PUSH AX
	PUSH BX
	PUSH DX
	MOV AX, SEG Menu
	MOV DS, AX
	MOV DX, OFFSET men
	MOV AH, 09H
	INT 21H
	POP DX
	POP BX
	POP AX
ENDM
; Macro para crear retardos
Retardo MACRO tick      ; crea un retardo (1 tick = 0.55 ms -> 18H ticks = 1 segundo)
	PUSH CX
	MOV CX, tick
	CALL delay      ; llama a la procedimiento delay que se basa en el reloj
	POP CX
ENDM
; Descripciones:
; Macro stpMen:
; Esta macro se utiliza para imprimir mensajes almacenados en la memoria del segmento de datos. 
; Primero, guarda los registros AX, BX y DX en la pila para preservar sus valores actuales. 
; Luego, carga el segmento de datos del menú en DS, y la dirección del mensaje se coloca en DX. 
; Utiliza la función 09H de la interrupción 21H para imprimir la cadena de caracteres apuntada por DX. 
; Finalmente, restaura los valores de los registros desde la pila.
; Macro Retardo:
; Esta macro crea un retardo en la ejecución del programa. 
; La cantidad de tiempo de retardo se determina por el valor de 'tick', donde 1 tick equivale a 0.55 ms. 
; El valor de 'tick' se carga en el registro CX y se llama al procedimiento delay que se basa en el reloj del sistema para crear el retardo. 
; El valor original del registro CX se restaura al final de la macro.
;-----------------------------------------------------------

; NOTA: en DX se guardará la posición de la nave
;       en BX se guardará el obstáculo/Dato/barrera (BL=Tipo)  x=virus, v=barrera, m=Dato
;       CX es el contador del ciclo

Principal:      CALL cls        ; limpiar pantalla
		setCur 0,0
		stpMen men1     ; imprimir las instrucciones en pantalla
		setCur 2,0 
		stpMen men2
		stpMen men3
		stpMen men4
		stpMen men4b
		stpMen men5
		stpMen men5b
		stpMen men6
		stpMen men6b
		stpMen mEsc
		stpMen mPausa
		setCur 11,1
		stpMen lBoton
		CALL outCur
		CALL waitKey    ; espera una Boton para continuar

Inicios:         ; cada vez que se choca contra un virus, se empieza de nuevo desde aquí
		CALL cls        ; limpiar pantalla
		CALL wBorde     ; dibuja el borde

	; IMPRIMIR LAS Barreras
		setCur 4,40
		stpMen mBarrera
		setCur 4,50
		stpChrC 03H, barrera, 04H    ; imprime los as Barreras

	; IMPRIMIR LA marcha
		setCur 6,40
		stpMen mMarcha
		setCur 6,50
		stpChrC 09H,marcha, 09H   ; imprime los puntos (que representan la marcha de la nave)

	; IMPRIMIR LA PUNTUACIÓN
		setCur 8,40
		stpMen mPuntaje
		setCur 8,50
		MOV AX, puntaje
		CALL word2dec           ; imprime la puntuación

	; POSICIONAR LA NAVE ABAJO EN EL CENTRO
		MOV DH, 20       ; fila
		MOV DL, 14       ; columna
		CALL setCar     ; posicionar la nave

		setCur 15,40    ; ZONA DONDE SE IMPRIMEN LOS MENSAJES
		stpMen mInicio  ; inicio del marcha, espera un ENTER
		CALL outCur
reqENTER:       CALL waitKey    ; espera la Boton ENTER
		CMP AL, kENTER
		JNE reqENTER
		setCur 15,40
		stpMen cInicio

		; CALL outCur    ; esconder el cursor
		MOV BX, 0000H    ; inicializar en cada ciclo el controlador de obstáculos/barrera/Datos
Ciclo:          MOV CH, BYTE PTR tMarcha   ; establecer el marcha inicial (velocidad)
		MOV CL, 0        ; inicializar el contador del ciclo para incrementar

        CMP CH,CL       ;si he cambiado la marcha y
        JBE Continue3   ;CH es menor o igual a CL -> Reinicio el ciclo
                        ;si no pongo este control, el programa puede colgarse
                        ;por ejemplo, si CL vale 0AH y CH ha llegado a 0BH mientras cambié el marcha
                        ;JBE = jump below or equal

        PUSH DX
        setCur 15,40    ;borrar el mensaje interactivo
        stpMen lVacio   ;del ciclo anterior
        POP DX
        CMP BL,'m'      ;si he tomado un dato, incremento la puntuación
         JE addDato
        CMP BL,'v'
         JE addBarrera     ;si he tomado una barrera, incremento las barreras (a menos que ya sean 5)

Continue3:      JMP AspKey

addDato:         PUSH AX         ;he tomado una Dato
         MOV AX,puntaje   ;podría hacer directamente "INC Puntaje"
         ;INC AX         ;incremento la puntuación
         ADD AX,marcha    ;en vez de incrementar en 1 unidad, añado el valor del marcha
         MOV puntaje,AX
         setCur 8,50    ;posiciono el cursor en la zona Puntaje:
         CALL word2dec  ;imprimo el valor ascii/decimal de la variable Puntaje
         setCur 15,40   ;posiciono el cursor en la zona MENSAJES
         stpMen lPuntaje  ;escribo +1 Puntaje
        POP AX
        MOV BX,0000H    ;inicializo el controlador de obstáculos/barreras/Datos
        JMP AspKey

addBarrera:        CMP barrera,5      ;he tomado una barrera
        JAE barrera5       ;si las barreras son mayores o iguales a 5 entonces no añadir más barreras
        PUSH AX
         MOV AX,barrera
         INC AX         ;incremento la variable Barrera
         MOV barrera,AX
         setCur 4,50    ;posiciono el cursor en la zona Barrera:
         stpChrC 03H,barrera,04H   ;imprimo tantos corazones rojos como barreras hay
         setCur 15,40   ;posiciono el cursor en la zona MENSAJES
         stpMen lBarrera   ;escribo +1 Barrera
        POP AX
Barrera5:          MOV BX,0000H    ;inicializo el controlador de obstáculos/barreras/Datos
        JMP AspKey
AspKey:
        CMP BL,'x'      ;verificar si he tomado un asteroide
        JE Muerto2      ;si tomado -> voy a Muerto2
        CALL setCar     ;verificar si he chocado con un obstáculo o si he tomado una Dato/barrera y posicionar la nave
        Retardo 01H     ;18 "esperas" por segundo
        INC CL          ;incremento el contador de las 18 esperas
        CMP CL,CH       ;Si CL=CH entonces estamos al final del ciclo (pasaron 18 esperas si el ciclo es de un segundo)
        JE Continue2    ;bajar una línea
        CALL pressKey   ;de lo contrario, verificar si se presiona una Boton
        JZ AspKey        ;si no se presiona ninguna Boton, seguir esperando
         CALL waitKey    ;de lo contrario, verificar qué Boton se ha presionado
         CMP AL,kESC     ;presiono ESC
         JE  Salir2       ;salir al DOS
         CMP AL,'P'      ;presiono P
         JE I_Pausa      ;poner el juego en pausa
         CMP AL,'p'      ;presiono p (minúscula)
         JE I_Pausa      ;poner el juego en pausa
         CMP AX,kDERECHA      ;presiono flecha Derecha - kDERECHA EQU 4D00H
         JE Derecha2
         CMP AX,kIZQUIERDA      ;presiono flecha Izquierda - kIZQUIERDA EQU 4B00H
         JE Izquierda2
         CMP AX,kARR      ;presiono flecha Arriba
         JE Arriba2
         CMP AX,kABAJO     ;presiono flecha Abajo
         JE Abajo2
         ;CMP AL,'h'      ;AUMENTA 100 LA PUNTUACIÓN
         ;JE HintA2
         ;CMP AL,'H'      ;DISMINUYE 100 LA PUNTUACIÓN
         ;JE HintB2
         JMP Boton2      ;ir a imprimir la Boton presionada
; Descripción de cada sección:
; Principal:
; Esta sección inicializa el juego. Limpia la pantalla, imprime las instrucciones del juego,
; y espera a que el jugador presione una tecla para comenzar.
; Inicios:
; Esta sección se ejecuta cada vez que el jugador choca contra un virus y se reinicia la posición inicial.
; Limpia la pantalla, dibuja el borde del juego, e imprime las barreras, la marcha, y la puntuación.
; Ciclo:
; Este es el ciclo principal del juego. Establece la marcha inicial y controla el ciclo del juego.
; Verifica si el jugador ha tomado un dato o una barrera, y actualiza la puntuación o el número de barreras.
; Si el jugador toma un asteroide, se ejecuta la rutina de colisión. También maneja el retardo
; para la velocidad del juego y verifica las teclas presionadas para mover la nave o realizar otras acciones.
; addDato:
; Incrementa la puntuación del jugador cuando toma un dato, añadiendo el valor de la marcha a la puntuación actual.
; addBarrera:
; Incrementa el número de barreras del jugador hasta un máximo de 5 barreras.
; AspKey:
; Verifica si el jugador ha tomado un asteroide, manejando la colisión. También maneja la entrada del jugador
; para mover la nave o realizar otras acciones (como pausar o salir del juego).
;-----------------------------------------------------------------
;----------etiquetas para JUMP demasiado largos-------------
;Win2:           JMP Win
Muerto2:        JMP Muerto
Derecha2:       JMP Derecha
Izquierda2:     JMP Izquierda
Salir2:         JMP Salir
Continue2:      JMP Continuar
Boton2:         JMP Boton
Arriba2:        JMP Arriba
Abajo2:         JMP Abajo
;------------etiquetas para JUMP demasiado largos-----------
;-----Gestión de PAUSA------------------------------
I_Pausa:        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        setCur 15,40    ;ESCRIBO "PAUSA" en la zona MENSAJES
        stpMen lPausa
Pausa:          CALL waitKey    ;espero una Boton
        CMP AL,kESC     ;Boton ESC
        JE Salir2       ;voy a Salir
        CMP AL,'P'      ;Boton P
        JE F_Pausa      ;Finalizo la Pausa
        CMP AL,'p'      ;Boton p
        JE F_Pausa      ;Finalizo la Pausa
        JMP Pausa       ;de lo contrario, continuo la pausa -> loop Pausa
F_Pausa:        setCur 15,40    ;ELIMINO la palabra "PAUSA"
        stpMen lVacio
        POP DX
        POP CX
        POP BX
        POP AX
        JMP AspKey      ;voy a AspKey
AspKey2:        JMP AspKey
; Descripcion de la Secion:
; Etiquetas para JUMP demasiado largos: 
; Estas etiquetas permiten saltos largos en el código. Son necesarias debido a las restricciones
; de longitud de los saltos en ensamblador.
;Gestión de PAUSA:
; La rutina de pausa permite al jugador detener el juego y luego continuar.
; Presionar 'P' o 'p' reanuda el juego, mientras que presionar ESC sale del juego.
;------------------------------------

;------Controles del Jugador----------------------------------
Derecha:        ;mueve la nave hacia la derecha
        CMP DL,limDerecha    ;verifico si la nave ha llegado al borde derecho
        JE AspKey2      ;si ha llegado al límite derecho y quiero moverla más a la derecha, el programa la bloquea
         INC DX         ;de lo contrario, puedo moverla a la derecha una posición
         PUSH DX
         SUB DX,2       ;muevo el cursor a donde estaba la nave antes de moverla a la derecha
         CALL posCur
         stpChrBN ' '   ;pongo un carácter ' ' a la izquierda donde antes estaba la nave
         POP DX
        JMP AspKey      ;espero la próxima Boton
Izquierda:      ;mueve la nave hacia la izquierda
        CMP DL,limIzquierda    ;verifico si la nave ha llegado al borde izquierdo
        JE AspKey2      ;si ha llegado al límite izquierdo y quiero moverla más a la izquierda, el programa la bloquea
         DEC DX         ;de lo contrario, puedo moverla a la izquierda una posición
         PUSH DX
         ADD DX,2       ;muevo el cursor a donde estaba la nave antes de moverla a la izquierda
         CALL posCur
         stpChrBN ' '   ;pongo un carácter ' ' donde antes estaba la nave
         POP DX
        JMP AspKey      ;espero la próxima Boton
Arriba:         ;sube de marcha
        CMP marcha,8     ;verifico si estamos en el marcha 8
        JAE marcha8      ;si el marcha es mayor o igual a 8 entonces no añadir más marchaes
         PUSH AX
         MOV AX,marcha   ;de lo contrario, añado un marcha
         INC AX
         MOV marcha,AX
          MOV AX,tMarcha ;disminuyo la duración del ciclo en 2 ticks
          SUB AX,2
          MOV tMarcha,AX
         setCur 6,50    ;posiciono el cursor en la zona NIVEL:
         stpChrC 09H,marcha,09H  ;imprimo el número de marchaes (puntos azules)
         setCur 15,40   ;posiciono el cursor en la zona MENSAJES
         stpMen lMarchaU ;imprimo +1 NIVEL
        POP AX
marcha8:          MOV BX,0000H    ;inicializo el controlador de obstáculos/barreras/Datos
        JMP aspKey
Abajo:          ;baja de marcha
        CMP marcha,1     ;verifico si estamos en el marcha 1
        JBE marcha1      ;si el marcha es menor o igual a 1 entonces no reducir el marcha
        PUSH AX
         MOV AX,marcha
         DEC AX         ;de lo contrario, decremento el marcha
         MOV marcha,AX
          MOV AX,tMarcha ;aumento la duración del ciclo en 2 ticks
          ADD AX,2
          MOV tMarcha,AX
          setCur 6,50
          stpMen lVacio  ;borro los marchaes anteriores para poder imprimir menos puntos que antes (de lo contrario, no se nota la reducción de marchaes)
         setCur 6,50    ;posiciono el cursor en la zona Marcha:
         stpChrC 09H,marcha,09H  ;imprimo el número del marcha (puntos azules)
         setCur 15,40   ;posiciono el cursor en la zona MENSAJES
         stpMen lMarchaD ;escribo -1 Marcha
        POP AX
marcha1:          MOV BX,0000H    ;inicializo el controlador de obstáculos/barreras/Datos
        JMP aspKey
Boton:  
        JMP AspKey
Continuar:      CALL goABAJO     ;hago "bajar" los obstáculos una fila
        ;ahora dibujo los nuevos obstáculos/barrera/Dato (con diferentes probabilidades)
        Random 99      ;número aleatorio entre 0 y 99 (100 números en total)
        CMP AX,95
         JAE Escudo        ;mayor o igual a 95 -> barrera (5% de prob)
        CMP AX,25
         JB Dato      ;menor de 25 -> Dato (25% de prob)
        CALL wOst       ;de lo contrario -> imprimo un obstáculo (el resto del 73% de prob)
        JMP Next
Escudo:      CALL wBarrera      ;imprimo una barrera
        JMP Next
Dato:         CALL wDatos       ;imprimo una Dato
        JMP Next
Muerto:         ;PUSH AX
                ;MOV AX,Barrera
                ;DEC AX
                ;MOV Barrera,AX
                ;POP AX
        DEC barrera        ;decremento una barrera
        CMP barrera,0      ;si la barrera es cero -> Game Over
        JE Perder
         CALL setCar    ;de lo contrario, reinicio el juego con una barrera menos
         PUSH DX
         setCur 4,50            ;posiciono el cursor en la zona VIDA:
         stpChrC 03H,barrera,04H   ;actualizo el número de corazones
         setCur 15,40           ;posiciono el cursor en la zona MENSAJES
         stpMen lMuerto         ;imprimo el mensaje "Has chocado contra un asteroide"
         setCur 16,40
         stpMen lEnter          ;imprimo "Presiona enter para continuar"
         POP DX

espEnter:        CALL waitKey           ;espero el botón ENTER
        CMP AL,kENTER           ;para reiniciar el juego con una barrera menos
        JNE espEnter
        JMP Inicios
Next:      CALL outCur     ;oculto el cursor
        PUSH AX         ;compruebo si he alcanzado la puntuación máxima
        MOV AX,maxPuntaje ;no puedo comparar dos variables directamente
        CMP puntaje,AX    ;entonces pongo una de las dos en AX
        POP AX
        JAE Ganar

        JMP Ciclo       ;continúo con el bucle y voy a la etiqueta Ciclo
Perder:         ;CALL cls
        PUSH DX
        setCur 15,40    ;posiciono el cursor en la zona MENSAJES
        stpMen lPerder   ;escribo GAME OVER
        POP DX
        CALL setCar
        JMP Salida
Ganar:          PUSH DX
        setCur 15,40
        stpMen lGanar
        POP DX
        CALL setCar
Salida:         setCur 17,40
        stpMen fPuntuacion   ;imprimo la puntuación final
        setCur 17,59    ;zona valor de la puntuación
        PUSH AX
        MOV AX,puntaje
        CALL word2dec   ;valor decimal de la
        POP AX
        ;POP DX
        CALL waitKey    ;espero un Boton
Salir:           setCur 19,40
		stpMen lEsc    ;stampo il messagio di uscita
waitINV:        CALL waitKey    ;aspetto Iniciar per uscire
		CMP AL,kENTER
		JNE waitINV
		CALL cls
		CALL tornaDOS   ;chiamo la procedura per tornare al dos
;Descripcion de la Seccion:
; Derecha: Mueve la nave hacia la derecha en la pantalla del juego.
; Verifica si la nave ha alcanzado el borde derecho y la mueve si no lo ha hecho.
; También actualiza la representación visual de la nave en la pantalla.
; Izquierda: Mueve la nave hacia la izquierda en la pantalla del juego.
; Verifica si la nave ha alcanzado el borde izquierdo y la mueve si no lo ha hecho.
; También actualiza la representación visual de la nave en la pantalla.
; Arriba: Aumenta la velocidad o "marcha" de la nave.
; Incrementa el nivel de marcha si este no es el máximo.
; Ajusta la duración del ciclo de juego para aumentar la velocidad aparente del juego.
; Abajo: Disminuye la velocidad o "marcha" de la nave.
; Decrementa el nivel de marcha si este no es el mínimo.
; Ajusta la duración del ciclo de juego para reducir la velocidad aparente del juego.
; Boton: No realiza ninguna acción cuando se presiona.
; Esta etiqueta se deja para uso futuro o para hacer que el programa reaccione a los botones genéricos.
; Continuar: Realiza las acciones necesarias para avanzar al siguiente ciclo del juego.
; Esto incluye mover los obstáculos hacia abajo, generar nuevos obstáculos y actualizar el estado del juego.
; Muerto: Realiza las acciones cuando la nave choca con un obstáculo y pierde una vida.
; Decrementa el número de vidas, actualiza la pantalla y verifica si el juego ha terminado.
; Perder: Realiza las acciones cuando el jugador pierde el juego.
; Muestra el mensaje de "GAME OVER" en la pantalla.
; Ganar: Realiza las acciones cuando el jugador alcanza la puntuación máxima y gana el juego.
; Muestra el mensaje de "GANASTE" en la pantalla.
; Salida: Realiza las acciones para finalizar el juego.
; Muestra la puntuación final y espera que el jugador presione un botón para salir
;---------------------------------------------------------------------------------------------------------
;PROCEDIMIENTOS COMO DISEÑO DEL MAPA, RANDOM DE OBJETOS.
wBorde PROC NEAR        ;dibuja el borde del juego
		;IMPRIME FILA SUPERIOR
		setCur 0,0      ;posiciona el cursor en la esquina superior izquierda
		stpChrT 0DAH    ;imprime la esquina superior izquierda
		MOV CX,28       ;establece el bucle a 28 veces (columnas)
CicloR1:        stpChrT 0C4H    ;imprime la línea superior
		LOOP CicloR1    ;hasta que llegue a la columna 29
		stpChrT 0BFH    ;donde imprime la esquina superior derecha
		;IMPRIME COLUMNA IZQUIERDA
		MOV DH,01H      ;establece la fila en 2
		MOV DL,00H      ;establece la columna en 0 (fija) - primera columna
		MOV CX,20       ;establece el bucle a 20 veces (filas)
CicloC1:        CALL posCur     ;posiciona el cursor en DH,DL (fila,columna)
		stpChrT 0B3H    ;imprime el carácter | para la columna izquierda
		inc DH          ;incrementa el contador (pasa a la fila siguiente)
		LOOP CicloC1    ;20 veces
		;IMPRIME COLUMNA DERECHA
		MOV DH,01H      ;establece la fila en 2
		MOV DL,29       ;establece la columna en 29 (fija) - columna 30
		MOV CX,0020     ;establece el bucle a 20 veces (filas)
CicloC2:        CALL posCur     ;posiciona el cursor en DH,DL (fila,columna)
		stpChrT 0B3H     ;imprime el carácter | para la columna derecha
		inc DH          ;incrementa el contador (pasa a la fila siguiente)
		LOOP CicloC2    ;20 veces
		;IMPRIME FILA INFERIOR
		setCur 21,0     ;posiciona el cursor en la fila 22, columna 0
		stpChrT 0C0H     ;imprime la esquina inferior izquierda
		MOV CX,28     ;establece el bucle a 28 veces (columnas)
CicloR2:        stpChrT 0C4H     ;imprime el guion para crear la fila
		LOOP CicloR2    ;28 veces
		stpChrT 0D9H     ;imprime la esquina inferior derecha
		;SE CREA UN RECTÁNGULO DE 22 FILAS X 30 COLUMNAS
wBorde  ENDP
;-----------------------------------
rand    PROC    NEAR        ;función que crea un número aleatorio entre 0<n<AX
	OR      AX,AX           ;si el valor del rango pasado como parámetro
	JNZ     Rand_1          ;es nulo se impone la terminación inmediata de la
	RET                     ;procedimiento (valor incorrecto!)
Rand_1: PUSH    BX          ;Guarda los registros utilizados por el procedimiento
	PUSH    CX
	PUSH    DX
	PUSH    DI
	PUSH    DS
	PUSH    AX              ;Guarda el valor del rango, pasado como entrada
							;como parámetro (se utilizará al final)
	LEA     DI,PrimeroIN      ;Verifica si se trata de la primera llamada
      CMP Byte Ptr DS:[DI],00H  ;del procedimiento que genera el retraso.
	JNE     Rand_2          ;si NO es así, calcula el nuevo valor
	MOV     AH,2CH          ;Si es la primera llamada, el procedimiento
	INT     21H             ;asume un valor aleatorio de la memoria CMOS que contiene el tiempo actual.
	MOV     DS:[Rnd_Lo],CX  ;Utiliza la función DOS 2CH que
	MOV     DS:[Rnd_Hi],DX  ;Deja en CH = Horas     (0-23)
	                        ;CL = Minutos  (0-59)
							;       DH = Segundos (0-59)
							;       DL = Centésimas de segundos (0-99)
	MOV Byte Ptr DS:[DI],01H  ;Modifica el byte de primer ingreso para evitar
							;recargar las variables aleatorias iniciales

							;Indicaciones relativas al primer ciclo
Rand_2: MOV     AX,DS:[Rnd_Lo]  ;
	MOV     BX,DS:[Rnd_Hi]  ;
	MOV     CX,AX           ;
	MUL     DS:[Constante]   ;
	SHL     CX,1            ;Algoritmo de cálculo del número aleatorio
	SHL     CX,1
	SHL     CX,1
	ADD     CH,CL
	ADD     DX,CX
	ADD     DX,BX
	SHL     BX,1
	SHL     BX,1
	ADD     DX,BX
	ADD     DH,BL
	MOV     CL,5
	SHL     BX,CL
	ADD     AX,1
	ADC     DX,0
	MOV     DS:[Rnd_Lo],AX  ;Salva il risultato a 32 bit della manipolazione
	MOV     DS:[Rnd_Hi],DX  ;nelle variabili a ciò destinate
	POP     BX              ;Recupera in BX il valore del range, passato in
							;ingresso, in AX
	XOR     AX,AX           ;Prepara il dividendo a 32 bit forzando a  zero
	XCHG    AX,DX           ;i 16 bit più significativi e copiando  nei  16
							;bit bassi il valore corrente di DX
	DIV     BX              ;AX = quoziente (DX,AX / BX)
							;DX = resto
	XCHG    AX,DX           ;il numero random corrente è il valore del resto
							;ed è lasciato, in uscita, in AX
	POP     DS
	POP     DI              ;Recupera i registri utilizzati dalla procedura
	POP     DX
	POP     CX
	POP     BX
	RET
rand  ENDP
;Descripcion de la Seccion:
; PROCEDIMIENTO wBorde
; Este procedimiento dibuja el borde del juego en la pantalla, creando un rectángulo de 22 filas x 30 columnas.
; Utiliza una combinación de caracteres ASCII para dibujar las esquinas, líneas verticales y horizontales.
; PROCEDIMIENTO rand
; Este procedimiento genera un número aleatorio en un rango especificado.
; Utiliza la interrupción del sistema de DOS (INT 21H) para obtener información del reloj del sistema y generar una semilla inicial.
; Luego, realiza una serie de cálculos y manipulaciones en los registros para generar un número aleatorio en el rango deseado.
; El número aleatorio se devuelve en el registro AX.
;---------------------------------------------------------------------------
;---- DELAYS EN EL JUEGO-----------
delay PROC NEAR         ;CX=18 para tener 0,55ms*18 = 1 segundo de retardo
    PUSH AX         ;guardo los registros
    PUSH BX
    PUSH DX

    PUSH CX         ;pongo el valor de CX en BX
    POP BX          ;en BX está el valor elegido como retardo
    CALL clock      ;devuelve en CX,DX el tiempo del sistema (32 bits)
    ADD DX,BX       ;sumo una cantidad de TICK (CX) a DX (parte baja del tiempo)
    JNC Delay_0     ;si no hay acarreo voy a Delay_0
    INC CX          ;de lo contrario, sumo el acarreo a CX
Delay_0: PUSH CX        ;copio en AX,BX el número de Tick relativos a la primera lectura
    PUSH DX         ;ACTUALIZADA con el número correspondiente al RETARDO deseado
    POP BX          ;en realidad en AX,BX tengo el tiempo futuro a alcanzar
    POP AX
Delay_1: PUSH AX        ;guardo en la pila los datos de AX,BX (tiempo a alcanzar)
    PUSH BX
    CALL clock      ;guardo los datos de la NUEVA lectura en CX,DX
    POP BX          ;y en AX,BX tengo siempre los datos del tiempo a alcanzar
    POP AX

    CMP AX,CX       ;comparo la parte alta de los dos tiempos
    JZ Delay_2      ;si son iguales, compruebo la parte baja (Delay_2)
                    ;de lo contrario, significa que (casi siempre) difieren por el acarreo
    PUSH AX         ;guardo la parte alta
    SUB AX,CX       ;compruebo si difieren, quizás de un número distinto de 1
    CMP AX,18H      ;de hecho, si la diferencia es 18H, se ha pasado de medianoche
    POP AX
    JNZ Delay_1     ;si no se ha pasado de medianoche, entonces vuelvo a Delay_1 para continuar la espera

    PUSH BX         ;si se ha pasado de medianoche (la diferencia es 18H)
    SUB BX,00B0H    ;entonces CX,DX ha pasado de 0018-00AFH a 0000-0000H
    CMP BX,DX       ;por lo tanto, también la parte baja debe adaptarse a la nueva situación
    POP BX
    JG Delay_1      ;si BX,DX sigue siendo mayor, continúo esperando
    JMP Delay_3     ;de lo contrario, ya no es necesario esperar más - ¡el retardo se ha consumido!

Delay_2: CMP BX,DX      ;si la parte alta es la misma y la parte baja del
    JG Delay_1      ;tiempo actual es menor, BX>DX -> continúa la espera

Delay_3: POP DX         ;¡el retardo se ha consumido!
    POP BX
    POP AX

    RET             ;retorna

delay ENDP
;Descripcion de la Seccion;
; PROCEDIMIENTO delay
; Este procedimiento se encarga de generar un retardo en el juego.
; El retardo se determina en función de un valor pasado en el registro CX.
; Utiliza la interrupción clock para obtener el tiempo del sistema y calcular el retardo.
; Compara el tiempo actual con el tiempo futuro esperado y espera hasta que se cumpla el retardo.
; Luego retorna al programa principal.
;-----------------------------------
;------------------------------------ Imprimir ObjetoS Aleatoriios
wBarrera PROC NEAR         ;imprime una barrera aleatorio
    PUSH DX
    PUSH CX
    PUSH BX
    PUSH AX
    Random 27       ;columna aleatoria entre 0 y 27 (pone el valor en AX)
    INC AX          ;columna aleatoria entre 1 y 28 (dentro la cornisa)
    setCur 1,AL     ;selecciono la parte superior del número aleatorio (ya que la parte alta es cero)
    MOV BH,0        ;página de video 0
    MOV CX,1        ;selecciono imprimir un carácter
    MOV AL,03H      ;selecciono el carácter (Barrera)
    MOV BL,04H      ;selecciono el color rojo sobre negro
    CALL scrivi     ;imprimo el carácter
    POP AX
    POP BX
    POP CX
    POP DX
    RET
wBarrera ENDP
;-----------------------------------
wDatos PROC NEAR       ;imprime un dato aleatoria
    PUSH DX
    PUSH CX
    PUSH BX
    PUSH AX
    Random 27       ;columna aleatoria entre 0 y 27 (pone el valor en AX)
    INC AX          ;columna aleatoria entre 1 y 28 (dentro la cornisa)
    setCur 1,AL     ;selecciono la parte superior del número aleatorio (ya que la parte alta es cero)
    MOV BH,0        ;página de video 0
    MOV CX,1        ;selecciono imprimir un carácter
    MOV AL,0FH      ;selecciono el carácter (Dato - Sol)
    MOV BL,0BH      ;selecciono el color CYAN sobre negro
    CALL scrivi     ;imprimo el carácter
    POP AX
    POP BX
    POP CX
    POP DX
    RET
wDatos ENDP
;-----------------------------------
wOst PROC NEAR       ;imprime un obstáculo aleatorio
    PUSH DX
    PUSH CX
    PUSH BX
    PUSH AX
    Random 27       ;columna aleatoria entre 0 y 27 (pone el valor en AX)
    INC AX          ;columna aleatoria entre 1 y 28 (dentro la cornisa)
    setCur 1,AL     ;selecciono la parte superior del número aleatorio (ya que la parte alta es cero)
    MOV BH,0        ;página de video 0
    MOV CX,1        ;selecciono imprimir un carácter
    MOV AL,0B1H     ;selecciono el carácter (Un "masso")
    MOV BL,05H      ;selecciono el color gris sobre negro
    CALL scrivi     ;imprimo el carácter
    POP AX
    POP BX
    POP CX
    POP DX
    RET             ;retorna
wOst ENDP
;-----------------------------------
goABAJO PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV AH,07H      ;función desplaza hacia abajo una parte de la pantalla
    MOV AL,01H      ;número de filas
    MOV CH,1        ;fila angular alto izquierda
    MOV CL,1        ;columna angular alto izquierda
    MOV DH,20       ;fila angular bajo derecha
    MOV DL,28       ;columna angular bajo derecha
    MOV BH,07H      ;color de las filas vacías negro (DEFAULT 07H)
    INT 10H
    POP DX
    POP CX
    POP BX
    POP AX
    RET             ;retorna
goABAJO ENDP
;Descripcion de la Seccion:
; PROCEDIMIENTO wBarrera
; Este procedimiento imprime una barrera aleatoria en una columna aleatoria dentro de los límites del juego. 
; PROCEDIMIENTO wDatos
; Este procedimiento imprime un dato aleatorio (barrera) en una columna aleatoria dentro de los límites del juego.
; PROCEDIMIENTO wOst
; Este procedimiento imprime un obstáculo aleatorio en una columna aleatoria dentro de los límites del juego. 
; PROCEDIMIENTO goABAJO
; Este procedimiento realiza un desplazamiento hacia abajo de una parte de la pantalla para simular el movimiento descendente de los objetos 
;--------------------------------------------------------

; ----- PROCEDIMIENTOS ----------------------------------
;procedimientos de subrutinas donde realizan operaciones específicas relacionadas con la manipulación del texto y la interfaz de pantalla.
writeTTY PROC Near      ;AL=caracter,CX=num de veces
	PUSH BX
	MOV BH,00H      ;Página 0
	MOV BL,70H      ;Blanco sobre negro
	MOV AH,0EH      ;Función 0EH de INT 10H (Imprime en pantalla uno o más caracteres coloreados)
	INT 10H
	POP BX
	RET             ;retorna
writeTTY ENDP
;--------------------------------------------

writeCOL PROC Near      ;AL=caracter,CX=num de veces,BL=color
	MOV BH,00H      ;Página 0
	MOV AH,09H      ;Función 09H de INT 10H (Imprime en pantalla uno o más caracteres coloreados)
	INT 10H
	RET             ;retorna
writeCOL ENDP
;---------------------------------------------

writeBN PROC Near      ;AL=caracter,CX=num de veces
	PUSH BX
	PUSH CX
	MOV BH,00H      ;Página 0
	MOV BL,70H      ;Blanco sobre Negro
	MOV CX,1        ;imprime UN carácter
	MOV AH,0AH      ;Función 0AH de INT 10H (Imprime en pantalla uno o más caracteres)
	INT 10H
	POP CX
	POP BX
	RET             ;retorna
writeBN ENDP
;------------------------------------------------------------

scrivi PROC    Near     ;AL=caracter,CX=num de veces,BL=color
	MOV AH,09H      ;Función 09H de INT 10H (Imprime en pantalla CX caracteres coloreados)
	INT 10H
	RET                     ;retorna
scrivi ENDP
;--------------------------------------------------------------------------

clock PROC NEAR         ;pone en los registros la hora actual:
	MOV AH,00H      ;CX=parte alta del reloj
	INT 1AH         ;DX=parte baja del reloj
	RET
clock ENDP
;-----------------------------------

waitKey PROC NEAR       ;espera una Boton
	MOV AH,00H      ;función 00H de INT 16H que espera una Boton
	INT 16H
			;AL=código ASCII, AH=código de escaneo
	RET             ;retorna
waitKey ENDP
;-----------------------------------

pressKey PROC NEAR
	MOV AH,01H      ;si se presiona una Boton, modifica el indicador de ZERO FLAG
	INT 16H
	RET
pressKey ENDP
;-----------------------------------

posCur PROC    Near     ;Procedimiento que posiciona el cursor
	PUSH AX
	PUSH BX
	PUSH DX
	MOV BH,00H      ;página de video 0 (la visible)
	MOV AH,02H      ;función 02H de INT 10H que posiciona el cursor en DH,DL (fila,columna)
	INT 10H
	POP DX
	POP BX
	POP AX
	RET             ;retorna
posCur ENDP
;--------------------------------------

setCar PROC NEAR        ;DH=fila,DL=columna
	PUSH AX
	PUSH CX
	PUSH DX
	MOV CX,0000H

	CALL posCur     ;posiciono el cursor
	 CMP BX,0000H   ;si BX es cero, aún no ha tocado nada
	 JNE asd1       ;salto la comprobación
	 CALL checkCar   ;compruebo si ha tocado algo
asd1:    CALL posCur
	stpChrBN 1EH    ;puedo imprimir el carácter central

	INC DX          ;me muevo a la derecha
	CALL posCur
	 CMP BX,0000H   ;si BX es cero, aún no ha tocado nada
	 JNE asd2       ;salto la comprobación
	 CALL checkCar
asd2:   CALL posCur
	stpChrBN '>'    ;imprimo el carácter de la derecha

	SUB DX,2        ;me muevo a la izquierda por 2
	CALL posCur
	 CMP BX,0000H   ;si BX es cero, aún no ha tocado nada
	 JNE asd3       ;salto la comprobación
	 CALL checkCar
asd3:   CALL posCur
	stpChrBN '<'    ;puedo imprimir el caracter de la izquierda

	;IMPRIME CARACTER PARA COMPROBAR
	;PUSH DX
	;setCur 18,60    ;imprimo el obstaculo que ha tocado
	;stpChrBN CH
	;POP DX

	CMP CH,'M'      ;ha cogido una Dato
	 JE Dato_2
	CMP CH,'X'      ;ha cogido una roca
	 JE Roca_2
	CMP CH,'V'      ;ha cogido una barrera
	 JE Barrera_2
	JMP CONT_2

Dato_2: JMP CONT_2    ;dejo el código así por si quiero hacer cambios posteriores

Roca_2:  JMP CONT_2

Barrera_2:   JMP CONT_2


CONT_2: INC DX
	CALL posCur

	POP DX
	POP CX
	POP AX
	RET                     ;retorna
setCar ENDP
;-----------------------------------
;---Seccion de Impresion como Coloreado--------------

checkCar PROC NEAR ;DH=fila,DL=columna
	CMP CL,01H      ;CL comprueba si ya se ha cogido algo
	JE CONT_1       ;CL=1 salto la comprobación porque no es necesario y voy al final

	CALL readCur    ;compruebo el carácter ASCII señalado por el cursor AL=carácter, AH=color
	CMP AH,05H      ;si es gris -> roca
	 JE Roca_1
	CMP AH,0BH      ;si es cyan -> Dato
	 JE Marcha_1
	CMP AH,04H
	 JE Barrera_1      ;si es rojo -> barrera
	CMP AH,01H
	 JE Niente_1    ;no coge nada
	JMP CONT_1

Roca_1: MOV CL,01H     ;establezco CL a 1 para indicar que he cogido algo
	 MOV CH,'X'     ;en CH guardo el valor del tipo de obstáculo (en CH dura un tick)
	 MOV BL,'x'     ;en BL guardo el valor del tipo de obstáculo (en BL dura un ciclo)
	 JMP CONT_1

Marcha_1: MOV CL,01H    ;establezco CL a 1 para indicar que he cogido algo
	  MOV CH,'M'    ;en CH guardo el valor del tipo de obstáculo (en CH dura un tick)
	  MOV BL,'m'    ;en BL guardo el valor del tipo de obstáculo (en BL dura un ciclo)
	  JMP CONT_1

Barrera_1:   MOV CL,01H    ;establezco CL a 1 para indicar que he cogido algo
	  MOV CH,'V'    ;en CH guardo el valor del tipo de obstáculo (en CH dura un tick)
	  MOV BL,'v'    ;en BL guardo el valor del tipo de obstáculo (en BL dura un ciclo)
	  JMP CONT_1

Niente_1: MOV CH,'_'    ;carácter de control
	  JMP CONT_1

CONT_1:   RET

checkCar ENDP
;-----------------------------------

Word2Dec PROC NEAR      ;convierte la palabra hexadecimal proporcionada en AX en los caracteres ASCII correspondientes
	PUSH    AX
	PUSH    BX
	PUSH    DX
	CMP     AX,10000        ;Si el número hexadecimal de entrada es menor
	JC      Wor2_0          ;que 10000 se evita la división siguiente
	MOV     DX,0000H        ;(DX,AX=0000XXXX):(BX=10000)=AX, resto DX
	MOV     BX,10000        ;Prepara el divisor a 10000
	DIV     BX              ;Realiza la división
	CALL    STAasci         ;Imprime el valor de las decenas de millar
	MOV     AX,DX           ;Mueve el Resto RRRR de la división anterior a AX
	JMP     SHORT Wor2_1    ;a dividir en la fase siguiente
Wor2_0: CMP     AX,1000     ;Si el número hexadecimal de entrada es menor
	JC      Byt2_0          ;que 1000 se evita la división siguiente
Wor2_1: MOV     DX,0000H    ;(DX,AX=0000XXXX):(BX=1000)=AX, resto DX
	MOV     BX,1000         ;Prepara el divisor a 1000
	DIV     BX              ;Realiza la división
	CALL    STAasci         ;Imprime el valor de las millares
	MOV     AX,DX           ;Mueve el Resto RRRR de la división anterior a AX
	JMP     SHORT Byt2_1    ;a dividir en la fase siguiente

;Byte2Dec
	PUSH    AX              ;Guarda los registros usados por el procedimiento, se toma el valor a convertir, pasado en AL
	PUSH    BX              ;como entrada
	PUSH    DX
	MOV     AH,00H          ;Formatea el dividendo al valor AX=00XX
Byt2_0: CMP     AX,100      ;Si el número hexadecimal de entrada es menor
	JC      Byt2_2          ;que 100, se evita la siguiente división
Byt2_1: MOV     BL,100      ;Prepara el divisor a 100
	DIV     BL              ;Divide AX=00XX por BL=100 (AX:BL=AL, resto AH)
	CALL    STAasci         ;Imprime el valor de las centenas
	MOV     AL,AH           ;Mueve a AL el Resto RR de la división anterior
	MOV     AH,00H          ;para dividir en la fase siguiente,
	JMP     SHORT Byt2_3    ;formateando el dividendo al valor AX=00RR
Byt2_2: CMP     AX,10       ;Si el número hexadecimal de entrada es menor
	JC      Byt2_4          ;que 10, se evita la siguiente división
Byt2_3: MOV     BL,10       ;Prepara el divisor a 10
	DIV     BL              ;Divide AX=00XX por BL=10 (AX:BL=AL, resto AH)
	CALL    STAasci         ;Imprime el valor de las decenas
	MOV     AL,AH           ;Prepara en AL la cifra de las unidades
Byt2_4: CALL    STAasci     ;Imprime el valor de las unidades
	POP     DX
	POP     BX
	POP     AX
	RET
Word2Dec ENDP
;-----------------------------------

STAasci PROC NEAR             ;imprime el valor ASCII del número en AL
	PUSH    AX
	ADD     AL,30H        ;suma 30 al número para obtener el carácter ASCII del número
	stpChrT AL
	POP     AX
	RET
STAasci ENDP
;-----------------------------------

readCur PROC NEAR             ;lee el valor del carácter ASCII señalado por el cursor
	MOV AH,08H
	MOV BH,00H
	INT 10H               ;devuelve AH=Color, AL=Carácter
	RET
readCur ENDP
;-----------------------------------

outCur PROC    Near             ;Procedimiento que oculta el cursor del video
	PUSH CX                 ;basado en el procedimiento resize cursor (si el bit 5 de CH es 1 entonces el cursor desaparece)
	PUSH AX                 ;(si el bit 5 de CH es 1 entonces el cursor desaparece)
	MOV CH,20H              ;línea de píxeles de inicio
	MOV CL,00H              ;línea de píxeles final
	MOV AH,01H
	INT 10H
	POP AX
	POP CX
	RET                     ;retorna
outCur ENDP
;-----------------------------------

cls PROC Near
	MOV AL,03H              ;modo de video 80 columnas x 24 filas
	MOV AH,00H              ;también borra la pantalla
	INT 10H
	RET
cls ENDP
;-----------------------------------

tornaDOS PROC NEAR
	MOV AH,4CH
	INT 21H
tornaDOS ENDP
;-----------------------------------
;Descripcion de la Seccion Enorme:
; PROCEDIMIENTO writeTTY:
; Este procedimiento imprime un carácter en la pantalla utilizando la función 0EH de la interrupción 10H. El carácter se imprime en blanco sobre negro.
; PROCEDIMIENTO writeCOL:
; Este procedimiento imprime un carácter en la pantalla utilizando la función 09H de la interrupción 10H. Permite especificar el color del carácter.
; PROCEDIMIENTO writeBN:
; Este procedimiento imprime un carácter en la pantalla utilizando la función 0AH de la interrupción 10H. Imprime el carácter en blanco sobre negro.
; PROCEDIMIENTO scrivi:
; Este procedimiento imprime un carácter en la pantalla utilizando la función 09H de la interrupción 10H. Permite especificar el color del carácter.
; PROCEDIMIENTO clock:
; Este procedimiento obtiene la hora actual del sistema y la devuelve en los registros CX y DX.
; PROCEDIMIENTO waitKey:
; Este procedimiento espera a que se presione una tecla y luego retorna.
; PROCEDIMIENTO pressKey:
; Este procedimiento verifica si se ha presionado una tecla y modifica el indicador de ZERO FLAG en consecuencia.
; PROCEDIMIENTO posCur:
; Este procedimiento posiciona el cursor en la posición especificada en DH y DL (fila y columna).
; PROCEDIMIENTO setCar:
; Este procedimiento posiciona y muestra un carácter en la pantalla dependiendo de la posición del cursor. También comprueba si se ha "recogido" un objeto.
; PROCEDIMIENTO checkCar:
; Este procedimiento comprueba si se ha "recogido" un objeto y guarda información sobre el objeto recogido.
; PROCEDIMIENTO Word2Dec:
; Este procedimiento convierte un número hexadecimal en ASCII y lo imprime en pantalla.
; PROCEDIMIENTO STAasci:
; Este procedimiento imprime el valor ASCII del número en AL.
; PROCEDIMIENTO readCur:
; Este procedimiento lee el valor del carácter ASCII señalado por el cursor.
; PROCEDIMIENTO outCur:
; Este procedimiento oculta el cursor del video.
; PROCEDIMIENTO cls:
; Este procedimiento borra la pantalla en modo de video 80 columnas x 24 filas.
; PROCEDIMIENTO tornaDOS:
; Este procedimiento devuelve el control al sistema operativo DOS.
;----------------------------------------------
_prog    ENDS                   ;FIN DEL SEGMENTO PROGRAMA
	END    INICIO      ;fin del programa, todo lo que se escribe después es ignorado!