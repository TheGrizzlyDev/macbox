#include <sys/socket.h>
#include <sys/un.h>
#include <string.h>

struct sockaddr macbox_create_unix_address(const char* addr, size_t addr_len) {
    struct sockaddr address = { AF_UNIX };
    strncpy(address.sa_data, addr, addr_len);
    return address;
}