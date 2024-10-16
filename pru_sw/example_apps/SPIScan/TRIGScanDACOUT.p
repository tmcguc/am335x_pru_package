//*=======================================================================================
//*Mighty EBIC Scan control
//* Copyright Ephemeron labs
//* Written by Terrence McGuckin
//* For Ephemeron Labs Inc.
//* See PYSPI for how to get configurations for SPI modes
//*========================================================================================





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
    // SPI1 is the master aka HighLander
    MOV addr, CM_PER_SPI1_CLK_CTRL
    MOV val, CM_PER_SPI1_CLK_EN
    SBBO val, addr, 0, 4

    //enable clk for SPI0
    MOV addr, CM_PER_SPI0_CLK_CTRL
    MOV val, CM_PER_SPI0_CLK_EN
    SBBO val, addr, 0, 4
   


    // reset spi1
    MOV addr, MCSPI1 | MCSPI_SYSCONFIG
    LBBO val, addr, 0, 4
    SET val.t1
    SBBO val, addr, 0, 4
//
////check if reset is done
CHECKRESET:
    MOV addr, MCSPI1 | MCSPI_SYSSTATUS
    LBBO val, addr, 0, 4
    QBBC CHECKRESET, val.t0


    // reset spi0
    MOV addr, MCSPI0 | MCSPI_SYSCONFIG
    LBBO val, addr, 0, 4
    SET val.t1
    SBBO val, addr, 0, 4
//
////check if reset is done
CHECKRESET2:
    MOV addr, MCSPI0 | MCSPI_SYSSTATUS
    LBBO val, addr, 0, 4
    QBBC CHECKRESET2, val.t0


// Need to initialize ADC always do this on power up first conversion
JMP ADCRESET
RADCRESET:



PASSVALUES:
LBCO Sx, CONST_PRUDRAM, 0, 4

LBCO Sy, CONST_PRUDRAM, 4, 4

LBCO sdx, CONST_PRUDRAM, 8, 4

LBCO sdy, CONST_PRUDRAM, 12, 4

LBCO dx, CONST_PRUDRAM, 16, 4

LBCO dy, CONST_PRUDRAM, 20, 4

LBCO pF, CONST_PRUDRAM, 24, 4

LBCO sF, CONST_PRUDRAM, 28, 4

LBCO samp, CONST_PRUDRAM, 32, 4

LBCO CH, CONST_PRUDRAM, 36, 4

LBCO DVAR, CONST_PRUDRAM, 40, 4

LBCO OS, CONST_PRUDRAM, 44, 4

LBCO XFER, CONST_PRUDRAM, 48, 4

SETUPOS:
    //Set up Over Sampling


    MOV val, 1 << OS_2 | 1 << OS_1 | 1 << OS_0
    MOV addr, GPIO2 | GPIO_CLEARDATAOUT
    SBBO val, addr, 0, 4

    MOV addr, GPIO2 | GPIO_SETDATAOUT
    SBBO OS, addr, 0, 4
   




SETUPADCM:
    
    // setAndCheckReg(MCSPI_MODULCTRL, spimem, MODCONTROL, name = "MCSPI_MODULCTRL")
    MOV addr, MCSPI1 |  MCSPI_MODULCTRL
    MOV val, MODCONTROL
    SBBO val, addr , 0, 4

    MOV  addr, MCSPI1 |  MCSPI_SYSCONFIG
    MOV  val, ADC_SYSCONFIG
    SBBO val, addr, 0, 4

    //reset interrupt status bits write all ones
    MOV addr, MCSPI1 |  MCSPI_IRQSTATUS
    MOV val, RESET_IRQ_STAT 
    SBBO val, addr, 0, 4

    //enable interupts for ADCs
    MOV addr, MCSPI1 | MCSPI_IRQENABLE
    MOV val, ADC_IRQENABLE
    SBBO val, addr, 0, 4
    
    //disable channel
    MOV addr, MCSPI1 |  MCSPI_CH0CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4

    // configure the channel 
    MOV addr, MCSPI1 |  MCSPI_CH0CONF     
    MOV val, ADC_MASTER_CONF
    SBBO val, addr, 0, 4


    //TODO XFER level will be determined from passed values
    // set xfer level
    MOV addr, MCSPI1 | MCSPI_XFERLEVEL
    MOV val, ADC_MASTER_XFER
    SBBO val, addr, 0, 4
    

SETUPADCS:

    MOV addr, MCSPI0 |  MCSPI_MODULCTRL
    MOV val, ADC_SLAVE_MODCONTROL
    SBBO val, addr , 0, 4

    
    MOV  addr, MCSPI0 |  MCSPI_SYSCONFIG
    MOV  val, ADC_SYSCONFIG
    SBBO val, addr, 0, 4


    //reset interrupt status bits write all ones
    MOV addr, MCSPI0 |  MCSPI_IRQSTATUS
    MOV val, RESET_IRQ_STAT 
    SBBO val, addr, 0, 4


    //enable interupts for ADCs
    MOV addr, MCSPI0 | MCSPI_IRQENABLE
    MOV val, ADC_IRQENABLE
    SBBO val, addr, 0, 4
    

    //disable channel
    MOV addr, MCSPI0 |  MCSPI_CH0CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4

    // configure the channel 
    MOV addr, MCSPI0 |  MCSPI_CH0CONF     
    MOV val, ADC_SLAVE_CONF
    SBBO val, addr, 0, 4


    //TODO: XFER level will be determined from passed values
    // set xfer level
    MOV addr, MCSPI0 | MCSPI_XFERLEVEL
    //MOV XFER
    SBBO XFER, addr, 0, 4



SETUPDAC:
    

    //disable channel
    MOV addr, MCSPI1 |  MCSPI_CH1CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4

    // configure the channel 
    MOV addr, MCSPI1 |  MCSPI_CH1CONF     
    MOV val, DAC_MASTER_CONF
    SBBO val, addr, 0, 4


SETUPTRIG:
    SET r30.t5              //MOV r30, 1 << 5  go high make sure output is high

//DAC TEST 
//TESTDAC:
//    JMP DACUPDATE
//TRDACUPDATE:


//Test loop
TESTLOOP:
    JMP LOOP1
RTESTLOOP:


//TESTADC:
//    JMP ENABLEADC
//RTEST_ENABLEADC:

//    JMP ADCREAD
//RTEST_ADCREAD:

//    SET r30.t14             //MOV r30, 1 << 14  go high make sure output is high
//    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
//    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
//    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
//    SET r30.t14             //MOV r30, 1 << 14  go high make sure output is high



    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16

HALT







// * =======================================================
// *  This is where we define the scanning functionality !!!
// * =======================================================

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
    JMP DACUPDATE          // Enabled for TRIG ScanTesing write out values to DACs not needed in Trigger Scan
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
// Add in The Trigger Functionality
    CLR r30.t5              //MOV r30, 0 << 5  go low  to make sure output is low for dummy trigger
    WBC r31.t14             // wait until this bit is clear !! TRIGGER MODE
    SET r30.t5              //MOV r30, 1 << 5  go high make sure output is high for dummy trigger
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
   
 
//*=============================================================
//*This is where we are defining the DAC functionality !!!!
//*=============================================================



DACUPDATE:
    JMP ENABLEDAC          // Enable the DAC SPI channels TODO: need to write seperate ENABLE DAC 
RENABLEDAC:
    MOV DACA, INIT_DACA
    MOV DACB, INIT_DACB
    OR DACA, Fx.w0, DACA    // This takes the position Fx and adds the prefix for the DAC to go to DACA 
    OR DACB, Fy.w0, DACB    // Same thing for DACB

    MOV addr, MCSPI1 | MCSPI_TX1     //TODO: make sure this is going to the right peripheral Should be MCSPI_TX1
    SBBO DACA, addr,0,4     //send out the data to DACA Yo

CHECKTXSA:
    MOV addr, MCSPI1 |  MCSPI_CH1STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSA, val.t1

    MOV addr, MCSPI1 | MCSPI_TX1     //TODO: make sure this is going to the right peripheral Should be MCSPI_TX1
    SBBO DACB, addr,0,4     //send out the data to DACB Yo

CHECKTXSB:
    MOV addr, MCSPI1 |  MCSPI_CH1STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSB, val.t1


    JMP LOADDAC            //TODO: write separate LOADDAC function need to determine right GPIOS
RLOADDAC:
    JMP DISABLEDAC         //TODO: write DAISABLEDAC function
RDISABLEDAC:
    JMP DELAYSET           //TODO: need to include a seperate delay that allows sample to reach steady state before measurement
RDELAYSET:
    JMP DELAY_VAR
RDELAY_VAR:
    JMP RDACUPDATE


LOADDAC:
    JMP DELAY
RDELAY:
    MOV val, 0xac           // need a dealy of 1.7 us before we take pulse LDAC  low
DELAYLOADDAC:
    SUB val, val, 1
    QBNE DELAYLOADDAC , val , 0
    SET r30.t14             //MOV r30, 1 << 14  go high make sure output is high
    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
    CLR r30.t14             //MOV r30, 0 << 14       // pulse low
    SET r30.t14             //MOV r30, 1 << 14  go high make sure output is high
    JMP RLOADDAC               


ENABLEDAC:
    MOV addr, MCSPI1 |  MCSPI_CH1CTRL
    MOV val, EN_CH
    SBBO val, addr, 0, 4
    /// Took this from CHECKTXSDAC
CHECKTXSDAC:
    MOV addr, MCSPI1 |  MCSPI_CH1STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSDAC, val.t1
    JMP RENABLEDAC


DISABLEDAC:
    MOV addr, MCSPI1 | MCSPI_CH1CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4
    JMP RDISABLEDAC

//*=======================================================
//* DELAY Routines
//*=======================================================


// Fixed Delay before loading values from register into DAC
DELAY:
    MOV r24, 0x96  //Test to delay LDAC until CS goes high
DELAY0:
    SUB r24, r24, 1
    QBNE DELAY0 , r24, 0
    JMP RDELAY


//Variable Delay user defined
DELAY_VAR:
    MOV r25, DVAR
DELAY2L:
    SUB r25, r25, 1
    QBNE DELAY2L, r25, 0
    JMP RDELAY_VAR


//Minimum delay before sampling ADCs
DELAYSET:
    MOV r24, 0xc8  // 2us delay for DAC settling time  for 512 step size
DELAYSET0:
    SUB r24, r24, 1
    QBNE DELAYSET0 , r24, 0
    JMP RDELAYSET


//*================================================================
//* ADC functions
//*================================================================



ADCREAD:
    JMP CONVERT
RCONVERT:
    JMP WAITBUSY // wait for adc to finish convert
RWB:        //Return location for WaitBUSY
    MOV CHc, CH // this is just a test value  TODO:need to init CH with value that is passed from memory
    //MOV val, CH // delay scales for each channel
READCH:
    JMP SPI0TX
RSPI0TX:
    SUB CHc, CHc, 1   
    QBNE READCH, CHc, 0     // keep on sending tx and reading into rx SPI0 slave unitl we got all of the channels
    //ADD in Delay here so we don't move faster than SPI can send out data
    MOV CHc, CH   // for each channel delay set time
READ_DELAY:
    SUB CHc, CHc, 1
    MOV val , 0x82    
READ_DELAY_LOOP:
    SUB val, val, 1
    QBNE READ_DELAY_LOOP, val, 0
    QBNE READ_DELAY, CHc, 0     // keep delaying until we got all of the channels, this is a minimum delay

    JMP RADCREAD
    //JMP RTEST_ADCREAD



ENABLEADC:
    MOV addr, MCSPI1 | MCSPI_CH0CTRL
    MOV val, EN_CH
    SBBO val, addr, 0, 4
CHECKTXMADC:
    MOV addr, MCSPI1 | MCSPI_CH0STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXMADC, val.t1
//Need to explictly enable Slave as well
    MOV addr, MCSPI0 | MCSPI_CH0CTRL
    MOV val, EN_CH
    SBBO val, addr, 0, 4
CHECKTXSADC:
    MOV addr, MCSPI0 | MCSPI_CH0STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSADC, val.t1
    JMP RENABLEADC
    //JMP RTEST_ENABLEADC


DISABLEADC:
    MOV addr, MCSPI1 | MCSPI_CH0CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4

    MOV addr, MCSPI0 | MCSPI_CH0CTRL
    MOV val, DIS_CH
    SBBO val, addr, 0 ,4

    JMP RDISABLEADC






SPI0TX:
    MOV addr, MCSPI1 |  MCSPI_TX0
    MOV val, 0x00000000     // Send DUMMY data only need to supply clock and cs to recieve on slave channel
    SBBO val, addr,0,4
    JMP RSPI0TX


ADCRESET:
    MOV val, 0x6            // need minmum pulse high of 50ns for reset
    SET r30.t7              //MOV r30, 1 << 7
RESETCOUNT:
    SUB val, val, 1
    QBNE RESETCOUNT, val, 0
    CLR r30.t7              //MOV r30, 0 << 7
    JMP RADCRESET


CONVERT:
    MOV val, 0x3        // need pulse low for convert signal of at least 25 ns
    CLR r30.t15         //MOV r30, 0 << 15
CONCOUNT:
    SUB val, val, 1
    QBNE CONCOUNT, val, 0
    SET r30.t15         //MOV r30, 1 << 15
    JMP RCONVERT


WAITBUSY:
    MOV val, 0x5        // wait for at least 40 ns to make surte BUSY signal latches
DELAYBUSY:
    SUB val, val, 1
    QBNE DELAYBUSY, val, 0
    WBS r31.t15         // wait till goes high
    WBC r31.t15         // wait until this bit is clear !!
    JMP RWB
    
    




