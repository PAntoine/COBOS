/*

		COBOS Create Disk File

	Concurrent Object Based Operating System
			(COBOS)

	  BEng (Hons) Software Engineering for
		   Real Time Systems
	       3rd Year Project 1996/97

	     Copyright (c) 1997 P.Antoine



	This program will create a 5 Meg disk file
	for the use of the COBOS operating system.
	It will also set some of the basic structure
	that this fille needs. There is a companion
	assembler program that will set the files
	block chain up.
						  */

#include <stdio.h>
#include <DOS.H>


main()
{
	FILE	*cobosfile;
	char	*buffer;
	int	count, wrote;



/* Silly Message */

	printf("%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n",
		"Concurrent Object Based Operating System",
		"		(COBOS)                 ",
		"                                       ",
		"  BEng (Hons) Software Engineering for ",
		"	   Real Time Systems      ",
		"       3rd Year Project 1996/97  ",
		"                                 ",
		"     Copyright (c) 1997 P.Antoine",
		"",
		" All rights reserved, except thoses needed",
		" by South  Bank University for the purpose",
		" of evaluating this program as port of a  ",
		" final year BEng project.		   ");

/* create the file */

	if ((cobosfile = fopen("\\COBOS.INI", "rb")) != NULL)
	{
		printf("File allready exists.\n");
		return 1;
	};

	if ((cobosfile = fopen("\\COBOS.INI", "wb")) == NULL)
	{
		printf("Cannot create file.\n");
		return 1;
	};


/* fill the file */

	printf(" Creating file....\n");

	buffer = (char *) calloc(1, 512);

	for (count = 0; count < 10240; count++)
	{
		wrote = fwrite(buffer,512,1,cobosfile);
		if (wrote != 1)
		{
			printf("Short count - Disk full? \n ");
			return 3;
		};

		printf(" %d blocks\ written \r",count+1);
	};


	fclose(cobosfile);
	printf("\n File created successfully!\n");

	_dos_setfileattr("\\COBOS.INI",(FA_SYSTEM | FA_HIDDEN));

	return 0;
};



