.origin 0
.entrypoint START
#include "SPItest.hp"


START:
// clear that bit
    LBCO r0, C4, 4, 4
    CLR r0, r0, 4
    SBCO r0, C4, 4, 4

    MOV r1, 1000
// 


SETUP:

    //enable clkspiref and clk
    MOV r12, CM_PER_SPI1_CLK_CTRL
    LBBO r13, r12, 0, 4
    SET r13, 1
    SBBO r13, r12, 0, 4


    MOV r14, MCSPI1 | MCSPI_SYSCONFIG
    LBBO r15, r14, 0, 4
    SET r15, 1
    SBBO r15, r14, 0, 4


CHECKRESET:
    MOV r16, MCSPI1 | MCSPI_SYSSTATUS
    LBBO r17, r16, 0, 4
    QBBC CHECKRESET, r17.t0



CONFIG:

    MOV  r18, SYSCONFIG
    SBBO r18, r14, 0, 4
    
    MOV r19, MCSPI1 | MCSPI_MODULCTRL
    MOV r20, MODCONTROL
    LBBO r19, r20 , 0, 4

    //MOV r21, MCSPI1 | MCSPI_WAKEUPENABLE
    //MOV r22, 0x0<<0
    //LBBO r22, r21, 0, 4

    
BLINK:
    MOV r2, 7<<22
    MOV r3, GPIO1 | GPIO_SETDATAOUT
    SBBO r2, r3, 0, 4

   
//reset interrupt status bits write all ones set ssb

    MOV r4, 0x1<<11| SYSTEMREG
    MOV r5, MCSPI1 | MCSPI_SYST
    SBBO r4, r5, 0, 4
    
     
    MOV r6, CH_CONF
    MOV r7, MCSPI1 | MCSPI_CH0CONF     
    SBBO r6, r7, 0, 4

    //enable channel
    MOV r8, MCSPI1 | MCSPI_CH0CTRL
    MOV r11, 0x1
    SBBO r11, r8, 0, 4


    //write to spi tx register
    MOV r9, 0x0f0f0f0f
    MOV r10 , MCSPI1 | MCSPI_TX0
    SBBO r9, r10,0,4


    MOV r0, 0x000f0000
DELAY:
    SUB r0, r0, 1
    QBNE DELAY, r0, 0

    //spi reset enable
    MOV r11, 0x0
    SBBO r11, r8, 0, 4
    //CLR r8.t0
    
    MOV r2, 7<<22
    MOV r3, GPIO1 | GPIO_CLEARDATAOUT
    SBBO r2, r3, 0, 4

    MOV r0, 0x000f0000
DELAY2:
    SUB r0, r0, 1
    QBNE DELAY2, r0, 0

    SUB r1, r1, 1
    QBNE BLINK, r1, 0








//#ifdef AM33XX
    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16
//#else
//    MOV R31.b0, PRU0_ARM_INTERRUPT
//#endif

HALT
