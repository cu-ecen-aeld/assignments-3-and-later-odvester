#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

void writeToFile(const char* writefile, const char* writestr) {
    FILE* file = fopen(writefile, "w");
    if (file == NULL) {
        syslog(LOG_ERR, "Failed to create file: %s", writefile);
        exit(1);
    }

    fprintf(file, "%s", writestr);
    fclose(file);

    syslog(LOG_DEBUG, "Writing '%s' to '%s'", writestr, writefile);
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        syslog(LOG_ERR, "Usage: %s <writefile> <writestr>", argv[0]);
        exit(1);
    }

    if (strlen(argv[2]) == 0) {
        syslog(LOG_ERR, "Write string not specified");
        exit(1);
    }

    openlog(argv[0], LOG_CONS | LOG_PID, LOG_USER);

    const char* writefile = argv[1];
    const char* writestr = argv[2];

    writeToFile(writefile, writestr);

    closelog();

    return 0;
}
