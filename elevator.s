.global _start
.equ S, 0x100000
tab_etage: 		.int 0b0111111, 0b0000110, 0b1011011, 0b1001111, 0b1100110, 0b1101101, 0b1111101, 0b0000111, 0b1111111, 0b1101111 
.align

wait1:			stmfd sp!, {r0, lr}
				mov r0, #0
tq1:			cmp r0, #S
				beq finWait1
				add r0, r0, #1
				b tq1
finWait1:		ldmfd sp!, {r0, pc}

@ param entree: r0: nombre de secondes à attendre
wait:			stmfd sp!, {r1, lr}
				mov r1, #0
tq2:			cmp r1, r0
				beq finWait
				bl wait1
				add r1, r1, #1
				b tq2
finWait:		ldmfd sp!, {r1, pc}

ouvrir_porte:	stmfd sp!, {r0-r1, lr}
				ldr r0, =0xff200000 
				ldr r1, =0b1111111111
				str r1, [r0]
				bl wait1
				
				ldr r1, =0b1111001111
				str r1, [r0]
				bl wait1
				
				ldr r1, =0b1110000111
				str r1, [r0]
				bl wait1
				
				ldr r1, =0b1100000011
				str r1, [r0]
				bl wait1
				
				ldr r1, =0b1000000001
				str r1, [r0]				
finOuverture:	ldmfd sp!, {r0-r1, pc}

fermer_porte:	stmfd sp!, {r0-r1, lr}
				ldr r0, =0xff200000 
				ldr r1, =0b1000000001
				str r1, [r0]
				bl wait1
				
				ldr r1, =0b1100000011
				str r1, [r0]
				bl wait1
				
				ldr r1, =0b1110000111
				str r1, [r0]
				bl wait1
				
				ldr r1, =0b1111001111
				str r1, [r0]
				bl wait1
				
				ldr r1, =0b1111111111
				str r1, [r0]				
finFermeture:	ldmfd sp!, {r0-r1, pc}

@ param entree: r0=numero etage
affiche_etage:	stmfd sp!, {r1-r3, lr}
				adr r1, tab_etage
				ldr r2, [r1, r0, lsl #2]
				ldr r3, =0xff200020
				str r2, [r3]
				ldmfd sp!, {r1-r3, pc}

@ param entree: r0=mouvement -> 0: arret, 1: montee, 2: descente
affiche_mouv:	stmfd sp!, {r1-r2,lr}
				ldr r1, =0xff200030
				cmp r0, #1
				beq montee
				cmp r0, #2
				beq descente
arret:			ldr r2, =0b000000000000000
				b finMouv
montee:			ldr r2, =0b010001100000000
				b finMouv
descente:		ldr r2, =0b001110000000000
finMouv:		str r2, [r1]
				ldmfd sp!, {r1-r2,pc}

@ param sortie: r2 contient le numero de l'etage appuyé
lire_boutons:	stmfd sp!, {r1, r3, r5, lr}
				ldr r1, =0xff20005c			@ permet de regarder le edge bits plutôt que l'état courant, pour ne pas rater des appuies
				ldr r2, [r1]
				and r5, r2, #0b0001
				cmp r5, #0b0001
				beq et0
				and r5, r2, #0b0010
				cmp r2, #0b0010
				beq et1
				and r5, r2, #0b0100
				cmp r2, #0b0100
				beq et2
				and r5, r2, #0b1000
				cmp r2, #0b1000
				beq et3
				mov r2, r4
				mov r3, #0b1111
				b fin_lecture
et0:			mov r2, #0
				mov r3, #0b0001
				b fin_lecture
et1:			mov r2, #1
				mov r3, #0b0010
				b fin_lecture
et2:			mov r2, #2
				mov r3, #0b0100
				b fin_lecture
et3:			mov r2, #3
				mov r3, #0b1000
fin_lecture:	
				str r3, [r1]
				ldmfd sp!, {r1, r3, r5, pc}
				
_start: 		mov r0, #0
				bl affiche_mouv
				mov r0, #0			
				bl affiche_etage
				bl fermer_porte
				@ position départ
				mov r4, #0 				@ etage actuel
				
bcl:			bl lire_boutons
				cmp r2, r4
				movhi r0, #1
				movlo r0, #2
				beq pas_bouger
				bl affiche_mouv
				subhi r0, r2, r1		@ attend en seconde le nombre d'etage à parcourir 
				sublo r0, r1, r2
				bl wait
				mov r0, r2
				bl affiche_etage
				bl ouvrir_porte
				bl fermer_porte
				mov r4, r0
				b bcl
				
pas_bouger:		mov r0, #0
				bl affiche_mouv
				b bcl
							
end: 			b end