
import socket
import time
import struct
import numpy
import pylab

# address of the BeagleBone DMX
IP = "10.0.1.8"
PORT = 5009


buf_size = 4096
#data =[]

# can just us numpy.int16 to take care of 2's complement
#easily scan in every direction
dt = numpy.dtype('uint32')

pF = 0x400
sF = 0x400
samp = 0x1
CH = 0x2


    # make sure pF is integer multiple of CCNT
if (pF >= 1020/(CH*samp)):
    CCNT = int(1020/(CH*samp))# largest CCNT can be
    pF = (pF/CCNT)*CCNT
    print "CCNT", CCNT
elif(CH*pF*samp <= 1020):
    CCNT = pF*samp

print "CCNT",CCNT
print "pF",pF
print "samp", samp
count = 0

storedArray = numpy.zeros([pF, sF, CH, samp], numpy.int32)

header_max = pF/CCNT * sF 
print header_max




def loop():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    sock.bind(("",PORT))
    datacount = CCNT*CH
    print datacount
    count = 0

    while True:
    
        data = sock.recv(buf_size)
        
        header = numpy.frombuffer(data, dtype = dt, count = 1, offset = 4)
        #Grab data from buff keep sign shift remaing data back print values
        X = numpy.frombuffer(data, dtype = dt, count = datacount, offset = 16)
        #typecast to keep sign
        Copy = numpy.int32(X << 14)
        #shift data back to proper space
        #now we have signed 18bit data represented as signed int32
        Z = Copy >> 14   #15 to get data back to its place but keep the sign
        #data is always zero indexed

        yindex = (header -1)/(pF/CCNT)   
        xindex = header - yindex*(pF/CCNT)-1

        sub_data_array = numpy.reshape(Z, ((CCNT/samp),CH,samp), order = 'C')
        
        print "data", count , " len", len(data), "xindex" , xindex, "yindex", yindex , "data shape", sub_data_array.shape, "header" , header[0], "Z", Z[1]
        #print sub_data_array
        sub_xindex = xindex*sub_data_array.shape[0]
        print sub_xindex 
        storedArray[sub_xindex[0] : sub_xindex[0] + sub_data_array.shape[0], yindex[0], :,:] = sub_data_array

        count += 1
        if header[0] == header_max:
            break
    sock.close()
    pylab.imshow(storedArray[:,:,1,0])
    pylab.colorbar()
    pylab.show()
    pylab.imshow(storedArray[:,:,0,0])
    pylab.colorbar()
    pylab.show()


if __name__ == "__main__":

    loop()
    #sock.close()

