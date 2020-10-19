if get_option('shared_lib')
  libtype = 'shared_library'
else
  libtype = 'static_library'
endif

libwriteas_sources = [
  'Writeas.vala'
]


confh = configuration_data ()
confh.set_quoted('PACKAGE_LOCALE_DIR', join_paths(get_option('prefix'), get_option('datadir'), 'locale'))
confh.set_quoted('GETTEXT_PACKAGE', 'writeas')
confh.set_quoted('VERSION', meson.project_version())
configure_file(output : 'config.h',
  configuration : confh)

inc_libh = include_directories ('.')
inc_libh_dep = declare_dependency (include_directories : inc_libh)

libwriteas = build_target('writeas',
    sources: libwriteas_sources,
    dependencies: libwriteas_deps,
    vala_args: [
        '--pkg=posix',
        '--vapidir=' + meson.source_root() + '/vapi'
        ],
    target_type: libtype,
    vala_header: 'writeas.h',
    vala_vapi: 'writeas.vapi',
    c_args: [ '-include', meson.current_build_dir() + '/config.h', '-w'],
    install_dir: [true, true, true],
    install: true,
)

libwriteas_dep = declare_dependency(
  include_directories: include_directories('.'),
            link_with: libwriteas,
)

pkg = import('pkgconfig')
pkg.generate(
    libraries: libwriteas,
      version: meson.project_version(),
         name: 'writeas',
  description: 'Publish to Write.as.',
)
