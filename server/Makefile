# Makefile for aesdsocket

ifeq ($(CC),)
	CC = ${CROSS_COMPILE}gcc
endif

ifeq ($(CFLAGS),)
	CFLAGS = -g -Wall -Werror
endif

TARGET = aesdsocket

default: all
all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -o $(TARGET) $(TARGET).c

clean:
	rm -f $(TARGET) $(TARGET).o

.PHONY: all clean default

