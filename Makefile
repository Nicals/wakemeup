CC=gcc
CFLAGS=-Wall -O2 --debug
EXEC=wakemeup
INSTALL_DIR=/usr/local/bin
MAN_FILE=wakemeup.1.gz
MAN_DIR=/usr/local/share/man/man1
PID_DIR=/tmp/
MOD=
# GOD_MOD enables the -c command
# MOD+= -DGOD_MOD

.PHONY:all clean mproper rebuild

all:wakemeup

wakemeup:wakemeup.c
	$(CC) $^ -o $(EXEC) $(CFLAGS) $(MOD)

clean:
	rm -f *.o

mproper:clean
	rm -f $(EXEC)

install:
	cp $(EXEC) $(INSTALL_DIR)
	mkdir -p $(MAN_DIR)
	cp $(MAN_FILE) $(MAN_DIR)

# TODO: delete empty directory that was created
uninstall:
	rm -f $(INSTALL_DIR)/$(EXEC)
	rm -f $(MAN_DIR)/$(MAN_FILE)
