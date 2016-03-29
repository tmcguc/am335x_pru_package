.origin 0
.entrypoint START
#include "IV.hp"


START:
// Enable OCP master port
    LBCO r0, C4, 4, 4
    CLR r0, r0, 4
    SBCO r0, C4, 4, 4

PASSVALUES:
LBCO nStep, CONST_PRUDRAM, 0, 4

LBCO pStep, CONST_PRUDRAM, 4, 4

LBCO Count, CONST_PRUDRAM, 8, 4

LBCO Start, CONST_PRUDRAM, 12, 4

LBCO Stop, CONST_PRUDRAM, 16, 4

LBCO Min, CONST_PRUDRAM, 20, 4

LBCO Max, CONST_PRUDRAM, 24, 4

LBCO STEP, CONST_PRUDRAM, 28, 4

LBCO samp, CONST_PRUDRAM, 32, 4

LBCO CH, CONST_PRUDRAM, 36, 4

LBCO DVAR, CONST_PRUDRAM, 40, 4

LBCO OS, CONST_PRUDRAM, 44, 4

LBCO XFER, CONST_PRUDRAM, 48, 4





STIV:
    QBEQ DONE, Stop, Count
    QBEQ SETnSTEP, Max, Count //check to see if we switch step sign
    QBEQ SETpSTEP, Min, Count // check to see if we swicth signs again
RSETnSTEP:
RSETpSTEP:
    ADD V1, V1, STEP // set step value
    SUB Count, Count, 1 //decrement count

//set DACs
//DElay
//Measure ADCs

    JMP STIV //keep on going .....


SETpSTEP:
    MOV STEP, pStep
    JMP RSETpSTEP

SETnSTEP:
    MOV STEP, nStep
    JMP RSETnSTEP

DONE:


//Do something ???



LOOP1:
    MOV Fx, Sx       // store Sx in Fx
    MOV Fy, Sy      // store Sy in Fy 
    
    JMP LOOP2              // LOOP2 is where we call the DAC and ADC subroutines
RLOOP2: 
    ADD Sx, Sx, sdx         // update Sx 
    ADD Sy, Sy, sdy         // update Sy
    SUB sF, sF, 1           // decrement count
    // TODO: add something here to check if we should stop the scan
    QBNE LOOP1, sF, 0       // check if we are done
    JMP RTESTLOOP
    RET


LOOP2:
    MOV pFc, pF             // reintialize fast count value
SUBLOOP2:
    JMP DACUPDATE          // write out values to DACs
RDACUPDATE:
    JMP LOOP3                // Loop samples ADCs multiple times
RLOOP3:
    ADD Fx, Fx, dx          // update Fx, TODO: check if I need to do a MOV first and use another register
    ADD Fy, Fy, dy          // update Fy
    SUB pFc, pFc, 1         // decrement count
    QBNE SUBLOOP2, pFc, 0   // see if we are going to the next line
    //Test to see if we stop
    //report back values
    // Exit if the halt flag is set
   // MOV r6, DMX_HALT
   // LBCO r2, CONST_PRUDRAM, r6, 1
   // QBNE EXIT, r2.b0, 0  //Something like this to check and see if we are done
    JMP RLOOP2






LOOP3:
    MOV sampc, samp         // reintialize the how many samples perpoint to take
    JMP ENABLEADC
RENABLEADC:
SUBLOOP3:
    JMP ADCREAD            // read in the ADC values
RADCREAD:
    SUB sampc, sampc, 1     // update samples per point counter
    QBNE SUBLOOP3, sampc, 0 // see if we go to the next point
    JMP DISABLEADC
RDISABLEADC:
    //JMP TEST
    JMP RLOOP3








