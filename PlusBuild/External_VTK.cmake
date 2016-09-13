IF(VTK_DIR)
  # VTK has been built already
  FIND_PACKAGE(VTK 7.0.0 REQUIRED PATHS ${VTK_DIR} NO_DEFAULT_PATH)

  MESSAGE(STATUS "Using VTK available at: ${VTK_DIR}")

  # Copy libraries to PLUS_EXECUTABLE_OUTPUT_PATH
  FOREACH(lib ${VTK_LIBRARIES})
    IF(NOT TARGET ${lib})
      continue()
    ENDIF()

    GET_TARGET_PROPERTY(LIB_TYPE ${lib} TYPE)

    IF(NOT ${LIB_TYPE} STREQUAL "INTERFACE_LIBRARY")
      GET_TARGET_PROPERTY(VTK_DEBUG_FILE ${lib} IMPORTED_LOCATION_DEBUG)
      GET_TARGET_PROPERTY(VTK_RELEASE_FILE ${lib} IMPORTED_LOCATION_RELEASE)

      IF ( ${CMAKE_GENERATOR} MATCHES "Visual Studio" OR ${CMAKE_GENERATOR} MATCHES "Xcode" )
        IF( EXISTS ${VTK_RELEASE_FILE} )
          FILE(COPY ${VTK_RELEASE_FILE} DESTINATION ${PLUS_EXECUTABLE_OUTPUT_PATH}/Release)
        ENDIF()
        IF( EXISTS ${VTK_DEBUG_FILE} )
          FILE(COPY ${VTK_DEBUG_FILE} DESTINATION ${PLUS_EXECUTABLE_OUTPUT_PATH}/Debug)
        ENDIF()
      ELSE()
        IF( VTK_DEBUG_FILE EQUAL VTK_RELEASE_FILE AND EXISTS ${VTK_RELEASE_FILE})
          FILE(COPY ${VTK_RELEASE_FILE} DESTINATION ${PLUS_EXECUTABLE_OUTPUT_PATH})
        ELSE()
          IF( EXISTS ${VTK_RELEASE_FILE} )
            FILE(COPY ${VTK_RELEASE_FILE} DESTINATION ${PLUS_EXECUTABLE_OUTPUT_PATH})
          ENDIF()
          IF( EXISTS ${VTK_DEBUG_FILE} )
            FILE(COPY ${VTK_DEBUG_FILE} DESTINATION ${PLUS_EXECUTABLE_OUTPUT_PATH})
          ENDIF()
        ENDIF()
      ENDIF()
    ENDIF()
  ENDFOREACH()

  SET (PLUS_VTK_DIR "${VTK_DIR}" CACHE INTERNAL "Path to store vtk binaries")

  IF(PLUSBUILD_BUILD_PLUSAPP AND NOT TARGET vtkGUISupportQt)
    MESSAGE( SEND_ERROR "You have to build VTK with VTK_USE_QT flag ON if you need to use PLUSBUILD_BUILD_PLUSAPP.")
  ENDIF()

ELSE(VTK_DIR)

  # VTK has not been built yet, so download and build it as an external project
  SET(VTK_GIT_PROTOCOL https)

  SET(VTK_GIT_REPOSITORY "gitlab.kitware.com/vtk/vtk.git")
  SET(VTK_GIT_TAG "v7.0.0")
  SET(VTK_GIT_PROTOCOL https)

  IF( PLUSBUILD_BUILD_PLUSAPP )
    SET(VTK_VERSION_SPECIFIC_ARGS ${VTK_VERSION_SPECIFIC_ARGS}
      -DVTK_Group_Qt:BOOL=ON
      )
  ENDIF()

  SET(VTK_VERSION_SPECIFIC_ARGS ${VTK_VERSION_SPECIFIC_ARGS}
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY:STRING=${PLUS_EXECUTABLE_OUTPUT_PATH}
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:STRING=${PLUS_EXECUTABLE_OUTPUT_PATH}
    )

  IF(APPLE)
    SET(VTK_QT_ARGS ${VTK_QT_ARGS}
      -DVTK_USE_CARBON:BOOL=OFF
      -DVTK_USE_COCOA:BOOL=ON # Default to Cocoa, VTK/CMakeLists.txt will enable Carbon and disable cocoa if needed
      -DVTK_USE_X:BOOL=OFF
      )
  ENDIF()

  IF(PLUSBUILD_USE_Tesseract)
    SET(VTK_VERSION_SPECIFIC_ARGS ${VTK_VERSION_SPECIFIC_ARGS}
      -DModule_vtkzlib:INTERNAL=ON
      )
  ENDIF()
  
  IF(MSVC)
    SET(VTK_VERSION_SPECIFIC_ARGS ${VTK_VERSION_SPECIFIC_ARGS}
      -DCMAKE_CXX_MP_FLAG:BOOL=ON
      )
  ENDIF()
  
  MESSAGE(STATUS "Downloading VTK ${VTK_GIT_TAG} from: ${VTK_GIT_PROTOCOL}://${VTK_GIT_REPOSITORY}")

  SET (PLUS_VTK_SRC_DIR "${CMAKE_BINARY_DIR}/Deps/vtk")
  SET (PLUS_VTK_DIR "${CMAKE_BINARY_DIR}/Deps/vtk-bin" CACHE INTERNAL "Path to store vtk binaries")

  ExternalProject_Add( vtk
    "${PLUSBUILD_EXTERNAL_PROJECT_CUSTOM_COMMANDS}"
    PREFIX "${CMAKE_BINARY_DIR}/Deps/vtk-prefix"
    SOURCE_DIR "${PLUS_VTK_SRC_DIR}"
    BINARY_DIR "${PLUS_VTK_DIR}"
    #--Download step--------------
    GIT_REPOSITORY "${VTK_GIT_PROTOCOL}://${VTK_GIT_REPOSITORY}"
    GIT_TAG ${VTK_GIT_TAG}
    #--Configure step-------------
    CMAKE_ARGS 
        ${ep_common_args}
        ${ep_qt_args}
        ${VTK_VERSION_SPECIFIC_ARGS}
        -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS} 
        -DBUILD_TESTING:BOOL=OFF 
        -DBUILD_EXAMPLES:BOOL=OFF
        -DCMAKE_CXX_FLAGS:STRING=${ep_common_cxx_flags}
        -DCMAKE_C_FLAGS:STRING=${ep_common_c_flags}
        -DVTK_SMP_IMPLEMENTATION_TYPE:STRING="OpenMP"
        -DVTK_QT_VERSION:STRING=${QT_VERSION_MAJOR}
        -DVTK_WRAP_PYTHON:BOOL=OFF
        -DVTK_RENDERING_BACKEND=${PLUSBUILD_VTK_RENDERING_BACKEND}
    #--Build step-----------------
    BUILD_ALWAYS 1
    #--Install step-----------------
    INSTALL_COMMAND ""
    DEPENDS ${VTK_DEPENDENCIES}
    )

ENDIF(VTK_DIR)
