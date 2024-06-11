# Trabajo Final para la materia Microarquitecturas y Softcores CESE 20Co - 2024

## IP Sumador punto flotante 32bits y 64bits

El repositorio implementa el IP de un bloque sumador punto flotante floatpoint_adder.vhd. Este sumador realiza la suma en precisión simple (32 bits) o precisión doble (64 bits) de dos números.

El bloque tiene las siguientes entradas:
a y b: números a sumar.
clk.
rst. 
start_i : start_i en 1 indica que se quiere realizar la suma de a con b. 

El bloque tiene las siguientes salidas:
done_o : indica que se realizó la suma y el resultado en s_o es válido.
s_o: resultado de la suma a + b.

Para realizar la suma, se deben introducir los números a sumar en formato punto flotante en las entradas a_i y b_i y luego dar un pulso en start_i. El resultado estará en s_o y solo será válido cuando la salida done_o esté en alto.

## Documento Documento_trabajo_práctico final_Sumador_punto_flotante.pdf
En el documento Documento_trabajo_práctico final_Sumador_punto_flotante.pdf se encuentra una descripción más detallada de la implementación

## Diapositivas
En el siguiente link se encuentra la presentación del sumador punto flotante: 
https://docs.google.com/presentation/d/15Og9U5eTDuLkyrA93w9BFtNq9QRBJUgmZXc6gR_X48U/edit#slide=id.p

##Esquematico y simulaciones
schematic_float_adder.pdf se encuentra el esquematico RTL del sumador punto flotante y simulacion1.png, simulacion2.png, simulacion3.png son capturas de las simulaciones descriptas en el documento.
