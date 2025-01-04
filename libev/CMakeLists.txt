cmake_minimum_required(VERSION 3.30)

project(ev VERSION 4.33
    DESCRIPTION "libev is a high-performance event loop/event model with lots of features."
    HOMEPAGE_URL "http://software.schmorp.de/pkg/libev"
    LANGUAGES C
)

option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_STATIC_LIBS "Build static libraries" ON)
option(DEFAULT_LIBRARY "Default library type" SHARED)
set_property(CACHE DEFAULT_LIBRARY PROPERTY STRINGS SHARED STATIC)

set(ev_sources
    "ev.c"
    "event.c"
)

set(ev_headers
    "ev++.h"
    "ev.h"
    "event.h"
)

set(ev_pod
    "ev.pod"
)

set(system_headers
    "stdio.h"
    "stdlib.h"
    "string.h"
    "inttypes.h"
    "stdint.h"
    "strings.h"
    "sys/stat.h"
    "sys/types.h "
    "unistd.h"
    "dlfcn.h"
    "sys/inotify.h"
    "sys/epoll.h"
    "sys/event.h"
    "port.h"
    "poll.h"
    "sys/timerfd.h"
    "sys/select.h"
    "sys/eventfd.h"
    "sys/signalfd.h"
    "linux/aio_abi.h"
    "linux/fs.h"
)

set(system_funcs
    "inotify_init"
    "epoll_ctl"
    "kqueue"
    "port_create"
    "poll"
    "select"
    "eventfd"
    "signalfd"
)

include(CheckIncludeFile)
include(CheckFunctionExists)
include(CheckTypeSize)

block()

foreach(h IN LISTS system_headers)
    string(TOUPPER ${h} have_macro_name)
    string(REPLACE "/" "_" have_macro_name ${have_macro_name})
    string(REPLACE "." "_" have_macro_name ${have_macro_name})
    string(CONCAT have_macro_name "HAVE_" ${have_macro_name})
    check_include_file(${h} ${have_macro_name})
endforeach()

endblock()

block()

foreach(f IN LISTS system_funcs)
    string(TOUPPER ${f} have_macro_name)
    string(CONCAT have_macro_name "HAVE_" ${have_macro_name})
    check_function_exists(${f} ${have_macro_name})
endforeach()

endblock()

block()

check_function_exists("clock_gettime" HAVE_CLOCK_GETTIME)

if(NOT HAVE_CLOCK_GETTIME)
    include(CheckSourceCompiles)
    set(clock_syscall_source
        "
        #include <unistd.h>
        #include <sys/syscall.h>
        #include <time.h>
        int main(void) {
            struct timespec ts;
            return syscall(SYS_clock_gettime, CLOCK_REALTIME, &ts);
            return 0;
        }
        "
    )
    check_source_compiles(C
        "${clock_syscall_source}"
        HAVE_CLOCK_SYSCALL)

    if(NOT HAVE_CLOCK_SYSCALL)
        find_library(LIBRT rt)

        if(LIBRT)
            set(CMAKE_REQUIRED_LIBRARIES ${LIBRT})
            check_function_exists("clock_gettime" HAVE_CLOCK_GETTIME)
        endif()
    endif()
endif()

endblock()

block()

check_function_exists("nanosleep" HAVE_NANOSLEEP)

if(NOT HAVE_NANOSLEEP)
    find_library(LIBRT rt)

    if(LIBRT)
        set(CMAKE_REQUIRED_LIBRARIES ${LIBRT})
        check_function_exists("nanosleep" HAVE_NANOSLEEP)
    endif()
endif()

endblock()

block()

find_library(MATH_LIBRARY m)

if(MATH_LIBRARY)
    set(CMAKE_REQUIRED_LIBRARIES ${MATH_LIBRARY})
endif()

check_function_exists("floor" HAVE_FLOOR)

endblock()

block()

set(CMAKE_EXTRA_INCLUDE_FILES "linux/fs.h")
check_type_size(" __kernel_rwf_t " KERNEL_RWF_T)

endblock()

set(CMAKE_INCLUDE_CURRENT_DIR ON)

add_library(ev_object OBJECT ${ev_sources})
target_compile_definitions(ev_object PRIVATE "HAVE_CONFIG_H")
target_link_libraries(ev_object PUBLIC ${LIBRT} ${MATH_LIBRARY})

if(NOT DEFINED CMAKE_POSITION_INDEPENDENT_CODE AND BUILD_SHARED_LIBS)
    set_target_properties(ev_object PROPERTIES POSITION_INDEPENDENT_CODE TRUE)
endif()

if(BUILD_SHARED_LIBS)
    add_library(ev_shared SHARED)
    target_sources(ev_shared PUBLIC FILE_SET HEADERS FILES ${ev_headers})
    target_link_libraries(ev_shared PUBLIC ev_object)
    set_target_properties(ev_shared PROPERTIES
        LIBRARY_OUTPUT_NAME ev
        VERSION 4.0.0
        SOVERSION ${PROJECT_VERSION_MAJOR}
    )
endif()

if(BUILD_STATIC_LIBS)
    add_library(ev_static STATIC)
    target_sources(ev_static PUBLIC FILE_SET HEADERS FILES ${ev_headers})
    target_link_libraries(ev_static PUBLIC ev_object)
    set_target_properties(ev_static PROPERTIES
        ARCHIVE_OUTPUT_NAME ev
    )
endif()

if(DEFAULT_LIBRARY STREQUAL "SHARED")
    add_library(ev ALIAS ev_shared)
else()
    add_library(ev ALIAS ev_static)
endif()

configure_file(config.h.cmake.in config.h)

install(TARGETS ev_shared ev_static
    FILE_SET HEADERS
)

find_program(pod2man_exe pod2man)

if(pod2man_exe)
    set(pod2man_command
        "${pod2man_exe}"
        "-n" "LIBEV"
        "-r" "libev-4.33"
        "-c" "libev - high performance full featured event loop"
        "-s3")
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/man3)
    add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/man3/ev.3
        COMMAND ${pod2man_command} <"${CMAKE_CURRENT_SOURCE_DIR}/${ev_pod}" >"${CMAKE_BINARY_DIR}/man3/ev.3"
        DEPENDS ${ev_pod}
        COMMENT "Generating ev.3"
    )
    add_custom_target(manpage ALL DEPENDS ${CMAKE_BINARY_DIR}/man3/ev.3)
    install(DIRECTORY ${CMAKE_BINARY_DIR}/man3
        TYPE MAN
        FILE_PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
        DIRECTORY_PERMISSIONS OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )
endif()
