#include <algorithm>
#include <cstring>
#include <cstdlib>
#include <dlfcn.h>
#include "getcwd.hh"
#include "libs.hh"

char* getcwd(char* buf, size_t len) {
    return libs::libc::getcwd(buf, len);
}