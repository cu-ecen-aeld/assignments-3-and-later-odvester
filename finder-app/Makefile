# Makefile for writer

CC := gcc
CFLAGS := -Wall -Werror

TARGET := writer

.PHONY: all clean result

all: $(TARGET)

$(TARGET): writer.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGET) *.o

ifeq ($(CROSS_COMPILE),aarch64-none-linux-gnu-)
	CC := aarch64-none-linux-gnu-gcc
endif
result: $(TARGET)
	file $(TARGET) > ~/Documents/Coursera/assignment-1-odvester/assignments/assignment2/fileresult.txt