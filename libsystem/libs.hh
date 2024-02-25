#pragma once
#include <cstddef>
#include <cstdarg>
#include <dlfcn.h>
#include <sys/socket.h>

namespace libs {
    namespace {
        template<typename ReturnType, typename... Args>
        struct LazyFn {
            LazyFn(const char* fn_name) : fn_name{fn_name} {}
            typedef ReturnType (*FnType)(...); 

            ReturnType operator()(Args... args) {
                if (handle == nullptr) {
                    handle = (FnType)dlsym(RTLD_NEXT, fn_name);
                }
                return handle(args...);
            }

            const char* fn_name;
            FnType handle = nullptr;
        };
    }

    namespace libc {
        LazyFn<int, int> close = {"close"};
        LazyFn<int, int, const sockaddr*, socklen_t> connect = {"connect"};
        LazyFn<char*, char*, size_t> getcwd = {"getcwd"};
        LazyFn<pid_t> getpid = {"getpid"};
        LazyFn<pid_t> gettid = {"gettid"};
        LazyFn<size_t> malloc = {"malloc"};
        LazyFn<ssize_t, int, void*, size_t> read = {"read"};
        LazyFn<long, long, void*> syscall = {"syscall"};
        LazyFn<int, int, int, int> socket = {"socket"};
        LazyFn<ssize_t, int, const void*, size_t> write = {"write"};
    }
}