/*
 * ==========================================================================
 *
 *  This code is copyright Nicolas Appriou, 2012-2013
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but without any warranty; without even the implied warranty of
 *  merchantability or fitness for a particular purpose.  See the
 *  GNU General Public License for more details.
 *
 * ==========================================================================
 *   Filename: wakemeup.c
 * ==========================================================================
 *
 *   Created:       2012-11-14
 *   Last stable:   2012-11-14
 *
 *   Author:        Nicolas Appriou
 *   Email:         nicolas.appriou@gmail.com
 *
 * ==========================================================================
 *
 * Be sure to have the loop patch you can find this version on my github
 * repository : http://github.com/Nicals/Beep
 *
 * ==========================================================================
 *  Changelog
 * ==========================================================================
 *  2012-12-10
 *    * Added the --robot options usefull for scripting multiples alarms.
 *
 */

#include <errno.h>
#include <getopt.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

/* 
 * some global stuff
 */

#define VERSION "wakemeup 1.0"

#define MIN_CHALLENGE_NB  100
#define MAX_CHALLENGE_NB  999
#define RAND_MIN_MAX(min, max) ((rand() % (max - min + 1)) + min)

const char* pid_filename = "/tmp/wakemeup.pid";


/*
 * a few structures
 */

enum _switch {
  ENABLED,
  DISABLED
};


/* command line parameters */
struct _params {
  /* setting up a challenge to kill a beep process */
  enum _switch skip_challenge;
  /* don't launch any challenge if a previous wakemeup launch have set up an alarm
   * and if this one is still running */
  enum _switch im_a_robot;
};


/* 
 * functions
 */
int challenge();
void start_alarm();
void stop_alarm(pid_t beep_pid);
int read_param(int argc, char* argv[], struct _params* params);
void usage(const char* prg_name);


/*
 * Challenge the user before shutting down the running beep process.
 * Returns 0 if the challenge is succesfully solved.
 * Returns -1 if the user aborted the challenge.
 */
int challenge() {
  unsigned int seed = (unsigned int)(time(NULL));
  unsigned int a, b, result;
  char user_input[49];

  srand(seed);
  a = RAND_MIN_MAX(MIN_CHALLENGE_NB, MAX_CHALLENGE_NB);
  b = RAND_MIN_MAX(MIN_CHALLENGE_NB, MAX_CHALLENGE_NB);
  result = a + b;

  /* Only gods are allowed to skip this ! */
#ifdef GOD_MOD
  fprintf(stdout, "Enter 'q' to exit the challenge\n");
#endif

  do {
    fprintf(stdout, "%u + %u ?\n", a, b);
    fgets(user_input, 49, stdin);
#ifdef GOD_MOD
  } while (atoi(user_input) != result && strncmp(user_input, "q", 49) == 0);
#else
  } while (atoi(user_input) != result);
#endif

  return atoi(user_input) == result ? 0 : -1;
}


/*
 * Start alarm and set PID
 * returns 0 on success and -1 on failure
 */
void start_alarm() {
  FILE* pid_file;
  pid_t beep_pid;
  /* this is the apollo spacecraft alarm system */
  char* args[] = {"beep", "-f750", "-l400", "-n", "-f2000", "-l400", "-i", NULL};

  beep_pid = fork();

  if (beep_pid == 0) {
    execve("/usr/bin/beep", args, NULL);
    fprintf(stderr, "ERROR: Fail to exec beep\n");
    exit(3);
  }
  else if (beep_pid > 0) {
    /* save pid file */
    pid_file = fopen(pid_filename, "w");
    if (pid_file) {
      fprintf(pid_file, "%u\n", beep_pid);
      fclose(pid_file);
      /* set some permission here */
      chmod(pid_filename, 0444);
      fprintf(stdout, "INFO: Process [%u] started.\n", beep_pid);
    }
    else {
      fprintf(stderr, "ERROR: Cannot write pid file %s (%s)", 
              pid_filename, strerror(errno));
      kill(beep_pid, SIGTERM);
    }
  }
  else {
    fprintf(stderr, "ERROR: Fail to fork.\n");
  }
}


/*
 * Kill the beep child process launch early and delete
 * the PID file.
 */
void stop_alarm(pid_t beep_pid) {
  if (kill(beep_pid, SIGTERM) == 0) {
    fprintf(stdout, "INFO: Process [%u] killed.\n", beep_pid);
    /* Just to be sure that the internal speaker will stop */
    putchar('\a');
  }
  else {
    fprintf(stdout, "INFO: Cannot kill process [%u]\n", beep_pid);
  }
  unlink(pid_filename);
}


/*
 * If the returned value is not below 0, the program will
 * exit with this return code.
 */
int read_param(int argc, char* argv[], struct _params* params) {
  int return_code = -1;
  int next_option;
  const char* const short_options = "chrv";
  const struct option long_options[] = {
    {"robot", no_argument, NULL, 'r'},
    {"challenge", no_argument, NULL, 'c'},
    {"help", no_argument, NULL, 'h'},
    {"version", no_argument, NULL, 'v'},
    {0, 0, 0, 0}
  };

  do {
    next_option = getopt_long(argc, argv, short_options, long_options, NULL);
    switch (next_option) {
      case 'c':
#ifdef GOD_MOD
        params->skip_challenge = ENABLED;
#endif
        break;
      case 'r':
        params->im_a_robot = ENABLED;
        break;
      case 'h':
        return_code = 0;
        usage(argv[0]);
        exit(0);
        break;
      case 'v':
        printf("%s\n", VERSION);
        printf("god mod: %s\n",
#ifdef GOD_MOD
            "enabled"
#else
            "disabled"
#endif
        );
        exit(0);
        break;
      case '?':
        fprintf(stderr, "Unknown option -%c\nUse %s for more informations.\n\n", next_option, argv[0]);
        exit(1);
        break;
      default:
        break;
    }
  } while (next_option != -1);

  return return_code;
}


/*
 * Obvious function
 */
void usage(const char* prg_name) {
  printf("\nUsage: %s [-r] [-c] [-h] [-v]"
      "\n\n"
      "Launch an alarm on your computer to wake up early on the morning.\n\n"
      "optional arguments:\n"
      "\t   -c   --challenge   switch challenge off. Only with god mod enabled ad compile time\n"
      "\t   -r   --robot       don't launch the challenge, don't stop the current alarm\n"
      "\t   -h   --help        print this help\n"
      "\t   -v   --version     get version and compile option\n"
      "\n"
      ,
      prg_name);
}


/*
 * Entry point
 */
int main(int argc, char* argv[]) {
  FILE* pid_file;
  pid_t beep_pid = 0;
  struct _params params;
  enum _switch stop_alarm_ok = DISABLED;
  int return_code;

  /* set default parameters */
  params.skip_challenge = DISABLED;
  params.im_a_robot = DISABLED;

  if ((return_code = read_param(argc, argv, &params)) < 0) {
    return_code = 0;

    /* Check if the pid file exists.
     * If it doesn't exists, create it and launch a beep alarm.
     * If it exists, get the pid written in it and kill the
     * process.
     */
    if (!(pid_file = fopen(pid_filename, "r"))) {
      start_alarm();
    }
    else {
      /* the file contains only one line : the pid of the beep alarm
       * currently running.
       */
      fscanf(pid_file, "%u\n", &beep_pid);
      fclose(pid_file);

      /* check if the process is still alive */
      if (kill(beep_pid, 0) < 0) {
        if (errno == ESRCH) {
          /* If we get there, it may be because a pid file
           * is still on hard drive but the process isn't running.
           */
          unlink(pid_filename);
          fprintf(stdout, "INFO: deleting an obsolete PID file [%u].\n", beep_pid);
          start_alarm();
        }
        else if (errno == EPERM) {
          fprintf(stderr, "ERR: don't have the permission to contact running beep instance [%u].\n", beep_pid);
        }
      }
      else {
        /* only on god mod */
        if (params.skip_challenge == ENABLED)
          stop_alarm_ok = ENABLED;
        else if (params.im_a_robot == DISABLED) 
          stop_alarm_ok = (challenge() == 0 ? ENABLED : DISABLED);

        if (stop_alarm_ok == ENABLED)
          stop_alarm(beep_pid);
      }
    }
  }

  return return_code;
}


