SHELL     = /bin/sh
CC        = arm-linux-gnueabihf-gcc
CFLAGS    = -std=gnu99 -fPIC -O2 -DDEBUG

#If DEBUG is set to a path, the FPGA configuration will be loaded from there instead
#This is passed into the code using the macro SD_CARD_OVERRIDE
ifdef DEBUG
	CC = gcc
	CFLAGS += -DSD_CARD_OVERRIDE=\"$(DEBUG)/\"
endif

TARGET    = libphantom.so
SOURCES   = $(shell echo *.c)
HEADERS   = $(shell echo *.h)
OBJECTS   = $(SOURCES:.c=.o)

all: $(TARGET)

.PHONY: clean
clean:
		rm *.o *.so

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJECTS) -shared
