cmake_minimum_required( VERSION 3.1 )

project( LinuxOpenGL )

set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_INSTALL OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

add_subdirectory( dependencies/glfw )
add_subdirectory( dependencies/glad )
add_subdirectory( dependencies/glm )

set( source Main.cpp )
     
add_executable( LinuxOpenGL ${source} )
target_link_libraries( LinuxOpenGL glfw glad glm)