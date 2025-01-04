project(
    'libev',
    'c',
    version: '4.33',
    default_options: {'warning_level': '0'},
)

sources = files(
    'ev.c',
    'event.c',
)
headers = files(
    'ev++.h',
    'ev.h',
    'event.h',
)
man_source = files('ev.pod')

system_headers = [
    'stdio.h',
    'stdlib.h',
    'string.h',
    'inttypes.h',
    'stdint.h',
    'strings.h',
    'sys/stat.h',
    'sys/types.h',
    'unistd.h',
    'dlfcn.h',
    'sys/inotify.h',
    'sys/epoll.h',
    'sys/event.h',
    'port.h',
    'poll.h',
    'sys/timerfd.h',
    'sys/select.h',
    'sys/eventfd.h',
    'sys/signalfd.h',
    'linux/aio_abi.h',
    'linux/fs.h',
]
system_funcs = [
    'inotify_init',
    'epoll_ctl',
    'kqueue',
    'port_create',
    'poll',
    'select',
    'eventfd',
    'signalfd',
]

cc = meson.get_compiler('c')
rtlib_found = false
link_libraries = []
conf_data = configuration_data()

foreach h : system_headers
    have_macro_name = 'HAVE_' + h.to_upper().underscorify()
    header_found = cc.has_header(h)
    if header_found
        conf_data.set10(
            have_macro_name,
            true,
            description: 'Define to 1 if you have the <' + h + '> header file.',
        )
    endif
endforeach

foreach f : system_funcs
    have_func_name = 'HAVE_' + f.to_upper().underscorify()
    func_found = cc.has_function(f)
    if func_found
        conf_data.set10(
            have_func_name,
            true,
            description: 'Define to 1 if you have the \'' + f + '\' function.',
        )
    endif
endforeach

if cc.has_type('__kernel_rwf_t', prefix: '#include <linux/fs.h>')
    conf_data.set10(
        'HAVE_KERNEL_RWF_T',
        true,
        description: 'Define to 1 if linux/fs.h defined kernel_rwf_t.',
    )
endif

clock_gettime_found = false
if cc.has_function('clock_gettime')
    clock_gettime_found = true
else
    clock_syscall_source = '''
        #include <unistd.h>
        #include <sys/syscall.h>
        #include <time.h>
        int main(void) {
            struct timespec ts;
            return syscall(SYS_clock_gettime, CLOCK_REALTIME, &ts);
            return 0;
        }
        '''

    if cc.links(clock_syscall_source, name: 'clock_gettime')
        conf_data.set10(
            'HAVE_CLOCK_SYSCALL',
            true,
            description: 'Define to 1 to use the syscall interface for clock_gettime.',
        )
    else
        rtlib = cc.find_library('rt', required: false)
        if rtlib.found()
            rtlib_found = true

            if cc.has_function('clock_gettime', dependencies: rtlib)
                link_libraries += rtlib
                clock_gettime_found = true
            endif
        endif
    endif
endif

if clock_gettime_found
    conf_data.set10(
        'HAVE_CLOCK_GETTIME',
        true,
        description: 'Define to 1 if you have the \'clock_gettime\' function.',
    )
endif

nanosleep_found = false
if cc.has_function('nanosleep')
    nanosleep_found = true
else
    if not rtlib_found
        rtlib = cc.find_library('rt', required: false)
    endif

    if rtlib.found()
        rtlib_found = true

        if cc.has_function('nanosleep', dependencies: rtlib)
            link_libraries += rtlib
            nanosleep_found = true
        endif
    endif
endif

if nanosleep_found
    conf_data.set10(
        'HAVE_NANOSLEEP',
        true,
        description: 'Define to 1 if you have the \'nanosleep\' function.',
    )
endif

if rtlib_found
    conf_data.set10(
        'HAVE_LIBRT',
        true,
        description: 'Define to 1 if you have the \'rt\' library (-lrt).',
    )
endif

link_libraries += cc.find_library('m', required: false)
if cc.has_function('floor', dependencies: link_libraries)
    conf_data.set10(
        'HAVE_FLOOR',
        true,
        description: 'Define to 1 if the floor function is available.',
    )
endif

configure_file(output: 'config.h', configuration: conf_data)
add_project_arguments('-DHAVE_CONFIG_H', language: 'c')

libev = both_libraries(
    'ev',
    sources: sources,
    version: '4.0.0',
    install: true,
    dependencies: link_libraries,
)

install_headers(headers)

pod2man_exe = find_program('pod2man', required: false)
if pod2man_exe.found()
    mandir = get_option('mandir')

    manpage_command = [
        pod2man_exe,
        '-n', 'LIBEV',
        '-r', 'libev-' + meson.project_version(),
        '-c', 'libev - high performance full featured event loop',
        '-s3',
    ]

    custom_target(
        'manpage',
        output: 'ev.3',
        input: man_source,
        command: manpage_command,
        feed: true,
        capture: true,
        install: true,
        install_dir: mandir / 'man3',
        install_mode: 'rw-r--r--',
        install_tag: 'docs',
    )
endif

ev_dep = declare_dependency(
    link_with: libev,
    include_directories: include_directories('.'),
)
