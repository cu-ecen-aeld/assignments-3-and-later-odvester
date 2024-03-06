#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <syslog.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <stdbool.h>

#define SERVER_PORT "9000"
#define BUFFER_LENGTH 1024
#define MAX_BACKLOG 10

static int server_socket = -1;
static FILE *persistent_data_file = NULL;

static void terminate_server(int sig) {
    if (sig == SIGINT || sig == SIGTERM) {
        syslog(LOG_INFO, "Terminating due to signal %d", sig);
        if (server_socket >= 0) {
            close(server_socket);
        }
        if (persistent_data_file) {
            fclose(persistent_data_file);
            remove("/var/tmp/aesdsocketdata");
        }
        closelog();
        exit(EXIT_SUCCESS);
    }
}

static void process_client_request(int client_socket, struct sockaddr_in client_address) {
    char client_ip_address[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &client_address.sin_addr, client_ip_address, INET_ADDRSTRLEN);
    syslog(LOG_INFO, "Connection established with %s", client_ip_address);

    char data_buffer[BUFFER_LENGTH] = {0};
    ssize_t received_bytes;
    char single_char;
    while ((received_bytes = recv(client_socket, &single_char, 1, 0)) > 0) {
        fwrite(&single_char, 1, received_bytes, persistent_data_file);
        if(single_char == '\n') break;
    }
    fflush(persistent_data_file);
    rewind(persistent_data_file);

    while ((received_bytes = fread(data_buffer, 1, BUFFER_LENGTH, persistent_data_file)) > 0) {
        send(client_socket, data_buffer, received_bytes, 0);
    }

    syslog(LOG_INFO, "Connection closed with %s", client_ip_address);
    close(client_socket);
}

int main(int argc, char *argv[]) {
    bool daemonize = false;
    if (argc == 2 && strcmp(argv[1], "-d") == 0) daemonize = true;

    openlog("aesdsocket", LOG_PID, LOG_USER);

    struct sigaction signal_action;
    memset(&signal_action, 0, sizeof(signal_action));
    signal_action.sa_handler = terminate_server;
    sigaction(SIGINT, &signal_action, NULL);
    sigaction(SIGTERM, &signal_action, NULL);

    persistent_data_file = fopen("/var/tmp/aesdsocketdata", "w+");
    if (!persistent_data_file) {
        syslog(LOG_ERR, "Cannot open or create data file");
        exit(EXIT_FAILURE);
    }

    struct addrinfo hints, *res;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    getaddrinfo(NULL, SERVER_PORT, &hints, &res);

    server_socket = socket(res->ai_family, res->ai_socktype, 0);
    int optval = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval));
    bind(server_socket, res->ai_addr, res->ai_addrlen);
    listen(server_socket, MAX_BACKLOG);

    if (daemonize) {
        if (fork() != 0) {
            exit(EXIT_SUCCESS);
        }
        setsid();
        chdir("/");
        close(STDIN_FILENO);
        close(STDOUT_FILENO);
        close(STDERR_FILENO);
    }

    while (1) {
        struct sockaddr_in client_address;
        socklen_t addr_size = sizeof(client_address);
        int client_socket = accept(server_socket, (struct sockaddr *)&client_address, &addr_size);
        if (client_socket >= 0) {
            process_client_request(client_socket, client_address);
        }
    }

    return 0;
}
