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
    MOV addr, MCSPI_CH0CTRL
    MOV val, EN_CH
    SBBO val, addr, 0, 4

    //CALL CHECKTXS

    //CALL ENABLEADC


    //CALL CONVERT


CHECKTXS:
    MOV addr, MCSPI_CH0STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXS, val.t1


    MOV r30, 1 << 15
    MOV r30, 0 << 15
    MOV r30, 0 << 15
    MOV r30, 0 << 15
    MOV r30, 0 << 15
    MOV r30, 0 << 15       
    MOV r30, 1 << 15

    JMP CONVERT    

Transfer:

    //write to spi tx register
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





// * =======================================================
// *  This is where we define the scanning functionality !!!
// * =======================================================

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
    CALL ENABLEADC
SUBLOOP3:
    CALL ADCREAD            // read in the ADC values
    SUB sampc, sampc, 1     // update samples per point counter
    QBNE SUBLOOP3, sampc, 0 // see if we go to the next point
    CALL DISABLEADC
    RET
    
//*=============================================================
//*This is where we are defining the DAC functionality !!!!
//*=============================================================


DACUPDATE:
    CALL ENABLEDAC          // Enable the DAC SPI channels TODO: need to write seperate ENABLE DAC 
    //OR DACA, Fx.w0, 0b00010000 << 16    // This takes the position Fx and adds the prefix for the DAC to go to DACA 
    //OR DACB, Fy.w0, 0b00010001 << 16    // Same thing for DACB

    MOV addr, MCSPI_TX0     //TODO: make sure this is going to the right peripheral
    SBBO DACA, addr,0,4     //send out the data to DACA Yo
    SBBO DACB, addr,0,4     //send out the data to DACB Yo
    CALL LOADDAC            //TODO: write separate LOADDAC function need to determine right GPIOS
    CALL DISABLEDAC         //TODO: write DAISABLEDAC function
    CALL DELAYSET           //TODO: need to include a seperate delay that allows sample to reacvh steady state before measurement
    RET


LOADDAC:
    MOV val, 0xac           // need a dealy of 1.7 us before we take pulse LDAC  low
DELAYLOADDAC:
    SUB val, val, 1
    QBNE DELAYLOADDAC , val , 0
    SET r30.t14             //MOV r30, 1 << 14  go high make sure output is high
    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
    SET r30.t14             //MOV r30, 1 << 14  go high make sure output is high
    RET


CHECKTXSDAC:
    MOV addr, MCSPI_CH1STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSDAC, val.t1
    RET


ENABLEDAC:
    MOV addr, MCSPI_CH1CTRL
    MOV val, EN_CH
    SBBO val, addr, 0, 4
    JMP CHECKTXSDAC
    RET

DISABLEDAC:
    MOV addr, MCSPI_CH1CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4
    RET


DELAYSET:
    CALL DELAY
    RET


//*================================================================
//* ADC functions
//*================================================================



ADCREAD:
    CALL CONVERT
    //CALL WAITBUSY // Don't need this until we have ADC Board to test!!!
    MOV sampc, 8 // this is just a test value  need to init sampc with value that is passed from memory
    MOV val, sampc
READCH:
    CALL SPI0TX
    SUB val, val ,1    
    QBNE READCH, val, 0     // keep on sending tx and reading into rx SPI0 slave unitl we got all of the channels
    RET


CHECKTXSADC:
    MOV addr, MCSPI_CH0STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSADC, val.t1
    RET


ENABLEADC:
    MOV addr, MCSPI_CH0CTRL
    MOV val, EN_CH
    SBBO val, addr, 0, 4
    JMP CHECKTXSADC
    RET


DISABLEADC:
    MOV addr, MCSPI_CH0CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4
    RET



SPI0TX:
    MOV addr, MCSPI_TX0
    MOV val, 0x00000000     // Send DUMMY data only need to supply clock and cs to recieve on slave channel
    SBBO val, addr,0,4
    RET


ADCRESET:
    MOV val, 0x6            // need minmum pulse high of 50ns for reset
    SET r30.t7              //MOV r30, 1 << 7
RESETCOUNT:
    SUB val, val, 1
    QBNE RESETCOUNT, val, 0
    CLR r30.t7              //MOV r30, 0 << 7
    RET


CONVERT:
    MOV val, 0x3        // need pulse low for convert signal of at least 25 ns
    CLR r30.t15         //MOV r30, 0 << 15
CONCOUNT:
    SUB val, val, 1
    QBNE CONCOUNT, val, 0
    SET r30.t15         //MOV r30, 1 << 15
    JMP Transfer


WAITBUSY:
    MOV val, 0x5        // wait for at least 40 ns to make surte BUSY signal latches
DELAYBUSY:
    SUB val, val, 1
    QBNE DELAYBUSY, val, 0
    WBC r31.t15         // wait until this bit is clear !!
    RET
    
    




