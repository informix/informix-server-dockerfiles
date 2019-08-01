#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>


char *garg1;
char *garg2;
char *garg3;
char *garg4;
char cmd[256];

void sig_handler (int signo)
{
   if (signo == SIGINT || signo == SIGTERM)
   {
      //printf("Shutdown:\n");
      sprintf(cmd, "%s %s", garg3, garg4);
      system(cmd);
   }

printf("Received signal %d\n",signo);
}


int main(int argc, char *argv[])
{ 

garg1=argv[1];
garg2=argv[2];
garg3=argv[3];
garg4=argv[4];

/*
printf("argv[1]: %s\n", garg1);
printf("argv[2]: %s\n", garg2);
printf("argv[3]: %s\n", garg3);
printf("argv[4]: %s\n", garg4);
*/

if (signal(SIGINT, sig_handler) == SIG_ERR)
   printf("Can't catch SIGINT\n");
if (signal(SIGTERM, sig_handler) == SIG_ERR)
   printf("Can't catch SIGTERM\n");
if (signal(SIGKILL, sig_handler) == SIG_ERR)
   printf("Can't catch SIGKILL\n");

sprintf(cmd, "%s %s", garg1, garg2);
system(cmd);

while (1)
{
   sleep(10);
}


//pause();


return 0;

}
