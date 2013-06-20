.origin 0
.entrypoint START
#include "SPItest.hp"


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

//    CALL DELAY


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

//
//
CONFIG:

    // setAndCheckReg(MCSPI_MODULCTRL, spimem, MODCONTROL, name = "MCSPI_MODULCTRL")
    MOV addr, MCSPI_MODULCTRL
    MOV val, MODCONTROL
    SBBO val, addr , 0, 4

    
//    CALL DELAY

    MOV  addr, MCSPI_SYSCONFIG
    MOV  val, ADC_SYSCONFIG
    SBBO val, addr, 0, 4

//    CALL DELAY

    //reset interrupt status bits write all ones
    MOV addr, MCSPI_IRQSTATUS
    MOV val, RESET_IRQ_STAT 
    SBBO val, addr, 0, 4

//    CALL DELAY

    //enable interupts for ADCs
    MOV addr, MCSPI_IRQENABLE
    MOV val, ADC_IRQENABLE
    SBBO val, addr, 0, 4
    
//    CALL DELAY

    // configure the channel 
    MOV addr, MCSPI_CH0CONF     
    MOV val, ADC_TX_CH_CONF
    SBBO val, addr, 0, 4

//    CALL DELAY

    //disable channel
    MOV addr, MCSPI_CH0CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4

//    CALL DELAY

    MOV addr, MCSPI_XFERLEVEL
    MOV val, ADC_XFER
    SBBO val, addr, 0, 4
    
//    CALL DELAY

    //enable channel
    MOV addr, MCSPI_CH0CTRL
    MOV val, EN_CH
    SBBO val, addr, 0, 4

//    CALL DELAY
//
CHECKTXS:
    MOV addr, MCSPI_CH0STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXS, val.t1
//
//
//    CALL DELAY

    //write to spi tx register
    MOV addr, MCSPI_TX0
    MOV val, TEST_PATT
    SBBO val, addr,0,4

    //CALL DELAY

    //write to spi tx register
    //MOV addr, MCSPI_TX0
    //MOV val, 0xba98
    //SBBO val, addr,0,4

    //CALL DELAY

    //write to spi tx register
    //MOV addr, MCSPI_TX0
    //MOV val, TEST_PATT
    //SBBO val, addr,0,4

    //CALL DELAY

    //write to spi tx register
    //MOV addr, MCSPI_TX0
    //MOV val, TEST_PATT
    //SBBO val, addr,0,4

    //CALL DELAY



//#ifdef AM33XX
    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16
//#else
//    MOV R31.b0, PRU0_ARM_INTERRUPT
//#endif

HALT



DELAY:
    MOV r24, 0xff
DELAY0:
    SUB r24, r24, 1
    QBNE DELAY0 , r24, 0
    RET 
