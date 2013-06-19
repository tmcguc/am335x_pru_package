.origin 0
.entrypoint START
#include "SPItest.hp"


START:
// clear that bit
    LBCO r0, C4, 4, 4
    CLR r0, r0, 4
    SBCO r0, C4, 4, 4



SETUP:

    //enable clkspiref and clk
    MOV r1, CM_PER_SPI1_CLK_CTRL
    MOV r2, CM_PER_SPI1_CLK_EN
    SBBO r2, r1, 0, 4

    CALL DELAY


    // reset spi
    MOV r3, MCSPI_SYSCONFIG
    LBBO r4, r3, 0, 4
    SET r4.t1
    SBBO r4, r3, 0, 4

//check if reset is done
CHECKRESET:
    MOV r5, MCSPI_SYSSTATUS
    LBBO r6, r5, 0, 4
    QBBC CHECKRESET, r6.t0



CONFIG:

    
    MOV r7, MCSPI_MODULCTRL
    MOV r8, MODCONTROL
    LBBO r8, r7 , 0, 4

    
    CALL DELAY


    MOV  r9, ADC_SYSCONFIG
    SBBO r9, r3, 0, 4

    CALL DELAY

    //reset interrupt status bits write all ones
    MOV r10, RESET_IRQ_STAT 
    MOV r11, MCSPI_IRQSTATUS
    SBBO r11, r10, 0, 4

    CALL DELAY

    //enable interupts for ADCs
    MOV r12, MCSPI_IRQENABLE
    MOV r13, ADC_IRQENABLE
    SBBO r13, r12, 0, 4
    
    CALL DELAY

    // configure the channel 
    MOV r14, ADC_TX_CH_CONF
    MOV r15, MCSPI_CH0CONF     
    SBBO r15, r14, 0, 4

    CALL DELAY

    //disable channel
    //MOV r16, MCSPI_CH0CTRL
    //MOV r17, DIS_CH
    //SBBO r17, r16, 0 ,4

    CALL DELAY

    MOV r22, MCSPI_XFERLEVEL
    MOV r23, ADC_XFER
    SBBO r23, r22, 0, 4
    
    CALL DELAY

    //enable channel
    MOV r16, MCSPI_CH0CTRL
    MOV r17, EN_CH
    SBBO r17, r16, 0, 4

    CALL DELAY

CHECKTXS:
    MOV r18, MCSPI_CH0STAT
    LBBO r19, r18, 0, 4
    QBBC CHECKTXS, r19.t1


    CALL DELAY

    //write to spi tx register
    MOV r20, TEST_PATT
    MOV r21 , MCSPI_TX0
    SBBO r21, r20,0,4

    CALL DELAY

    SBBO r21, r20,0,4

    CALL DELAY

    SBBO r21, r20,0,4

    CALL DELAY

    SBBO r21, r20,0,4


    CALL DELAY








//#ifdef AM33XX
    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16
//#else
//    MOV R31.b0, PRU0_ARM_INTERRUPT
//#endif

HALT



DELAY:
    MOV r24, 0xfffff
DELAY0:
    SUB r24, r24, 1
    QBNE DELAY0 , r24, 0
    RET 
