.origin 0
.entrypoint START
#include "SPIScan.hp"


START:
// Enable OCP master port
    LBCO r0, C4, 4, 4
    CLR r0, r0, 4
    SBCO r0, C4, 4, 4



SETUP:
    // setAndCheckReg(CM_PER_SPI1_CLK_CTRL, Cmem, 0x2, name = "CM_PER_SPI1_CLK_CTRL")
    //enable clkspiref and clk
    MOV addr, CM_PER_SPI1_CLK_CTRL
    MOV val, CM_PER_SPI1_CLK_EN
    SBBO val, addr, 0, 4


    // reset spi
    MOV addr, MCSPI_SYSCONFIG
    LBBO val, addr, 0, 4
    SET val.t1
    SBBO val, addr, 0, 4
//
////check if reset is done
CHECKRESET:
    MOV addr, MCSPI_SYSSTATUS
    LBBO val, addr, 0, 4
    QBBC CHECKRESET, val.t0

CONFIG:

    // setAndCheckReg(MCSPI_MODULCTRL, spimem, MODCONTROL, name = "MCSPI_MODULCTRL")
    MOV addr, MCSPI_MODULCTRL
    MOV val, MODCONTROL
    SBBO val, addr , 0, 4

    
    MOV  addr, MCSPI_SYSCONFIG
    MOV  val, ADC_SYSCONFIG
    SBBO val, addr, 0, 4


    //reset interrupt status bits write all ones
    MOV addr, MCSPI_IRQSTATUS
    MOV val, RESET_IRQ_STAT 
    SBBO val, addr, 0, 4


    //enable interupts for ADCs
    MOV addr, MCSPI_IRQENABLE
    MOV val, ADC_IRQENABLE
    SBBO val, addr, 0, 4
    

    //disable channel
    MOV addr, MCSPI_CH0CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4

    // configure the channel 
    MOV addr, MCSPI_CH0CONF     
    MOV val, ADC_TX_TURBO
    SBBO val, addr, 0, 4

    // set xfer level
    MOV addr, MCSPI_XFERLEVEL
    MOV val, ADC_XFER
    SBBO val, addr, 0, 4
    

    //enable channel
    //MOV addr, MCSPI_CH0CTRL
    //MOV val, EN_CH
    //SBBO val, addr, 0, 4

    //CALL CHECKTXS

    CALL ENABLE


Transfer:

    //write to spi tx register
    MOV addr, MCSPI_TX0
    MOV val, TEST_PATT
    SBBO val, addr,0,4

    MOV addr, MCSPI_TX0
    MOV val, TEST_PATT
    SBBO val, addr,0,4

    MOV addr, MCSPI_TX0
    MOV val, TEST_PATT
    SBBO val, addr,0,4

    MOV addr, MCSPI_TX0
    MOV val, TEST_PATT
    SBBO val, addr,0,4

    MOV addr, MCSPI_TX0
    MOV val, TEST_PATT
    SBBO val, addr,0,4

    MOV addr, MCSPI_TX0
    MOV val, TEST_PATT
    SBBO val, addr,0,4



//#ifdef AM33XX
    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16
//#else
//    MOV R31.b0, PRU0_ARM_INTERRUPT
//#endif

HALT



DELAY:
    MOV r24, 0x10
DELAY0:
    SUB r24, r24, 1
    QBNE DELAY0 , r24, 0
    RET


//Delay2 is nested with Delay 1
DELAY2:
    MOV r25, 0x1
DELAY2L:
    CALL DELAY 
    SUB r25, r25, 1
    QBNE DELAY2L, r25, 0
    RET


CHECKTXS:
    MOV addr, MCSPI_CH0STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXS, val.t1
    RET


ENABLE:
    MOV addr, MCSPI_CH0CTRL
    MOV val, EN_CH
    SBBO val, addr, 0, 4

    CALL CHECKTXS
    RET


// * ===================================================
// *  This is where we define the scanning functionality !!!
// * ===================================================

LOOP1:
    SBBO Sx, Fx, 0, 4       // store Sx in Fx
    SBBO Sy, Fy, 0, 4       // store Sy in Fy 
    Call LOOP2              // LOOP2 is where we call the DAC and ADC subroutines 
    ADD Sx, Sx, sdx         // update Sx 
    ADD Sy, Sy, sdx         // update Sy
    SUB sF, sF, 1           // decrement count
    // TODO: add something here to check if we should stop the scan
    QBNE LOOP1, sF, 0       // check if we are done
    RET


LOOP2:
    MOV pFc, pF             // reintialize fast count value
SUBLOOP2:
    CALL DACUPDATE          // write out values to DACs
    CALL LOOP3              // Loop samples ADCs multiple times
    ADD Fx, Fx, dx          // update Fx, TODO: check if I need to do a MOV first and use another register
    ADD Fy, Fy, dy          // update Fy
    SUB pFc, pFc, 1         // decrement count
    QBNE SUBLOOP2, pFc, 0   // see if we are going to the next line
    RET


LOOP3:
    MOV sampc, samp         // reintialize the how many samples perpoint to take
SUBLOOP3:
    CALL ADCREAD            // read in the ADC values
    SUB sampc, sampc, 1     // update samples per point counter
    QBNE SUBLOOP3, sampc, 0 // see if we go to the next point
    RET
    

