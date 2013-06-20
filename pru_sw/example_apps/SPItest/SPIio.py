
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


EOWKE                   = 0x0 << 17
RX0_OVERFLOWENABLE      = 0x0 << 3
RX0_FULL_ENABLE         = 0x0 << 3
TX0_UNDERFLOW_ENABLE    = 0x0 << 1
TX0_EMPTY_ENABLE        = 0x0

IRQENABLE = 0x0000 | EOWKE | RX0_OVERFLOWENABLE | RX0_FULL_ENABLE | TX0_UNDERFLOW_ENABLE | TX0_EMPTY_ENABLE

# SSB  ?
SPIENDIR                = 0x0 << 10     # output in master mode
SPIDATDIR1              = 0x0 << 9      # 0x0 output
SPIDATDIR0              = 0x1 << 8      # 0x1 input
SPICLK                  = 0x0 << 6      # driven low
SPIDAT_1                = 0x0 << 5
SPIDAT_0                = 0x0 << 4      # driven low if output
SPIEN_1                 = 0x0 << 1      # driven low
SPIEN_0                 = 0x0             # driven low
SYSTEMREG = 0x0000 | SPIENDIR | SPIDATDIR1 | SPIDATDIR0 | SPICLK | SPIDAT_1 |SPIDAT_0 | SPIEN_1 | SPIEN_0


FDAA                   = 0x0 << 8      # 0x0 FIFO manged by CSPI_tx and rx registers
MOA                    = 0x0 << 7      # multiple word access disabled
INITDLY                = 0x0 << 4      # no intial delay
SYSTEM_TEST            = 0x0 << 3      # Functional mode
MS                     = 0x0 << 2      # This module is a master
PIN34                  = 0x0 << 1      # 0x0 SPIEN is used as chip select 
SINGLE                 = 0x1             # 0x0 more than one channel will be used in master mode
MODCONTROL = 0x0000 | FDAA| MOA | INITDLY | SYSTEM_TEST | MS | PIN34 | SINGLE



CLKG                   = (0x1 << 29)       # 0x0 clock divider granularity power of 2
FFER                   = (0x0 << 28)       # FIFO enabled for recieve, 0x0 not used
FFEW                   = (0x1 << 27)       # FIFO enabled for transmit, 0x0 not used
TCS                    = (0x0 << 25)       # 0.5 clock cycle delay 
SBPOL                  = (0x0 << 24)       #start bit held to zero
SBE                    = (0x0 << 23)       # start bit enable  , 0x0 default set by WL
SPIENSLV               = (0x0 << 21)       # spi select signal detection on ch 0
FORCE                  = (0x1 << 20)       # manual assertion to keep SPIEN active between SPI words
TURBO                  = (0x1 << 19)       # 0x0 turbo is deactivated 
IS                     = (0x1 << 18)       # Input select SPIDAT1 selected for reception
DPE1                   = (0x1 << 17)       # 0x1 no Transmission enable for data line 1
DPE0                   = (0x0 << 16)       # data line zero selected for transmission
DMAR                   = (0x0 << 15)       # DMA read request is disabled
DMAW                   = (0x0 << 14)       # DMA write request is disabled
TRM                    = (0x2 << 12)       #Transmit only   
WL                     = (0x11 << 7)       # 0x17 24bit wordlength DAC, 0x11 18bit Wordlength for ADC
EPOL                   = (0x1 << 6)        # spien is held low during active state
CLKD                   = (0x2 << 2)        # Clk frequency divider 0x1 for DAC 24 MHz, 0x2 for ADC 16MHz
POL                    = (0x0 << 1)        # SPI clock is held high during ative state
PHA                    = (0x1)             # data latched on even numbered edges of SPICLK
CH_CONF = 0x0000 | CLKG | FFER | FFEW | TCS | SBPOL | SBE | SPIENSLV| FORCE | TURBO | IS | DPE1 | DPE0 | DMAR | DMAW | TRM | WL | EPOL | CLKD | POL | PHA

 
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

setAndCheckReg(MCSPI_CH0CONF, spimem, CH_CONF, name = "MCSPI_CH0CONF")

setAndCheckReg(MCSPI_CH0CTRL, spimem, 0x00000000)

setAndCheckReg(MCSPI_XFERLEVEL, spimem, XFER, name ="XFERLevel")

setAndCheckReg(MCSPI_CH0CTRL, spimem, 0x00000001, name = "enable CH")

setAndCheckReg(MCSPI_TX0, spimem, 0x5555aaaa, name ="MCSPI_TX0")

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



