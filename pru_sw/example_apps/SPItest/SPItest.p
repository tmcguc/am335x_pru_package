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

    // reset spi
    MOV r14, MCSPI1 | MCSPI_SYSCONFIG
    LBBO r15, r14, 0, 4
    SET r15, 1
    SBBO r15, r14, 0, 4

//check if reset is done
CHECKRESET:
    MOV r16, MCSPI1 | MCSPI_SYSSTATUS
    LBBO r17, r16, 0, 4
    QBBC CHECKRESET, r17.t0



CONFIG:

    
    MOV r19, MCSPI1 | MCSPI_MODULCTRL
    MOV r20, MODCONTROL
    LBBO r19, r20 , 0, 4

    MOV  r18, ADC_SYSCONFIG
    SBBO r18, r14, 0, 4

    //reset interrupt status bits write all ones
    MOV r4, RESET_IRQ_STAT 
    MOV r5, MCSPI1 | MCSPI_IRQSTATUS
    SBBO r4, r5, 0, 4

    //enable interupts for ADCs
    MOV r21, MCSPI1 | MCSPI_IRQENABLE
    MOV r22, ADC_IRQENABLE
    SBBO r22, r21, 0, 4
    
    // configure the channel 
    MOV r6, ADC_TX_CH_CONF
    MOV r7, MCSPI1 | MCSPI_CH0CONF     
    SBBO r6, r7, 0, 4

    
    //enable channel
    MOV r8, MCSPI1 | MCSPI_CH0CTRL
    MOV r11, EN_CH
    SBBO r11, r8, 0, 4

CHECKTXS:
    MOV r23, MCSPI1 | MCSPI_CH0STAT
    LBBO r24, r23, 0, 4
    QBBC CHECKTXS, r24.t1


    //write to spi tx register
    MOV r9, TEST_PATT
    MOV r10 , MCSPI1 | MCSPI_TX0
    SBBO r9, r10,0,4


    //spi reset enable
    MOV r11, DIS_CH
    SBBO r11, r8, 0, 4
    //CLR r8.t0
    








//#ifdef AM33XX
    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16
//#else
//    MOV R31.b0, PRU0_ARM_INTERRUPT
//#endif

HALT
