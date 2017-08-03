SHELL     = /bin/sh
CC        = arm-linux-gnueabihf-gcc
CFLAGS    = -std=gnu99 -fPIC -O2 $(DEFINES)

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
