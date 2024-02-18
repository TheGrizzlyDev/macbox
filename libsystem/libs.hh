#pragma once
#include <cstddef>
#include <cstdarg>
#include <dlfcn.h>

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
        LazyFn<char*, char*, size_t> getcwd = {"getcwd"};
        LazyFn<long, long, void*> syscall = {"syscall"};
    }
}