#include "PalArbiter.h"
#include "verilated.h"

struct TestCase {
	const char* name;
  	uint8_t ID;
	uint8_t ARB_I;
	bool GRANT;
};


int main(int argc, char **argv, char **env) {
	Verilated::commandArgs(argc, argv);
  	PalArbiter* arbitera = new PalArbiter;
  	PalArbiter* arbiterb = new PalArbiter;

  	arbitera->ARBENA = 0;
  	arbitera->ID = 0;
  	arbitera->ARB_I = arbitera->ARB_O;
  	arbitera->eval();
  	arbitera->ARBENA = 1;

  	arbiterb->ARBENA = 0;
  	arbiterb->ID = 0;
  	arbiterb->ARB_I = arbiterb->ARB_O;
  	arbiterb->eval();
  	arbiterb->ARBENA = 1;

  	for(uint8_t ida = 0; ida < 16; ida++) {
	  	arbitera->ID = ida; 
		for(uint8_t idb = 0; idb < 16; idb++) {
			if (ida == idb)
				continue;
			arbiterb->ID = idb; 

	  		arbitera->ARB_I = arbitera->ARB_O | arbiterb->ARB_O; 
	  		arbiterb->ARB_I = arbitera->ARB_O | arbiterb->ARB_O;
			arbitera->eval();
			arbiterb->eval();
			// because test require ouput signals on input we have to make two steps
			// first we produce outputs then second we copy output on input and make
			// one more step
	  		arbitera->ARB_I = arbitera->ARB_O | arbiterb->ARB_O; 
	  		arbiterb->ARB_I = arbitera->ARB_O | arbiterb->ARB_O;
			arbitera->eval();
			arbiterb->eval();

			bool expected_grant = arbitera->ID > arbiterb->ID;

	   		if (expected_grant != arbitera->GRANT) {
	    		printf("  fail (%01X vs %01X) (expected GRANT=%01X but was %01X) (ARB_I=%01X ARB_Out=%01X)\n",
	    	 		arbitera->ID, 
	    			arbiterb->ID,
	    			expected_grant,
	    			arbitera->GRANT, 
	    			arbitera->ARB_I,
	    			arbitera->ARB_O);
	    	}
	    	else {
	    		printf("passed (%01X vs %01X) (ARB_Out=%01X)\n", arbitera->ID, arbiterb->ID, arbitera->ARB_O);
	    	}
		}
  	}

	arbitera->final();
	arbiterb->final();
    delete arbitera;
    delete arbiterb;
    exit(0);
}