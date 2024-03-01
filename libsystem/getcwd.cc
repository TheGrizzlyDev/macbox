#include "getcwd.hh"
#include "api_client.hh"
#include "libs.hh"
#include <cstdio>
#include <string>

char* getcwd(char* buf, size_t len) {
    std::string cwd { api::client::ApiClient::the().getcwd() };
    
    if (buf == nullptr) {
        char* result = static_cast<char*>(malloc(sizeof(char*)));
        strncpy(result, cwd.c_str(), cwd.size());
        return result;
    }
    strncpy(buf, cwd.c_str(), len);
    return buf;
}