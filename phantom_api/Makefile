SHELL     = /bin/sh
CC        = arm-linux-gnueabihf-gcc
#CC        = gcc
CFLAGS    = -std=gnu99 -fPIC -O2

TARGET    = phantom_api.so
SOURCES   = $(shell echo *.c)
HEADERS   = $(shell echo *.h)
OBJECTS   = $(SOURCES:.c=.o)

all: $(TARGET)

.PHONY: clean
clean:
		rm *.o *.so

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJECTS) -shared
