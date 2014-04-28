#include <stdio.h>

#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#include <dirent.h>
#include <signal.h>
#include <prussdrv.h>
#include <pruss_intc_mapping.h>


#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>


#define PRU_NUM 	0
#define AM33XX



#define UDP_PORT (9930)
#define UDP_BUFLEN (512)


#define START_SCAN 0xa0aa
#define STOP_SCAN  0xf0ff

static void *pruDataMem;
static unsigned int *pruDataMem_int;

static int LOCAL_exampleInit ( unsigned short pruNum );
static void LOCAL_udp_listen ();
static int Local_pru_Data_Mem ();

struct scan_param {
    unsigned int Sx;
    unsigned int Sy;
    unsigned int sdx;
    unsigned int sdy;
    unsigned int dx;
    unsigned int dy;
    unsigned int pF;
    unsigned int sF;
    unsigned int samp;
    unsigned int CH;
    unsigned int DVAR;
	unsigned int OS;
};

struct scan_param scan;

static int udp_forever = 1;
unsigned int scanning = 0;

int main (void)
{
    //unsigned int ret;
    //tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;
    
    //printf("\nINFO: Starting %s example.\r\n", "SPIScan");
    /* Initialize the PRU */
    //prussdrv_init ();		
    
    /* Open PRU Interrupt */
    //ret = prussdrv_open(PRU_EVTOUT_0);
    //if (ret)
    //{
    //    printf("prussdrv_open open failed\n");
    //   return (ret);
    //}
    
    /* Get the interrupt initialized */
    //prussdrv_pruintc_init(&pruss_intc_initdata);

    //Initialize Data on of shared memory
    // LOCAL_exampleInit(PRU_NUM);
	LOCAL_udp_listen();

    /* Execute example on PRU */
    printf("\tINFO: Executing example.\r\n");
    prussdrv_exec_program (PRU_NUM, "./SPIScan.bin");
    
    /* Wait until PRU0 has finished execution */
    printf("\tINFO: Waiting for HALT command.\r\n");
    prussdrv_pru_wait_event (PRU_EVTOUT_0);
    printf("\tINFO: PRU completed transfer.\r\n");
    prussdrv_pru_clear_event (PRU0_ARM_INTERRUPT);

    /* Disable PRU and close memory mapping*/
    prussdrv_pru_disable (PRU_NUM);
    prussdrv_exit ();

    return(0);
}

static int LOCAL_exampleInit ( unsigned short pruNum )
{  
    //Initialize pointer to PRU data memory
    if (pruNum == 0)
    {
      prussdrv_map_prumem (PRUSS0_PRU0_DATARAM, &pruDataMem);
    }
    else if (pruNum == 1)
    {
      prussdrv_map_prumem (PRUSS0_PRU1_DATARAM, &pruDataMem);
    }  
    pruDataMem_int = (unsigned int*) pruDataMem;
    
    // Write values in the PRU data memory locations
    pruDataMem_int[0] = 0x0;// 0x8000; //Sx
    pruDataMem_int[1] =0x0;//  0x8000; //Sy
    pruDataMem_int[2] = 0x0;// 0x0000; //sdx
    pruDataMem_int[3] = 0x0;// 0x0040; //sdy
    pruDataMem_int[4] = 0x0;// 0x0040; //dx
    pruDataMem_int[5] = 0x0;// 0x0000; //dy
    pruDataMem_int[6] = 0x0;// 0x03ff; //pF
    pruDataMem_int[7] = 0x0;// 0x03ff; //sF
    pruDataMem_int[8] = 0x0;// 0x0001; //samp
    pruDataMem_int[9] = 0x0;// 0x0002; //CH
    pruDataMem_int[10] = 0x0;// 0x0001; //DVAR

    return(0);
}

static int Local_pru_Data_Mem(){

    pruDataMem_int[0] = scan.Sx;
    pruDataMem_int[1] = scan.Sy;
    pruDataMem_int[2] = scan.sdx;
    pruDataMem_int[3] = scan.sdy;
    pruDataMem_int[4] = scan.dx;
    pruDataMem_int[5] = scan.dy;
    pruDataMem_int[6] = scan.pF;
    pruDataMem_int[7] = scan.sF;
    pruDataMem_int[8] = scan.samp;
    pruDataMem_int[9] = scan.CH;
    pruDataMem_int[10] = scan.DVAR;
    pruDataMem_int[11] = scan.OS;


    return(0);

}


static void diep(char *s)
{
  perror(s);
  exit(1);
}


// From http://www.abc.se/~m6695/udp.html
static void LOCAL_udp_listen () {
	struct sockaddr_in si_me, si_other;
	int s, i, slen=sizeof(si_other);
	char buf[UDP_BUFLEN];
	//int channel, value;
	int packet_length;
	int r;

    unsigned int ret;
	unsigned int cmd;

	if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1)
		diep("socket");

	memset((char *) &si_me, 0, sizeof(si_me));
	si_me.sin_family = AF_INET;
	si_me.sin_port = htons(UDP_PORT);
	si_me.sin_addr.s_addr = htonl(INADDR_ANY);
	if (bind(s, &si_me, sizeof(si_me))==-1)
		diep("bind");

	for (i=0; i<UDP_BUFLEN; i++) {
		buf[i] = 0;
	}
	while(udp_forever){
		packet_length = recvfrom(s, buf, UDP_BUFLEN, 0, &si_other, &slen);
		if (packet_length == -1) {
			diep("recvfrom()");
		}
		buf[packet_length] = 0;
		
		sscanf(buf, "%8x", &cmd); //First part of the buffer always needs to be the cmd
			switch(cmd){
				case START_SCAN:
					sscanf(buf, "%8x%8x%8x%8x%8x%8x%8x%8x%8x%8x%8x%8x%8x", &cmd, &scan.Sx, &scan.Sy, &scan.sdx, &scan.sdy, &scan.dx, 
							&scan.dy, &scan.pF, &scan.sF, &scan.samp, &scan.CH, &scan.DVAR, &scan.OS );
					printf("%d", packet_length);

					if (scanning == 1){
					    prussdrv_pru_clear_event (PRU0_ARM_INTERRUPT);

    					/* Disable PRU and close memory mapping*/
    					prussdrv_pru_disable (PRU_NUM);
    					prussdrv_exit ();
					}
					
    				tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;
    
    				printf("\nINFO: Starting %s example.\r\n", "SPIScan");
    				/* Initialize the PRU */
    				prussdrv_init ();		
    
    				/* Open PRU Interrupt */
    				ret = prussdrv_open(PRU_EVTOUT_0);
    				if (ret){
        				printf("prussdrv_open open failed\n");
        				//return (ret);
    				}
    
    				/* Get the interrupt initialized */
    				prussdrv_pruintc_init(&pruss_intc_initdata);

    				//Initialize Data on of shared memory
     				LOCAL_exampleInit(PRU_NUM);
					r = Local_pru_Data_Mem();

				    printf("\tINFO: Executing example.\r\n");
    				prussdrv_exec_program (PRU_NUM, "./SPIScan.bin");
    
					scanning = 1;

					break;


				case STOP_SCAN:

					if (scanning == 1){
					    prussdrv_pru_clear_event (PRU0_ARM_INTERRUPT);

    					/* Disable PRU and close memory mapping*/
    					prussdrv_pru_disable (PRU_NUM);
    					prussdrv_exit ();
					}
						scanning = 0;

					break;

				default:
					break;

			}
			
	}
	close(s);
}
