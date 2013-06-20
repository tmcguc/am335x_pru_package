
from mmap import mmap
import time, struct

MCSPI1_offset = 0x481a0000
MCSPI1_size = 0xfff

CM_PER = 0x44E00000

CM_PER_SPI1_CLK_CTRL =  0x50



#TODO: put inside a dictionary or make a object for these offsets 
MCSPI_REVISION      = 0x000
MCSPI_SYSCONFIG     = 0x110
MCSPI_SYSSTATUS     = 0x114
MCSPI_IRQSTATUS     = 0x118
MCSPI_IRQENABLE     = 0x11c
MCSPI_WAKEUPENABLE  = 0x120
MCSPI_SYST          = 0x124
MCSPI_MODULCTRL     = 0x128

MCSPI_XFERLEVEL     = 0x17c
MCSPI_DAFTX         = 0x180   # DMA address aligned FIFO TX register
MCSPI_DAFRX         = 0x1a0   # DMA address aligned FIFO RX register

MCSPI_CH0CONF       = 0x12c
MCSPI_CH0STAT       = 0x130
MCSPI_CH0CTRL       = 0x134
MCSPI_TX0           = 0x138
MCSPI_RX0           = 0x13c

MCSPI_CH1CONF       = 0x140
MCSPI_CH1STAT       = 0x144
MCSPI_CH1CTRL       = 0x148
MCSPI_TX1           = 0x14c
MCSPI_RX1           = 0x150

# This is where we can change the register configuartions values and put them all together

# sysconfig register setup
CLOCKACTIVITY       = 0x3 << 8  # 0x3 ocp and functional clocks maintained
SIDLEMODE           = 0x2 << 3      # 0x1 idle request ignored
AUTOIDLE            = 0x1               # 0x1 automatic ocp clock strategy is applied

SYSCONFIG = 0x0000| CLOCKACTIVITY | SIDLEMODE | AUTOIDLE


WCNT                = 0x4 << 16 # word count for 
AFL                 = 0x0 << 8  #
AEL                 = 0x0       #

XFER = 0x0000| WCNT | AFL |AEL


def setIRQENABLE(EOWKE = 0x0, RX3_FULL_ENABLE = 0x0, TX3_UNDERFLOW_ENABLE = 0x0, TX3_EMPTY_ENABLE = 0x0,
RX2_FULL_ENABLE = 0x0, TX2_UNDERFLOW_ENABLE = 0x0, TX2_EMPTY_ENABLE = 0x0,
RX1_FULL_ENABLE = 0x0, TX1_UNDERFLOW_ENABLE = 0x0, TX1_EMPTY_ENABLE = 0x0,
RX0_OVERFLOW_ENABLE = 0x0, RX0_FULL_ENABLE = 0x0, TX0_UNDERFLOW_ENABLE = 0x0, TX0_EMPTY_ENABLE = 0x0):
    """

    There is an EWOK in the register!!
    """

    vEOWKE                   = EOWKE << 17
    vRX3_FULL_ENABLE         = RX3_FULL_ENABLE << 14
    vTX3_UNDERFLOW_ENABLE    = TX3_UNDERFLOW_ENABLE << 13
    vTX3_EMPTY_ENABLE        = TX3_EMPTY_ENABLE << 12
    vRX2_FULL_ENABLE         = RX2_FULL_ENABLE << 10
    vTX2_UNDERFLOW_ENABLE    = TX2_UNDERFLOW_ENABLE << 9
    vTX2_EMPTY_ENABLE        = TX2_EMPTY_ENABLE << 8
    vRX1_FULL_ENABLE         = RX1_FULL_ENABLE << 6
    vTX1_UNDERFLOW_ENABLE    = TX1_UNDERFLOW_ENABLE << 5
    vTX1_EMPTY_ENABLE        = TX1_EMPTY_ENABLE << 4
    vRX0_OVERFLOWENABLE      = RX0_OVERFLOWENABLE << 3
    vRX0_FULL_ENABLE         = RX0_FULL_ENABLE << 2
    vTX0_UNDERFLOW_ENABLE    = TX0_UNDERFLOW_ENABLE << 1
    vTX0_EMPTY_ENABLE        = TX0_EMPTY_ENABLE 0x0
    
    #TODO:insert rest of parameters here
    IRQENABLE = 0x0000 | EOWKE | RX0_OVERFLOWENABLE | RX0_FULL_ENABLE | TX0_UNDERFLOW_ENABLE | TX0_EMPTY_ENABLE

    return IRQENABLE


def setSYST(SPIENDIR = 0x0, SPIDATDIR1 = 0x0, SPIDATDIR0 = 0x1, SPICLK = 0x0, SPIDAT_1 = 0x0, SPIDAT_0 = 0x0, SPIEN_1 = 0x0, SPIEN_0 = 0x0):
    """
    Helper function to setup System Test, probably will nevr use it but it is here!!
    """
    # SSB  ?
    vSPIENDIR                = SPIENDIR << 10     # output in master mode
    vSPIDATDIR1              = SPIDATDIR1 << 9      # 0x0 output
    vSPIDATDIR0              = SPIDATDIR0 << 8      # 0x1 input
    vSPICLK                  = SPICLK << 6      # driven low
    vSPIDAT_1                = SPIDAT_1 << 5
    vSPIDAT_0                = SPIDAT_0 << 4      # driven low if output
    vSPIEN_1                 = SPIEN_1 << 1      # driven low
    vSPIEN_0                 = SPIEN_0             # driven low
    SYST = 0x00000000 | vSPIENDIR | vSPIDATDIR1 | vSPIDATDIR0 | vSPICLK | vSPIDAT_1 |vSPIDAT_0 | vSPIEN_1 | vSPIEN_0
    
    return SYST


def setMODCONTROL(FDAA = 0x0, MOA = 0x0, INITDLY  = 0x0, SYSTEM_TEST = 0x0, MS = 0x0, PIN34  = 0x0, SINGLE  = 0x0):
    """
    Helper function that returns value for MODCONTROL register

    """
    vFDAA                   = (FDAA << 8)      # 0x0 FIFO manged by CSPI_tx and rx registers
    vMOA                    = (MOA << 7)      # multiple word access disabled
    vINITDLY                = (INITDLY << 4)      # no intial delay
    vSYSTEM_TEST            = (SYSTEM_TEST << 3)      # Functional mode
    vMS                     = (MS << 2)      # This module is a master
    vPIN34                  = (PIN34 << 1)      # 0x0 SPIEN is used as chip select 
    vSINGLE                 = (SINGLE)             # 0x0 more than one channel will be used in master mode
    MODCONTROL = 0x00000000 | vFDAA| vMOA | vINITDLY | vSYSTEM_TEST | vMS | vPIN34 | vSINGLE

    return MODCONTROL



def setCH_CONF(CLKG = 0x1, FFER = 0x0, FFEW = 0x0, TCS = 0x0, SBPOL = 0x0, SBE = 0x0, SPIENSLV = 0x0, FORCE = 0x0, TURBO = 0x0, IS = 0x1, DPE1 = 0x1, DPE0 = 0x0, DMAR = 0x0, DMAW = 0x0, TRM = 0x0, WL = 0x7, EPOL = 0x1, CLKD = 0x1, POL = 0x0, PHA = 0x1):
    """
    Helper Function to set up and return a configuration for SPI channel
    !!come helper come!!
    """

    vCLKG                   = (CLKG << 29)       # 0x0 clock divider granularity power of 2
    vFFER                   = (FFER << 28)       # FIFO enabled for recieve, 0x0 not used
    vFFEW                   = (FFEW << 27)       # FIFO enabled for transmit, 0x0 not used
    vTCS                    = (TCS << 25)       # 0.5 clock cycle delay 
    vSBPOL                  = (SBPOL << 24)       #start bit held to zero
    vSBE                    = (SBE << 23)       # start bit enable  , 0x0 default set by WL
    vSPIENSLV               = (SPIENSLV << 21)       # spi select signal detection on ch 0
    vFORCE                  = (FORCE << 20)       # manual assertion to keep SPIEN active between SPI words
    vTURBO                  = (TURBO << 19)       # 0x0 turbo is deactivated 
    vIS                     = (IS << 18)       # Input select SPIDAT1 selected for reception
    vDPE1                   = (DPE1 << 17)       # 0x1 no Transmission enable for data line 1
    vDPE0                   = (DPE0 << 16)       # data line zero selected for transmission
    vDMAR                   = (DMAR << 15)       # DMA read request is disabled
    vDMAW                   = (DMAW << 14)       # DMA write request is disabled
    vTRM                    = (TRM << 12)       #Transmit only   
    vWL                     = (WL << 7)       # 0x17 24bit wordlength DAC, 0x11 18bit Wordlength for ADC
    vEPOL                   = (EPOL << 6)        # spien is held low during active state
    vCLKD                   = (CLKD << 2)        # Clk frequency divider 0x1 for DAC 24 MHz, 0x2 for ADC 16MHz
    vPOL                    = (POL << 1)        # SPI clock is held high during ative state
    vPHA                    = (PHA)             # data latched on even numbered edges of SPICLK
    CH_CONF = 0x00000000 | vCLKG | vFFER | vFFEW | vTCS | vSBPOL | vSBE | vSPIENSLV| vFORCE | vTURBO | vIS | vDPE1 | vDPE0 | vDMAR | vDMAW | vTRM | vWL | vEPOL | vCLKD | vPOL | vPHA

    return CH_CONF

 
f = open("/dev/mem", "r+b")

spimem = mmap(f.fileno(), MCSPI1_size, offset = MCSPI1_offset)
Cmem = mmap(f.fileno(), 0xfff, offset = CM_PER)


def getReg(address, mapped, length=32):
    """ Returns unpacked 16 or 32 bit register value starting from address. """
    if (length == 32):
        return struct.unpack("<L", mapped[address:address+4])[0]
    elif (length == 16):
        return struct.unpack("<H", mapped[address:address+2])[0]
    else:
        raise ValueError("Invalid register length: %i - must be 16 or 32" % length)


def setReg(address, mapped, new_value, length=32):
    """ Sets 16 or 32 bits at given address to given value. """
    if (length == 32):
        mapped[address:address+4] = struct.pack("<L", new_value)
    elif (length == 16):
        mapped[address:address+2] = struct.pack("<H", new_value)
    else:
        raise ValueError("Invalid register length: %i - must be 16 or 32" % length)

def printValue(register):
    print hex(register)
    print"byte 1=" +str(bin(register & 0x000000ff))
    print"byte 2=" +str(bin((register & 0x0000ff00) >> 8))
    print"byte 3=" +str(bin((register & 0x00ff0000) >> 16))
    print"byte 4=" +str(bin((register & 0xff000000) >> 24)) + "\n"

def setAndCheckReg(address, mapped, new_value, name = "Reg"):
    print"value written" + hex(new_value)
    setReg(address,mapped, new_value)
    value = getReg(address, mapped)
    print"register value of " + name +":"
    printValue(value)

    
def checkValue(address, mapped, bit = 0, value = 1, name = "Reg"):
    reg = getReg(address, mapped)
    flag = value << bit
    print"check value of resgister" + name +":\n"
    printValue(reg)
    if ((reg & flag) == flag):
        return True
    else:
        return False


#TODO finsh writing this function and setup channel config , enable and then wait for txs bit to be set
def waitTillSet(address, mapped, bit = 0, value =1, name = "Reg", maxNum = 10):
    checkAgain = True
    count = 0
    check = True
    while((check == True) and (count < maxNum)):
        result = checkValue(address, mapped, bit, value, name)
        if (result == True):
            check = False
        elif(result == False): 
            time.sleep(0.000001)
            count += 1
    print count




setAndCheckReg(CM_PER_SPI1_CLK_CTRL, Cmem, 0x2, name = "CM_PER_SPI1_CLK_CTRL")

sys = getReg(MCSPI_SYSCONFIG, spimem)
print"register value of MCSPI_SYSCONFIG:"
printValue(sys)
reset = 0x1<<1
sysReset = sys | reset
setReg(MCSPI_SYSCONFIG, spimem, sysReset)

check = True
count = 0
while(check):
    stat = getReg(MCSPI_SYSSTATUS, spimem)
    count +=1 
    resetdone = 0x1 & stat
    if (resetdone == 0x1):
        check = False
print"register value of MCSPI_SYSSTATUS:"
print"Count:" + str(count)
printValue(stat)

setAndCheckReg(MCSPI_MODULCTRL, spimem, MODCONTROL, name = "MCSPI_MODULCTRL")

setAndCheckReg(MCSPI_SYSCONFIG, spimem, SYSCONFIG, name = "MCSPI_SYSCONFIG")

irq = getReg(MCSPI_IRQSTATUS, spimem)
print"inital status of MCSPI_IRQSTATUS :"
printValue(irq)

setAndCheckReg(MCSPI_IRQSTATUS, spimem, 0xffffffff, name = "MCSPI_IRQSTATUS")

setAndCheckReg(MCSPI_IRQENABLE, spimem, IRQENABLE, name = "MCSPI_IRQENABLE")

setAndCheckReg(MCSPI_CH0CTRL, spimem, 0x00000000)

setAndCheckReg(MCSPI_CH0CONF, spimem, CH_CONF, name = "MCSPI_CH0CONF")


setAndCheckReg(MCSPI_XFERLEVEL, spimem, XFER, name ="XFERLevel")

setAndCheckReg(MCSPI_CH0CTRL, spimem, 0x00000001, name = "enable CH")


waitTillSet(MCSPI_CH0STAT, spimem, bit = 1, value = 1, name = "MCSPI_CH0STAT TXS")

for i in range(6):
    setAndCheckReg(MCSPI_TX0, spimem, 0xfff29999, name ="MCSPI_TX0")

#waitTillSet(MCSPI_CH0STAT, spimem, bit = 1, value = 0, name = "MCSPI_CH0STAT TXS")

tx = getReg(MCSPI_TX0, spimem)
print "contents of TX0 register are after write and TXS set:"
printValue(tx)

txsSet = getReg(MCSPI_CH0STAT, spimem)
print "TXS set:"
printValue(txsSet)

setAndCheckReg(MCSPI_CH0CTRL, spimem, 0x00000000)



