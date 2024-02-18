#include "syscall.hh"
#include "libs.hh"

long syscall(long number, ...) {
    return libs::libc::syscall(number, &number+sizeof(long));
}