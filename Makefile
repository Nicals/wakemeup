CC=gcc
CFLAGS=-Wall -O2
EXEC=wakemeup
INSTALL_DIR=/usr/local/bin
MAN_FILE=wakemeup.1.gz
MAN_DIR=/usr/local/share/man/man1
PID_DIR=/tmp/
MOD=
# GOD_MOD enables the -c command
# uncomment the following line if you need it
# MOD+= -DGOD_MOD

.PHONY:all clean mproper install uninstall

all:wakemeup

wakemeup:wakemeup.c
	$(CC) $^ -o $(EXEC) $(CFLAGS) $(MOD)

clean:
	-rm -f *.o

mproper:clean
	-rm -f $(EXEC)

install:
	cp $(EXEC) $(INSTALL_DIR)
	mkdir -p $(MAN_DIR) 2> /dev/null
	cp $(MAN_FILE) $(MAN_DIR)

uninstall:
	-rm -f $(INSTALL_DIR)/$(EXEC)
	-rm -f $(MAN_DIR)/$(MAN_FILE)
	-rmdir $(MAN_DIR) 2> /dev/null
