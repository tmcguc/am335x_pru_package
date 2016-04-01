.origin 0
.entrypoint START
#include "IV.hp"


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




STIV:
    QBEQ DONE, Stop, Count
    QBEQ SETnSTEP, Max, Count //check to see if we switch step sign
    QBEQ SETpSTEP, Min, Count // check to see if we swicth signs again
RSETnSTEP:
RSETpSTEP:
    ADD V1, V1, STEP // set step value
    SUB Count, Count, 1 //decrement count   Count down to zero
    JMP DACUPDATE          // write out values to DACs
RDACUPDATE:
    JMP LOOP3                // Loop samples ADCs multiple times
RLOOP3:

    JMP STIV //keep on going .....


DONE:

    MOV R31.b0, PRU0_ARM_INTERRUPT+16

HALT

//Do something ???



//Change Step to negative for down swing
SETpSTEP:
    MOV STEP, pStep
    JMP RSETpSTEP

SETnSTEP:
    MOV STEP, nStep
    JMP RSETnSTEP


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


//*=============================================================
//*This is where we are defining the DAC functionality !!!!
//*=============================================================



DACUPDATE:
    JMP ENABLEDAC          // Enable the DAC SPI channels TODO: need to write seperate ENABLE DAC 
RENABLEDAC:
    MOV DACC, INIT_DACC    //Change from A to C for seting up IV
    //MOV DACD, INIT_DACD     //change from B to D for setting up IV
    OR DACC, V1.w0, DACC    // This takes the position Fx and adds the prefix for the DAC to go to DACC 
    //OR DACD, Fy.w0, DACD    // Same thing for DACD

    MOV addr, MCSPI1 | MCSPI_TX1     //TODO: make sure this is going to the right peripheral Should be MCSPI_TX1
    SBBO DACC, addr,0,4     //send out the data to DACC Yo

CHECKTXSA:
    MOV addr, MCSPI1 |  MCSPI_CH1STAT
    LBBO val, addr, 0, 4
    QBBC CHECKTXSA, val.t1

//    MOV addr, MCSPI1 | MCSPI_TX1     //TODO: make sure this is going to the right peripheral Should be MCSPI_TX1
//    SBBO DACD, addr,0,4     //send out the data to DACB Yo

//CHECKTXSB:
//    MOV addr, MCSPI1 |  MCSPI_CH1STAT
//    LBBO val, addr, 0, 4
//    QBBC CHECKTXSB, val.t1


    JMP LOADDAC            //
RLOADDAC:
    JMP DISABLEDAC         //
RDISABLEDAC:
    JMP DELAYSET           //
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
    
    








