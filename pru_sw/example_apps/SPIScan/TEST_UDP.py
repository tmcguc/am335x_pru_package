################################################################################
# dmxController.py
# ----------------
# 
# An example script that cycles through each DMX channel, turning each fully on
# one at a time
################################################################################

import socket
import time
import struct
import numpy

# address of the BeagleBone DMX
IP = "10.0.1.8"
PORT = 9930


# can just us numpy.int16 to take care of 2's complement
#easily scan in every direction
def constructPayload():
    #bit shift
    OS_0 = 2
    OS_1 = 3
    OS_2 = 5

    #extract bits
    OS0 = 0b001
    OS1 = 0b010
    OS2 = 0b100
    OSI = 1


    if OSI > 0:
        OS_value = int(numpy.log2(OSI))
    else:
        OS_value = OSI
    print "OS_valuen", bin(OS_value)

    Sx = numpy.int16(0x8000)
    Sy = numpy.int16(0x8000)
    sdx = numpy.int16(0x0000)
    sdy = numpy.int16(0x0040)
    dx = numpy.int16(0x0040)
    dy = numpy.int16(0x0000)
    pF = 0x400
    sF = 0x400
    samp = 0x1
    CH = 0x2
    DVAR = 0xff
    OS =  ((OS_value & OS2) >> 2) << OS_2 | ((OS_value & OS1) >> 1) << OS_1 | (OS_value & OS0) << OS_0 #TODO: need a nice way to add in the over clocking through the gui 2,4,8,16,32,64
    print "OS", OS
    XFER = CH << 16 | ((CH*4) -1) << 8
    

    # make sure pF is integer multiple of CCNT
    if (pF >= 1020/(CH*samp)):
        CCNT = int(1020/(CH*samp))# largest CCNT can be
        pF = (pF/CCNT)*CCNT
        print "CCNT", CCNT
    elif(CH*pF*samp <= 1020):
        CCNT = pF*samp


    print "CCNT",CCNT
    print "pF",pF

    header_max = pF/CCNT * sF 
    print header_max

    #Make sure scan doesn't go outside bounds of what the DAC can take as an input
    assert abs(Sx + sdx*sF) <= abs(0x8000) 

    assert abs(Sx + dx*pF) <= abs(0x8000) 

    assert abs(Sy + sdy*sF) <= abs(0x8000) 

    assert abs(Sy + dy*pF) <= abs(0x8000) 


    #Pick values that fit levels allowed by DMA controller and buffers
    assert (CH*samp) <= 1020

    

    res = "%8x" %0xa0aa
    res += "%8x" %Sx	
    res += "%8x"%Sy
    res += "%8x"%sdx
    res += "%8x"%sdy
    res += "%8x"%dx
    res += "%8x"%dy
    res += "%8x"%pF
    res += "%8x"%sF
    res += "%8x"%samp
    res += "%8x"%CH
    res += "%8x"%DVAR
    res += "%8x"%OS
    res += "%8x"%XFER
    res += "%8x"%CCNT
    

    return res


def loop():
  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
  sock.connect((IP, PORT))

  #while True:
  payload = constructPayload()
  print payload
  sock.send(payload)
  sock.close()

if __name__ == "__main__":
  loop()
  #sock.close()

