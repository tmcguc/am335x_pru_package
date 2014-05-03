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


OS_0 = 2
OS_1 = 3
OS_2 = 5


# can just us numpy.int16 to take care of 2's complement
#easily scan in every direction
def constructPayload():
    Sx = numpy.int16(0x8000)
    Sy = numpy.int16(0x8000)
    sdx = numpy.int16(0x0000)
    sdy = numpy.int16(0x0040)
    dx = numpy.int16(0x0040)
    dy = numpy.int16(0x0000)
    pF = 0x400
    sF = 0x400
    samp = 0x1
    CH = 0x5
    DVAR = 0xff
    OS =  0 << OS_2 | 1 << OS_1 | 0 << OS_0
    XFER = CH << 16 | ((CH*4) -1) << 8


    # make sure pF is integer multiple of CCNT
    if (pF >= 1020/(CH*samp)):
        CCNT = int(1020/(CH*samp))# largest CCNT can be
        pF = (pF/CCNT)*CCNT
        print "CCNT", CCNT
    else:
        CCNT = pF*CH*samp

    print "CCNT",CCNT
    print "pF",pF
 

    #Make sure scan doesn't go outside bounds of what the DAC can take as an input
    assert abs(Sx + sdx*sF) <= abs(0x8000) 

    assert abs(Sx + dx*pF) <= abs(0x8000) 

    assert abs(Sy + sdy*sF) <= abs(0x8000) 

    assert abs(Sy + dy*pF) <= abs(0x8000) 


    #Pick values that fit levels allowed by DMA controller and buffers
    assert (CH*samp) <= 1020

    #assert  CCNT <= 1020/(CH*samp)

    

    

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

