#include <stdio.h>

#include <prussdrv.h>
#include <pruss_intc_mapping.h>

#define PRU_NUM 	0
#define AM33XX

static void *pruDataMem;
static unsigned int *pruDataMem_int;

static int LOCAL_exampleInit ( unsigned short pruNum );


int main (void)
{
    unsigned int ret;
    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;
    
    printf("\nINFO: Starting %s example.\r\n", "SPIScan");
    /* Initialize the PRU */
    prussdrv_init ();		
    
    /* Open PRU Interrupt */
    ret = prussdrv_open(PRU_EVTOUT_0);
    if (ret)
    {
        printf("prussdrv_open open failed\n");
        return (ret);
    }
    
    /* Get the interrupt initialized */
    prussdrv_pruintc_init(&pruss_intc_initdata);

    //Initialize Data on of shared memory
     LOCAL_exampleInit(PRU_NUM);


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
    pruDataMem_int[0] = 0x8000; //Sx
    pruDataMem_int[1] = 0x8000; //Sy

    pruDataMem_int[2] = 0x0000; //sdx
    pruDataMem_int[3] = 0x0040; //sdy

    pruDataMem_int[4] = 0x0040; //dx
    pruDataMem_int[5] = 0x0000; //dy

    pruDataMem_int[6] = 0x03ff; //pF
    pruDataMem_int[7] = 0x03ff; //sF

    pruDataMem_int[8] = 0x0001; //samp
    pruDataMem_int[9] = 0x0002; //CH

    pruDataMem_int[10] = 0x0001; //DVAR

    return(0);
}

