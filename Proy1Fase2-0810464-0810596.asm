################################################################
#>>>>>>>>>>>>>>>>>> MAQUINA VIRTUAL MIPS-USB <<<<<<<<<<<<<<<<<<#
#  Giuli Latella USBid: 08-10596                               #
#  Fernando Gonzalez USBid: 08-10464                           #
################################################################

.data

	mensaje1: .asciiz "Bienvenido diga el nombre del archivo: "
	mensaje2: .asciiz "si es windows escriba 1, si es Unix escriba 2: "
	mensaje3: .asciiz "Error: Caracter especial en la entrada"
		.align 2
	memoria: .space 65536		#espacio reservado para memoria (segmento de datos)
		.align 2
	registros: .space 64		#espacio designado a los 16 registros
		.align 2
	buffer: .space 12 		#espacio asignado para la lectura de las tres palabras de los hexadecimales
		.align 2
	nombre:.space 80	 	#espacio para el nombre de archivo de entrada
		.align 2
	codigo: .space 65536	 	#espacio para almacenar las instrucciones en hexadecimal (segmento de texto)
	ProgramCounter: .word codigo
	
# Tabla de codigos de operacion

coopTabla:
	.word _coopTabla0
	.word 0 0 0 0
	.word _coopTabla5
	.word _coopTabla6
	.word 0 0 0 0 0 0 0 0 0
	.word _coopTabla15
	
_coopTabla0:
	.word _R _add __add	#coop 0 addd
	.word _R _sub __sub	#coop 1 sub
	.word _R _slt __slt	#coop 2 slt
	.word _R _and __and	#coop 3 and
	.word _R _or __or	#coop 4 or
	.word _R _xor __xor	#coop 5 xor
	
_coopTabla5:
	.word _I _addi __addi	#coop 80 addi
	.word _I _slti __slti	#coop 81 slti
	.word _I _andi __andi	#coop 82 andi
	.word _I _ori __ori	#coop 83 ori
	.word _I _xori __xori	#coop 84 xori
	.word _I _sll __sll	#coop 85 sll
	.word _I _srl __srl	#coop 86 srl
	.word _I _sra __sra	#coop 87 sra
	.word _I _ror __ror	#coop 88 ror
	.word _I _lui __lui	#coop 89 lui
	.word _I _li __li	#coop 90 li
	
_coopTabla6:
	.word _I _lw __lw	#coop 96 lw
	.word _I _sw __sw	#coop 97 sw
	.word _I _beq __beq	#coop 98 beq
	.word _I _bne __bne	#coop 99 bne

_coopTabla15:
	.word _R _Halt __Halt	#coop 255 Halt
	
	
	_registro: .asciiz "registro"
	_dospuntos: .asciiz ":	"
	_parentesisAb:.asciiz "("
	_parentesisCie:.asciiz ")"
	_$:.asciiz "$"
	SaltoLinea: .asciiz "\n"
	Tab: .asciiz "\t"
			
	_add: .asciiz "add 	"
	_sub: .asciiz "sub 	"
	_slt: .asciiz "slt 	"
	_and: .asciiz "and 	"
	_or: .asciiz "or 	"
	_xor: .asciiz "xor 	"
	
	_addi: .asciiz "addi 	"
	_slti: .asciiz "slti 	"
	_andi: .asciiz "andi 	"
	_ori: .asciiz "ori 	"
	_xori: .asciiz "xori 	"
	_sll: .asciiz "sll 	"
	_srl: .asciiz "srl 	"
	_sra: .asciiz "sra 	"
	_ror: .asciiz "ror 	"
	
	_lui: .asciiz "lui 	"
	_li: .asciiz "li 	"
	
	_lw: .asciiz "lw 	"
	_sw: .asciiz "sw 	"
	
	_beq: .asciiz "beq 	"
	_bne: .asciiz "bne 	"
	
	_Halt: .asciiz "Halt 	"
	
.text 

main:
################################################################
#       Solicitando nombre de archivo a decodificar            #
################################################################
#imprimiendo mensaje de solicitud del archivo
	li $v0,4
	la $a0,mensaje1 #imprime el mensaje 1
	syscall

#solicita nombre 
	li $v0,8
	la $a0,nombre  #almacena en nombre el String
	la $a1,80      #el limite de caracteres es 80
	syscall

#recorta el \n del nombre
	li $s0,0                # Set index to 0
remove:
    	lb $a3,nombre($s0)      # carga caracter del index
    	addi $s0,$s0,1          # incrementa index
    	bnez $a3,remove         # loop hasta que el limite sea alcanzado
    	beq $a1,$s0,skip        # no quite \n cuando no este presente
    	subiu $s0,$s0,2         # Backtrack index a '\n'
    	sb $0, nombre($s0)      # agrega el caracter terminal en su posicion
skip:

################################################################
#       Solicitando tipo de sistema operativo a usar           #
################################################################
#impresion de solicitud tipo de S.O.
	li $v0,4
	la $a0,mensaje2     #imprime el mensaje2
	syscall

 	li $v0, 5
 	syscall
	beq $v0,1, else	    #si es windows el tam(buffer) es 10
 	li $t0,9	    #si es unix el tam(buffer) es 9
 	li $t3,0x0a
	j salta
 else:
 	li $t0,10
 	li $t3, 0x0d
 salta:
 	
################################################################
#                 Lectura del Archivo                          #
################################################################	
# Apertura de archivo
open:
	li	$v0, 13		# Open File Syscall
	la	$a0, nombre	# carga el nombre del archivo
	li	$a1, 0		# flag de solo lectura
	li	$a2, 0		# ignorar modo
	syscall
	move	$s4, $v0	# salvar descriptor del archivo

        li $t8,0		#inicializo en cero un contador de palabras decodificadas
	la $s0, buffer	        # $s0 pongo la direccion del buffer	
	la $s1, codigo		# asigno a un registro la etiqueta donde tengo el espacio para la decodificacion
	
# Lectura de Datos
read:
	li	$v0, 14		# Read File Syscall
	move	$a0, $s4	# cargar el descriptor del archivo
	move	$a1, $s0	# carga la direccion del buffer
	move	$a2, $t0        # tamano del buffer
	syscall

	beqz $v0, maquinaVirtual		#si no ha leido todo el archivo vuelve a leer
	
	
################################################################
#                     Decodificacion                           #
################################################################
        li $t9,0		   #inicializo en cero $t9 para recorrer las palabras en la etiqueta codigo
	move $t2, $zero		   #reinicio el registro conversor para dar espacio a la nueva instruccion
convertir:	

	lb $t1,0($s0) 	           #carga byte del buffer
	beq $t1,$t3, almacenaje    #si llego al salto de linea almacena palabra
	blt $t1,0x30, error_ascii  #si es menor a 0x30 es caracter especial
	bgt $t1,0x39, letra        #si el byte es mayor o igual a 0x39 ve a letra
	subi $t1,$t1,0x30          #en caso contrario restale 0x30 y dejalo en $t0	
	sll $t2, $t2, 4            #desplaza 4bytes en $t2 para agregar a la derecha
	add $t2, $t2,$t1	   #agrega a la derecha el caracter convertido
	addi $s0,$s0,1		   #desplaza al siguiente byte a convertir en buffer
	b convertir
letra:  
	blt $t1,0x47, mayuscula	     #si el byte es menor a 0x47 es una letra mayuscula
	blt $t1,0x61, error_ascii    #si es menor a 0x61 es caracter especial
	bgt $t1,0x66, error_ascii    #si es mayor a 0x66 es caracter especial
	subi $t1,$t1,0x57            #resta 0x57 al byte 
	sll $t2, $t2, 4              #desplaza 4 bytes a la derecha para agregar a la izquierda
	add $t2, $t2,$t1	     #agrega el byte convertido a la izquierda
	addi $s0,$s0,1               #desplaza al siguiente byte a convertir en el buffer
	b convertir
	
mayuscula:
	beq $t1,0x40, error_ascii    #si es caracter especial va a impresion de error
	bgt $t1,0x46, error_ascii    #si es caracter especial va a la impresion de error
	subi $t1,$t1,0x37            #Resto 0x37 para dejarlo en su representacion
	sll $t2, $t2, 4              #desplaza 4 bytes a la derecha para agregar el caracter
	add $t2, $t2,$t1	     #agrega a derecha el caracter convertido a izquierda
	addi $s0,$s0,1		     #desplaza al siguiente byte para convertir en buffer
	b convertir
	
almacenaje:
	sw $t2,($s1)		#guarda la palabra decodificada en la etiqueta codigo
	addi $s1,$s1,4		#desplaza a la siguiente posicion en la etiqueta codigo
	subi $s0,$s0,8		#desplazo el buffer 
	addi $t8,$t8,1		#suma un elemento al contador de instrucciones decodificadas
	b read			#leer el siguiente hexadecimal

################################################################
#               Decodificacion de instrucciones                #
################################################################		
maquinaVirtual:

	la $s1, codigo		# etiqueta al espacio donde reposan instrucciones hexadecimales
	sw $s1, ProgramCounter  # PC orientado a recorrer Codigo
	la $s5, registros 	# asigno $s5 para la etiqueta con el espacio a los registros
	la $s6, memoria
	li $t7,1 		# contador de iteraciones
	li $v0, 4
	la $a0, SaltoLinea
	syscall
	
lec_coop:
	lw $s1, ProgramCounter		#cargo en $s1 la primera instruccion
	bge $t7, 2, continua_		#si no es la primera iteracion salta
	subi $s1, $s1, 4		#de lo contrario, manda el PC a la instruccion anterior
	continua_:
	addi $t7, $t7, 1 		#aumenta el contador de iteraciones
	addi $s1, $s1, 4		#aumenta el PC a la siguiente instruccion
	lw $s0, 0($s1)			#cargo en $s0 la instruccion
	sw $s1, ProgramCounter		#almaceno en $s1 la posicion actual del PC
	beqz $s0, imprimir_reg		#si no restan insrucciones, imprime los registros
	la $s4, coopTabla		#cargo la tabla principal a $s4	
	andi $s3, $s0, 0xf0000000 	#tomo los 4 primeros bits del hexadecimal
	srl $s3, $s3 28			#desplazo hacia la derecha 28 espacios 
	sll $s2, $s3 2			#multiplico por 4 para desplazarme en la tabla
	add $t1, $s2, $s4		#al apuntador de la tabla le sumo $s2 posiciones
	lw $t1, 0($t1)			# cargo el contenido de la posicion 0 de $t1
	beq $s3, 0x0, ir_tabla0		
	beq $s3, 0x5, ir_tabla5		#cargo en $s3 el apuntador a la tabla [0/5/6/15]
	beq $s3, 0x6, ir_tabla6		#dependiendo del primer byte del hexadecimal
	beq $s3, 0xf, ir_tabla15	
	
	ir_tabla0:
		la $s4, _coopTabla0	#asigno a $s4 un apuntador al inicio de la Tabla0
		b siguiente		#salto al procedimiento que determinar el tipo de la instruccion
	ir_tabla5:
		la $s4, _coopTabla5	#asigno a $s4 un apuntador al inicio de la Tabla5
		b siguiente		#salto al procedimiento que determinar el tipo de la instruccion
	ir_tabla6:
		la $s4,_coopTabla6	#asigno a $s4 un apuntador al inicio de la Tabla6
		b siguiente		#salto al procedimiento que determinar el tipo de la instruccion
	ir_tabla15:
		la $s4,_coopTabla15	#asigno a $s4 un apuntador al inicio de la Tabla15
		li $s2, 0		
		add $t1, $s2, $s4
		lw $t1, 0($t1)		#cargo la direccion asociada al Coop Halt
		jalr $t1		#ejecuto el procedimiento para el Halt
		

	siguiente:
		andi $s3, $s0, 0x0f000000	#tomo el segundo byte del hexadecimal para moverme con el en la tabla secundaria
		srl $s3, $s3, 24		#desplazo a derecha el byte 
		mul $s2, $s3, 12		#multiplico por 12 el byte pues hay 3 bytes por cada slot de la tabla para obtener la posicion
		add $t1, $s2, $s4		#sumo la posicion con el apuntador al inicio de la tabla
		lw $t1, 0($t1)			#cargo la informacion del tipo de instruccion asociado al coop
		jalr $t1			#ejecuto el procedimiento segun el tipo de funcion que sea
	
_R:
	add $t1, $s2, $s4
	lw $t0, 4($t1)
	andi $t2, $s0,0x000f0000	#mascara para tomar 4bits del num registro fuente 1
	srl $t2, $t2, 16		#desplazo a la derecha el bit y le dejo en $t2
	andi $t3, $s0, 0x0000f000	#mascara para tomar los 4 bits del num registro fuente 2
	srl $t3, $t3, 12		#desplazo a la derecha el bit y le dejo en $t3
	andi $t4, $s0, 0x00f00000	#mascara para tomar los 4 bits del num registro destino
	srl $t4, $t4, 20		#desplazo a la derecha los 4 bits
	andi $t9, $s0 0xff000000	#tomo los 8 primeros bits para determinar el coop
	srl $t9,$t9 24			#desplazo a la derecha los 8 bits
	beq $t9, 0xff, ImpresionHalt	#si estos dos bytes son 0xff, es la instruccion Halt


#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#	
#      impresion de la instruccion de tipoR formato Coop Rd Ra Rb      #
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#

	li $v0, 34
	lw $a0, 0($s1)		#impresion del codigo en hexadecimal de la instruccion
	syscall
	
	li $v0, 4
	la $a0, Tab
	syscall
	
	li $v0, 4
	move $a0, $t0		#impresion del nombre del coop
	syscall
	
	
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t4		#impresion del registro destino en formato $Rd
	syscall
	
	li $v0, 4
	la $a0, Tab
	syscall
	
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t2		#impresion del registro fuente 1 en formato $Ra
	syscall
	
	li $v0, 4
	la $a0, Tab
	syscall
	
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t3		#impresion del registro fuente 2 en formato $Rb
	syscall
	li $v0, 4
	la $a0, SaltoLinea
	syscall
	b jump			#salto a la ejecucion de las funcion asociada a la instruccion


#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#	
#           impresion de la instruccion de Halt del programa           #
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#
	
ImpresionHalt:
	li $v0, 34
	lw $a0, 0($s1)		#impresion del codigo en hexadecimal
	syscall
	
	li $v0, 4
	la $a0, Tab
	syscall
	
	li $v0, 4
	move $a0, $t0		#impresion del nombre del coop
	syscall
	
	li $v0, 4
	la $a0, SaltoLinea
	syscall

jump:			
				
#direccion de la instruccion a ejecutar
	lw $t0, 8($t1)

#argumentos para la ejecucion de la instruccion
	move $a0, $t2	#Registro fuente
	move $a1, $t3	#valor Inmediato
	move $a2, $t4	#Registro Destino
	jalr $t0	#llamado a la funcion
	b lec_coop
	
_I:
	add $t1, $s2, $s4
	lw $t0, 4($t1)			#direccion nombre de la instruccion actual	
	andi $t5, $s0, 0x000f0000	#mascara para tomar los 4bytes del registro base
	srl $t5, $t5, 16 		#desplazo a la derecha los 4bytes y los dejo en $t5
	andi $t4, $s0, 0x00f00000	#mascara pata tomar los 4bytes del registro destino
	srl $t4, $t4, 20 		#desplazo a la derecha los 4bytes y los dejo en $t4
	andi $t6, $s0, 0x0000ffff	#tomo los 16bits del Inmediato y lo dejo en $t6

	andi $t9, $s0, 0xff000000		#uso una mascara para tomar los dos primeros bits de la instruccion
	srl $t9, $t9 24				#desplazo los dos bits a la derecha
	beq $t9, 0x59, impresionRdInm
	beq $t9, 0x5a, impresionRdInm
	beq $t9, 0x60, impresionRdInmRa		#dependiendo de la instruccion dada selecciona
	beq $t9, 0x61, impresionRdInmRa		#el metodo de impresion del tipo I
	beq $t9, 0x62, impresionRdRa
	beq $t9, 0x63, impresionRdRa
	
	
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_#	
#  Impresion en el formato Coop Rd, Ra, Inm   #
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_#

	li $v0, 34
	lw $a0, 0($s1)		#impresion del codigo en hexadecimal
	syscall
	
	li $v0, 4
	la $a0, Tab		#impresion del espacio
	syscall
	
	li $v0, 4
	move $a0, $t0		#impresion de la etiqueta de Coop
	syscall
	
	
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t4		#impresion del registro destino en formato: $Rd
	syscall
	
	li $v0, 4
	la $a0, Tab		#impresion de espacio
	syscall
	
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t5		#impresion registro fuente en formato: $Ra
	syscall
	
	li $v0, 4
	la $a0, Tab		#impresion de espacio
	syscall
	
	blt $t6, 0x8000, positive	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $t6, $t6, 0xffff0000	#completo los bits para ser tomado como negativo
	positive:
	li $v0, 1
	move $a0, $t6		#impresion del inmediato
	syscall
	
	li $v0, 4
	la $a0, SaltoLinea	#impresion salto de linea
	syscall	
	b maquinaTipoI		#salto a la ejecucion de la funcion asociada a la instruccion
	
	
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#	
#   Impresion en el formato Coop Rd, Inm   #
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#

impresionRdInm:

	li $v0, 34
	lw $a0, 0($s1)		#impresion del codigo en hexadecimal
	syscall
	
	li $v0, 4
	la $a0, Tab		#impresion de espacio
	syscall
	
	li $v0, 4
	move $a0, $t0		#impresion del Coop
	syscall
	
	
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t4		#impresion del Registro Destino en formato: $Rd
	syscall
	
	li $v0, 4
	la $a0, Tab		#impresion de espacio
	syscall

	blt $t6, 0x8000, positive1	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $t6, $t6, 0xffff0000	#completo los bits para ser tomado como negativo
	positive1:
	li $v0, 1
	move $a0, $t6		#impresion del Inmediato
	syscall
	
	li $v0, 4
	la $a0, SaltoLinea
	syscall	
	b maquinaTipoI		#salto a la ejecucion de la funcion asociada a la instruccion
	
	
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_#
#   Impresion en formato Coop Rd, Inm(Ra)     #	
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_#

impresionRdInmRa:

	li $v0, 34
	lw $a0, 0($s1)		#impresion del codigo hexadecimal
	syscall
	
	li $v0, 4
	la $a0, Tab		#impresion de espacio
	syscall
	
	li $v0, 4
	move $a0, $t0		#impresion del coop
	syscall
		
	
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t4		#impresion del registro destino en formato: $Rd
	syscall
	
	li $v0, 4
	la $a0, Tab		#impresion de espacio
	syscall	

	blt $t6, 0x8000, positive2	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $t6, $t6, 0xffff0000	#completo los bits para ser tomado como negativo
	positive2:	
	li $v0, 1
	move $a0, $t6 		#impresion del inmediato
	syscall	
	
	li $v0, 4
	la $a0,_parentesisAb
	syscall
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t5		#registro fuente en formato: ($Rd)
	syscall
	li $v0, 4
	la $a0,_parentesisCie
	syscall
	li $v0, 4
	la $a0, SaltoLinea
	syscall	
	b maquinaTipoI		#salto a la funcion asociada a la instruccion
	
	
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_#	
#   impresion formato Coop Rd, Ra   #
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_#

impresionRdRa:
	li $v0, 34
	lw $a0, 0($s1)		#impresion del codigo en hexadecimal
	syscall
	
	li $v0, 4
	la $a0, Tab		#impresion de espacio	
	syscall
	
	li $v0, 4
	move $a0, $t0		#impresion del Coop
	syscall
	
	
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t4		#impresion del registro destino en formato: $Rd
	syscall
	
	li $v0, 4
	la $a0, Tab		#impresion de espacio
	syscall
	
	li $v0, 4
	la $a0, _$
	syscall 
	li $v0, 1
	move $a0, $t5		#impresion del registro fuente en formato: $Ra
	syscall
	li $v0, 4
	la $a0, SaltoLinea
	syscall	

maquinaTipoI:
#direccion de la instruccion a ejecutar
	lw $t0, 8($t1)

#argumentos para la ejecucion de la instruccion
	move $a0, $t5
	move $a1, $t6
	move $a2, $t4
	jalr $t0
	b lec_coop
				
			
################################################################
#                Ejecucion de las instrucciones                #
################################################################

#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#
#    instrucciones TipoR       #
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#		
						
__add:
	mul $t1, $a0, 4		#tomo el numero de registro x4 para accesarlo en la etiqueta registro
	add $t1, $t1, $s5	#desplazo el apuntador a la posicion deseada
	lw $t1, 0($t1) 		#contenido del registro fuente 1 asignado a $t1
	mul $t2, $a1, 4
	add $t2, $t2, $s5
	lw $t2, ($t2)		#cargo contenido del registro fuente 2
	mul $t3, $a2, 4
	add $t3, $t3, $s5 	#cargo direccion del registro destino
	add $t4, $t1, $t2
	sw $t4, ($t3)		#almaceno el resultado en el registro destino
	jr $ra			#ejecucion de la instruccion
__sub:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1)		#cargo contenido del registro fuente 1
	mul $t2, $a1, 4
	add $t2, $t2, $s5
	lw $t2, ($t2) 		#cargo contenido del registro fuente 2
	mul $t3, $a2, 4
	add $t3, $t3, $s5 	#cargo direccion del registro destino
	sub $t4, $t1, $t2
	sw $t4, ($t3)		#almaceno el resultado en el registro destino
	jr $ra			#ejecucion de la instruccion
__slt:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 		#cargo contenido del registro fuente 1
	mul $t2, $a1, 4
	add $t2, $t2, $s5
	lw $t2, ($t2) 		#cargo contenido del registro fuente 2
	mul $t3, $a2, 4
	add $t3, $t3, $s5 	#cargo direccion del registro destino
	slt $t4, $t1, $t2
	sw $t4, ($t3)		#almaceno el resultado en el registro destino
	jr $ra			#ejecucion de la instruccion
__and:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 		#cargo contenido del registro fuente 1
	mul $t2, $a1, 4
	add $t2, $t2, $s5
	lw $t2, ($t2) 		#cargo contenido del registro fuente 2
	mul $t3, $a2, 4
	add $t3, $t3, $s5 	#cargo  direccion del registro destino
	and $t4, $t1, $t2
	sw $t4, ($t3)		#almaceno el resultado en el registro destino
	jr $ra			#ejecucion de la instruccion
__or:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 		#cargo contenido del registro fuente 1
	mul $t2, $a1, 4
	add $t2, $t2, $s5
	lw $t2, ($t2) 		#cargo contenido del registro fuente 2
	mul $t3, $a2, 4
	add $t3, $t3, $s5 	#cargo direccion del registro destino
	or $t4, $t1, $t2
	sw $t4, ($t3)		#guardo el resultado en el registro destino
	jr $ra			#ejecucion de la instruccion
__xor:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 		#cargo contenido del registro fuente 1
	mul $t2, $a1, 4
	add $t2, $t2, $s5
	lw $t2, ($t2) 		#cargo contenido del registro fuente 2
	mul $t3, $a2, 4
	add $t3, $t3, $s5 	#cargo direccion del registro destino
	xor $t4, $t1, $t2
	sw $t4, ($t3)		#almaceno el resultado en el registro destino
	jr $ra			#ejecucion de la instruccion


#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#
#    instrucciones TipoI       #
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#	
	
__addi:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1)			#cargo contenido del registro base
	blt $a1, 0x8000, positivo	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $a1, $a1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivo:			#si es menor, es positivo
	add $t2, $t1, $a1 		#ejecucion de la funcion
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del registro destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__slti:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro base
	blt $a1, 0x8000, positivo2	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $a1, $a1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivo2:			#si es menor, es positivo
	slt $t2, $t1, $a1		#ejecucion de la funcion
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del registro destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__andi:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro base
	blt $a1, 0x8000, positivo3	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $a1, $a1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivo3:			#si es menor, es positivo
	and $t2, $t1, $a1		#ejecucion de la funcion
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del registro destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra	
__ori:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro base
	blt $a1, 0x8000, positivo4	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $a1, $a1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivo4:			#si es menor, es positivo
	or $t2, $t1, $a1		#ejecucion de la funcion
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del registro destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra	
__xori:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro base
	blt $a1, 0x8000, positivo5	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $a1, $a1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivo5:			#si es menor, es positivo
	xor $t2, $t1, $a1		#ejecucion de la funcion
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del registro destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__sll:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro fuente
	sllv $t2, $t1, $a1
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__srl: 
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro fuente
	srlv $t2, $t1, $a1
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__sra:  
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro fuente
	srav $t2, $t1, $a1
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__ror:  
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro fuente
	ror $t2, $t1, $a1
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__lui: 

	addi $t1, $a1,0
	blt $t1, 0x8000, positivo6	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $t1, $t1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivo6:			#si es menor, es positivo
	sll $t1,$t1, 16			#ejecucion de la funcion
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del registro destino
	sw $t1, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__li: 
	addi $t1,$a1,0
	blt $t1, 0x8000, positivo7	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $t1, $t1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivo7:			#si es menor, es positivo
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del registro destino
	sw $t1, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__lw:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro base
	blt $a1, 0x8000, positivo8	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $a1, $a1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivo8:			#si es menor, es positivo
	add $t1,$t1, $a1		#cargo Inmediato	
	add $t1, $t1, $s6
	lw $t2, ($t1)
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del registro destino
	sw $t2, ($t3)			#almacenamiento de resultado en Rd
	jr $ra
__sw:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del registro fuente
	blt $a1, 0x8000, positivo9	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $a1, $a1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivo9:			#si es menor, es positivo
	add $t1, $t1, $a1
	mul $t3, $a2, 4
	add $t3, $t3, $s5 		#cargo direccion del registro destino
	lw $t3, ($t3)
	add $t1, $t1, $s6 		#cargo direccion del destino
	sw $t3, ($t1)			#almacenamiento de resultado en memoria
	jr $ra
__beq:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1) 			#cargo contenido del rs
	mul $t2, $a2, 4
	add $t2, $t2, $s5
	lw $t2, ($t2) 			#cargo contenido del rt
	blt $a1, 0x8000, positivoA	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $a1, $a1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivoA:			#si es menor, es positivo
	#mul $t3, $a1, 4 		#desplazamiento
	bne $t1, $t2, salta_beq 	#comparacion
	lw $t0, ProgramCounter
	add $t0, $t0, $a1
	sub $t0, $t0, 4
	sw $t0, ProgramCounter 
	salta_beq:
	jr $ra	
__bne:
	mul $t1, $a0, 4
	add $t1, $t1, $s5
	lw $t1, ($t1)	 		#cargo contenido del rs
	mul $t2, $a2, 4
	add $t2, $t2, $s5
	lw $t2, ($t2) 			#cargo contenido del rt
	blt $a1, 0x8000, positivoB	#si el Inm es mayor o igual que 0x8000 es negativo
	ori $a1, $a1, 0xffff0000	#completo los bits para ser tomado como negativo
	positivoB:			#si es menor, es positivo
	#mul $t3, $a1, 4 		#desplazamiento
	beq $t1, $t2, salta_bne 	#comparacion
	lw $t0, ProgramCounter
	add $t0, $t0, $a1
	sub $t0, $t0, 4
	sw $t0, ProgramCounter
	salta_bne:
	jr $ra

		
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#
#    instruccion Halt TipoR    #
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-#
	
__Halt:
	b imprimir_reg		#salto a la impresion de registros
	
	
	
################################################################
#                   Impresion de Registros                     #
################################################################
	
#*****Planificacion de registros*****#

#$t0 ProgramCounter
#t1 cantidad de registros
#s0 direccion de los registros en memoria
#$t3 registro actual

 imprimir_reg:

	li $t0, 0		#inicializo el contador en cero para el ciclo
	li $t1, 16		#impresion de 16 registros
	la $s0, registros	#cargo el apuntador a la primera posicion del espacio asignado a los registros
	
	li $v0, 4
	la $a0, SaltoLinea	#impresion de salto de linea
	syscall
	
	
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_#
# impresion de registros en el formato:				#
# 	registro N:	valorHexadecimal	valorDecimal	#
#_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_#
ciclo:

	beq $t0, $t1, pass	#si ya imprimio todos los registros, termina el programa
	mul $t3, $t0, 4		#me desplazo de palabra en palabra (4bits) para la impresion de los registros
	add $t3, $t3, $s0	#muevo el apuntador a la posicion de desplazamiento
	lw $t3, ($t3)		#cargo en $t3 la palabra en esa posicion

	li $v0, 4
	la $a0, _registro	#impresion de la palabra "registro"
	syscall
	
	li $v0, 1
	move $a0, $t0		#impresion del numero de registro
	syscall
	
	li $v0, 4
	la $a0, _dospuntos	#impresion de, << : +"/t" >>
	syscall


	li $v0, 34
	move $a0, $t3		#impresion del valor contenido en el registro [contador] en hexadecimal
	syscall

	li $v0, 4
	la $a0, Tab		#impresion de espacio
	syscall
			
	li $v0, 1
	move $a0, $t3		#impresion del valor contenido en el registro[contador] en decimal
	syscall

	li $v0, 4
	la $a0, SaltoLinea
	syscall

	addi $t0, $t0, 1	#aumento una unidad al contador
	b ciclo	
	
			
error_ascii:
	beqz $t8,pass		#si ya no quedan palabras por imprimir termina el programa
	li $v0, 4
	la $a0, SaltoLinea
	syscall
	li $v0,4
	la $a0, mensaje3	#imprime el mensaje de error:caracter especial
	syscall
	li $v0, 4
	la $a0, SaltoLinea
	syscall
pass:


li $v0,10
syscall	

#FIN