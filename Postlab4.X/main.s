;Universidad del Valle de Guatemala
;IE2023 Programación de Microncontroladores
;Autor: LUIS PEDRO GONZALEZ 21513
;Compilador: PIC-AS (v2.40), MPLAB X IDE (v6.00)
;Proyecto: Laboratorio 4
;Creado: 03/02/2023
;Última Modificación: 03/02/2023
; Entrega postlab4
;--------------------rt-------------------------------
PROCESSOR 16F887
#include <xc.inc>
;---------------------------------------------------
;Palabra de Configuración
;---------------------------------------------------
    
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF              ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON             ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF             ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF                ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF               ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = ON             ; Brown Out Reset Selection bits (BOR controlled by SBOREN bit of the PCON register)
  CONFIG  IESO = OFF              ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF             ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF               ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V          ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF               ; Flash Program Memory Self Write Enable bits (Write protection off)
  
  
  
;VARIABLES
PSECT udata_shr
    W_TEMP: DS 1; 1 BYTE
    STATUS_TEMP: DS 1; 1 BYTE
    UP	EQU 6 ; DECLARAN CONSTANTES PARA LOS PUERTOS
    DOWN    EQU 7
    VERIFICADOR: DS 1; 1 BYTE antirebotes
    CONTMR0: DS 1; 1 BYTE contador del tmr0 ms
    CONTSEGS: DS 1; 1BYTE Ccontador de segundos
    CONTDEC: DS 1; 1 BYTE variable para ocntar los decimales
    

 ;-------------- vector reset----------
PSECT resVect, class=CODE, abs, delta=2
ORG 00h ; posición 0000h para el reset 
resetVect:
    PAGESEL main
    goto main 

 ;--------------INTERRUPCIONES----------
PSECT resVect, class=CODE, abs, delta=2
ORG 04h ; POSICION DE LA INTERRUPCION 

PUSH:
    MOVWF W_TEMP	    ;PONER EL VALOR DEL W EN EN WTEMP,ES DECIR LA VARIABLE TEMPORAL
    SWAPF STATUS, W	    ;HACER SWAP Y GUARDAR EN W
    MOVWF STATUS_TEMP	    ;MOVER EL VALOR DE W EN LA OTRA VARIABLE TEMPORAL
ISR:  
    BTFSC RBIF	    ;REVISAR EL BIT DE INTERRUPCIONES DEL PUERTO B
    CALL INT_PORTB  ;IR A LA SUBRUTINA DE PORTB
    
    BTFSC T0IF ; REVISAR EL BIT DE INTERRUPCIONES DEL TMR0
    CALL INT_TMR0   ;LLAMAR A LA SUBRUTINA DEL TMR0

  
POP:
    SWAPF STATUS_TEMP, W    ;CAMBIAR EL VALOR DE STATUS CON W
    MOVWF STATUS	    ;CARGAR EL VALOR DEL STATUS, ES DECIR, W A STTUS
    SWAPF W_TEMP, F	    ;CAMBIAR STATUS_TEMP DE W A F PARA QUE ESTEN EN ORDEN AL MOVERLOS
    SWAPF W_TEMP, W	    ;MOVER EL VALOR DE W A W, SE ROTA DE NUEVO PARA NO MODIFICAR EL ORDEN Y GUARDAR EN W
    RETFIE		    ;REGRESAR DE LA INTERRUPCIóN
 
    
/////////////////////////////////////////////////////
/////////////////SUBRUTINAS/////////////////////////////
////////////////////////////////////////////////////
    
/////////INTERRUPCION DEL PUERTO B(PUSHBUTTONS)
INT_PORTB:
    
    //BANKSEL PORTA; LLAMR AL BANCO
    
    BTFSS RBIF  ;REVISAR EL BIT DE INTERRUPCIO DEL PORTB
    RETURN
    BANKSEL PORTB
    BTFSC PORTB, UP ; REVISAR SI SE PRESIONA EL BOTON
    CALL VERIFICADOR1 ; LLAMAR AL ANTIRREBOTE
    BTFSS PORTB, UP ; REVISAR SI SE DEJA DE PRESIONAR
    CALL INCREMENTO
    
    BTFSC PORTB, DOWN;REVISAR SI EL BOTóN DE DECREMENTAR FUE PRESIONADO
    CALL VERIFICADOR2 ; LLAMAR AL ANTIREBOTE
    BTFSS PORTB, DOWN ; REVIAR SI SE DEJA DE PRESIONAR
    CALL DECREMENTO
    BCF RBIF	    ;LIMPIAR BIT DE INTERRUPCIóN DEL PUERTO B
    RETURN		    ;REGRESAR
    
    
    
/////////////////////////////////////////////////
    ////////////////////ANTIREBOTES
  ///////////////////////////////////////////
  
VERIFICADOR1:;ANTIRREBOTE 1
    BSF VERIFICADOR, 0
    RETURN
    
VERIFICADOR2: 
    BSF VERIFICADOR, 1
    RETURN
 
///////////////INTERRUPCION DEL TMR0
    
INT_TMR0:
      // RE INICIO EL TMR0
    BANKSEL TMR0 ; SELCCIONA EL TMR0
    //0.02 SEG = 4*1/2MHZ*256-N*256 Y SE DESPEJO N
    MOVLW 217 ; DELAY DE 20MS
    MOVWF TMR0 ; CARGAR EL VALOR AL TMRO
    BCF T0IF ; LIMPIAMOS LA BANDER DE INTERRUPCION DEL TMR0
    
    INCF CONTMR0 ; INCREMENTAMIS LA VARIABLE DEL CONTADOR DE MS
    MOVF CONTMR0, W ; MOVEMOS EL VALOR DEL CONTADOR A W
    //20*50 = 1000MS
    SUBLW 50 ; SE LE RESTA 50 A W PARA SABER SI SE HA LLEGADO A 1000MS
    BTFSS ZERO ; CHEQUEAR SE ACTIVA LA BANDERA ZERO,si el bit ZERO es 1 la resta es 0 y se prosigue; si el BIT ZERO es 0 se vuelve a verificar    

    GOTO RETURN_TMR
    CLRF CONTMR0    ; LIMPIAR LA VARIABLE DEL TMR0
    INCF PORTB ; INCREMENTAR EL PUETO B EN, tmr0
    
    GOTO INCRE_SEGS ; IR A LA SUBRUTINA DE INCREMETO DE SEGUNDOS
    RETURN_TMR:
	RETURN
	
	
////////////////////////////SUBRUTUNAS DE INC Y DEC
INCREMENTO:			    
    BTFSS VERIFICADOR, 0 ; REVISAR BANDERA
    RETURN
    INCF PORTA, F ; INCREMETAR EL PORTA
    CLRF VERIFICADOR ;LIMPIRAR LA BANDERA
    RETURN
	
DECREMENTO:
    BTFSS VERIFICADOR, 1	    ;FUNCION DE DECREMENTAR
    RETURN
    DECF PORTA, F ; DECREMNTAR PORT A
    CLRF VERIFICADOR
    RETURN   
    
//////////////////////////////////////////////////////
//////////////////INCREMENTO DE SEGUNDOS
////////////////////////////////////////////////////////
INCRE_SEGS:
    INCF CONTSEGS ; INCREMETAR LA VARIBALE QUE CUNETA LO SEGUNDOS
    MOVF CONTSEGS, W ; MOVEMOS EL VALOR DE LA VARIABLE A W
    SUBLW 10 ; SE RESTA 10 PARA SABER SI SE LLEG A 10 SEGUNDOS
    BTFSS ZERO; ; CHEQUEAR SE ACTIVA LA BANDERA ZERO,SI ES 1 LA RESTA SI DIO 0
    GOTO RETURN_SEG ; VOLVER A CHEAQUEAR SI SE LLEGA A 10 SEG
    CLRF CONTSEGS ; LIMPIAR EL CONTADOR DE SEGUNDOS
    GOTO INCRE_DEC; IR A LA SBRUTINA DE DECIMALES
    RETURN_SEG://SUBRUTINA DE REGRESO 
	RETURN
	   
///////////////////////////////////////////////////////////////////////
/////////////////INCREMENTO DE DECENAS////////////////////////////
/////////////////////////////////////////////////////////////
/// LA SUBRUTINA LIMITA LOS 60 SEGUNDO Y REINICIA LA CUENTA
INCRE_DEC:
    INCF CONTDEC ; INCREMETAR EL CONTADOR DE DECIMALES
    MOVF CONTDEC, W ; OVER EL VALOR DEL CONTADOR A W
    // 6 CICLOS DE 10 SEGS
    SUBLW 6 ; CHEQUEAR SI LLEGO A 60 SEGUNDOS
    BTFSS ZERO ; CHEQUEAR LA BANADERA DE ZERO
    GOTO RETURN_DEC ; VOLVER A CHEQUEAR SI SE LLEGA A 60 SEGS
    CLRF CONTDEC
    CLRF CONTSEGS ; LIMPIAR AMBOS CONTADORES PARA REINCIAR 
    
    RETURN_DEC: //SUBRUTINA DE REGRESO
	RETURN
	    
;----------- Código Principal ----------
PSECT CODE, delta=2, abs
 ORG 100h
 
////////////////////////////////////////////////////////
 ////TABLA DE VALORES PARA EL DISPLAY
 ///////////////////////////////////
TABLA:
    CLRF PCLATH ; limpiar pclath
    BSF PCLATH, 0 ; estbalecel el bit 0 de pclath, es decir en 01
    
    ANDLW 0x0F     ; 15 A W PARA ESTABLECER LIMITE Y QUE W SOLO TENGA LOS 4 BITS MENOS SINIFICATIVOS
    ADDWF PCL      ;SUMA EL PCL Y W, ASI PC = PCLATH+PCL+W, INDICA POSICION EN PC
    RETLW 00111111B ;0
    RETLW 00000110B ;1
    RETLW 01011011B ;2
    RETLW 01001111B ;3
    RETLW 01100110B ;4
    RETLW 01101101B ;5
    RETLW 01111101B ;6
    RETLW 00000111B ;7
    RETLW 01111111B ;8
    RETLW 01100111B ;9
    RETLW 01110111B ;A
    RETLW 01111100B ;B
    RETLW 00111001B ;C
    RETLW 01011110B ;D
    RETLW 01111001B ;E
    RETLW 01110001B ;F 
    
    
 ///////////////////////////////////////////////////
 ///MAIN
 /////////////////////////////////////////////////
 
 main:
    

    ///////////////////////////////////////////////////////////
    ///////////CONFIGURACION DE PUERTOS
    //////////////////////////////////////
    BANKSEL ANSEL ; INGRESAR AL BANCO DE ANSEL
    CLRF ANSEL
    CLRF ANSELH ;CONGIFURAR PUERTOS COMO DIGITALES
    
        
    ;PONER  PUERTO COMO SALIDAS
    BANKSEL TRISA
    CLRF TRISA	      ;PUERTO A COMO SALIDA
    CLRF TRISC ; PUERTO  COMO SALIDA
    CLRF TRISD ; PUERTO D COMO SALIDA
	
    BANKSEL TRISB
    BSF TRISB,UP      ;RD6 COMO ENTRADA push buttons
    BSF TRISB, DOWN      ;RA7 COMO ENTRADA
    BCF TRISB, 2	    ;RB0 COMO SALIDA
    BCF TRISB, 3	    ;RB1 COMO SALIDA
    BCF TRISB, 4	    ;RB2 COMO SALIDA
    BCF TRISB, 5	    ;RB3 COMO SALIDA	

    
    ;INICIAR PUERTOS
    BANKSEL PORTA     ;ir al banco de puertos
    CLRF PORTA        ;inicia puerto a
    CLRF PORTB ; INICIA EL PUERTO B    
    CLRF PORTC ; INICA EL PORTC
    CLRF PORTD ; INICIA EL PORTD
   
 //////////////////////////////////////////////
 /////INTERRUPCIONES DEL PORTB ON CHANGE
 /////////////////////////////////////////////////////////////
    BANKSEL IOCB ;ABRIR EL BANCO DONDE SE CONFIGURAN LS INTERRUPCIONED
    
    BSF IOCB, UP ;PORTB0 INTERRUPCION PARA PUSHBUTTON
    BSF IOCB, DOWN; PORTB1 INTERRUPCION PARA PUSHBUTTON
    
    BANKSEL PORTA
    MOVF PORTB, W ; CARGAR EL VALOR DE PORTB A W PARA FINALIZAR MISMATCH
    BCF RBIF ; LIMPIAR LA BANDER DE INT ON CHANGE DE PORTB
    
    
    /////////////////////////////////////////////////////
    /////////////////PULL UPS
    /////////////////////////////////////////////////////
    BANKSEL OPTION_REG
    BCF OPTION_REG, 7	    ;SE LIMPIA RBPU PARA USAR PULL UPS
    BANKSEL WPUB	    ;DETERMINAR PINES QUE VAN A LLEVAR PULL-UPS
    BSF WPUB, UP		    ; PULL-UP
    BSF WPUB, DOWN		    ; PULL-UP
    
    ///////////////////////////////////////////////////
    //////////////INTERRUPCIONES GLOBALES
    /////////////////////////////////////////////
    
    BANKSEL INTCON
    BSF GIE ; HABILTAR LAS INTERUPPCIONES GLOBALES
    BSF RBIE ; ACTIVAR EL CAMBIO DE INTERRUPCIONES EN PORTB
    BCF RBIF ; LIMPIAR LA BANDER DE PORTB
    BSF T0IE ; ACTIVAR INTERRUPCION DEL TMR0
    BCF T0IF ;BANDERA DEL TMR0
    
    
    /////////////////////////////////////////////////////////
    //configuracion del oscilador
    /////////////////////////////////////////////////////////
    // 2MHZ COMO OSCILADOR 
    BANKSEL OSCCON ; aqui se encuentra la configurcion del oscildor
    BSF IRCF2 ; 1 en el bit 6
    BCF IRCF1 ;0 en el bit 5
    BSF IRCF0 ; 1  en el bit 4
    BSF SCS ; selecciona el oscilador interno
    
    
    ///////////////////////////////////////////////////////////////////////////////
    //CONFIGURACION DEL TMR0
    ////////////////////////////////////////////////////////////
    BANKSEL OPTION_REG ; SELECCIONAR EL OR
    ;TMR0 RATE 1:256 ES 111 eb=n datasheet
    ;Prescaler Assignment bit
    BCF PSA ;SE LE ASIGNA EL PRESCALER AL TIMER, PRE EN 0
    BSF PS2 ; PS2 EN 1
    BSF PS1; PS1 EN 1
    BSF PS0 ; PS0 EN 1
    BCF T0CS ; PONER T0CS EN 0 PARA QUE OPERE COMO TIMER,  Timer0 Clock Source Select bit

    CLRF CONTMR0
    CLRF CONTSEGS
    CLRF CONTDEC
     /////////// INICIO EL TMR0
    BANKSEL TMR0 ; SELCCIONA EL TMR0
    //0.02 SEG = 4*1/2MHZ*256-N*256 Y SE DESPEJO N
    MOVLW 217 ; DELAY DE 20MS
    MOVWF TMR0 ; CARGAR EL VALOR AL TMRO
    
   ///////////////////////////////
   /////LOOP PRINCIPAL
   /////////////////////////////
    loop:
    
    /////////////DIPLAY 1 segundos
    MOVF CONTSEGS, 0      ;MOVER EL VALOR DE LA VARIABLR CONTADOR DE SEGS A W
    CALL TABLA        ;LLAMAR A LA TABLA PARA OBTNER EL VALOR EN DISPLAY
    MOVWF PORTD       ;MOVER EL VALOR DE W AL PUERTO C
    
      ////////////DISPLAY 2 decenas
    MOVF CONTDEC, 0      ;MOVER EL VALOR DE LA VARIABLR CONTADOR DE DECIMLAES A W
    CALL TABLA        ;LLAMAR A LA TABLA PARA OBTNER EL VALOR EN DISPLAY
    MOVWF PORTC       ;MOVER EL VALOR DE W AL PUERTO C
    
    GOTO loop
    
    
END


