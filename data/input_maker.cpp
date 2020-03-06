//c++ program to write input files for MSDAP midterm

#include <stdio.h>
#include <stdlib.h>  /* For exit() function */
#include <stdint.h>

int main()
{
	FILE *rj1, *rj2, *coeff1, *coeff2, *data1, *data2, *out_file;
	
	rj1	= fopen("Rj1.in", "r");
	rj2	= fopen("Rj2.in", "r");
	coeff1	= fopen("Coeff1.in", "r");
	coeff2	= fopen("Coeff2.in", "r");
	data1	= fopen("data1.in", "r");
	data2	= fopen("data2.in", "r");
	out_file= fopen("input.in", "w");
	
	if (rj1 == NULL) 	{ fprintf(stderr, "Can't open input file rj1.in!\n");	exit(1); }
	if (rj2 == NULL) 	{ fprintf(stderr, "Can't open input file rj2.in!\n"); exit(1); }
	if (coeff1 == NULL) 	{ fprintf(stderr, "Can't open input file coeff1.in!\n"); exit(1); }
	if (coeff2 == NULL)	{ fprintf(stderr, "Can't open input file coeff2.out!\n"); exit(1); }
	if (data1 == NULL) 	{ fprintf(stderr, "Can't open input file data1.in!\n");	exit(1); }
	if (data2 == NULL) 	{ fprintf(stderr, "Can't open input file data2.in!\n"); exit(1); }
	if (out_file == NULL)	{ fprintf(stderr, "Can't open input file input.in!\n"); exit(1); }
	
	//read both rj files, put them in out_file

	
	fprintf(out_file, "//RJ VALUES\n");
	printf("//RJ VALUES\n");
	
	
	while(!feof(rj1))
	{
		int rj [2];
		
		fscanf(rj1, "%x", &rj[0]);
		fscanf(rj2, "%x", &rj[1]);
		
		fprintf(out_file, "%04X\t%04X\n", rj[0], rj[1]);		
	}
	
	//read both coeff files, put them in out_file
	fprintf(out_file, "//COEFF VALUES\n");
	printf("//COEFF VALUES\n");
	while(!feof(coeff1))
	{		
		int coeff [2];
		
		fscanf(coeff1, "%x", &coeff[0]);
		fscanf(coeff2, "%x", &coeff[1]);

		if(!feof(coeff1))
		fprintf(out_file, "%04X\t%04X\n", coeff[0], coeff[1]);
	}
	
	//read both data files, put them in out_file
	fprintf(out_file, "//DATA VALUES\n");
	printf("//DATA VALUES\n");
	while(!feof(data1))
	{
		int data [2];
		
		fscanf(data1, "%x", &data[0]);
		fscanf(data2, "%x", &data[1]);
		
		fprintf(out_file, "%04X\t%04X\n", data[0], data[1]);
	}
	
}
