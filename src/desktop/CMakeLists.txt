cmake_minimum_required(VERSION 3.21)
project(NexoraShell VERSION 0.1.0 LANGUAGES CXX)

include(GNUInstallDirs)
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick Network)
find_package(Qt6 6.4 QUIET COMPONENTS Test)

qt_standard_project_setup()

qt_add_executable(nexora-shell
    main.cpp
    AssistantBackend.cpp
    AssistantBackend.hpp
    SoftwareCenterBackend.cpp
    SoftwareCenterBackend.hpp
    SystemMonitorBackend.cpp
    SystemMonitorBackend.hpp
    TerminalBackend.cpp
    TerminalBackend.hpp
    CodeEditorBackend.cpp
    CodeEditorBackend.hpp
    ImageEditorBackend.cpp
    ImageEditorBackend.hpp
    ImagePreviewProvider.cpp
    ImagePreviewProvider.hpp
)

target_compile_features(nexora-shell PRIVATE cxx_std_17)
target_compile_definitions(nexora-shell PRIVATE
    NEXORA_DEFAULT_QML_PATH="${CMAKE_INSTALL_FULL_DATADIR}/nexora/src/desktop/NexoraShell.qml"
)
target_link_libraries(nexora-shell PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
)

if(TARGET Qt6::Test)
    enable_testing()
    add_executable(tst-terminal-backend
        TerminalBackend.cpp
        TerminalBackend.hpp
        "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/cpp/tst_terminalbackend.cpp"
    )
    target_compile_features(tst-terminal-backend PRIVATE cxx_std_17)
    target_include_directories(tst-terminal-backend PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(tst-terminal-backend PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME terminal-backend COMMAND tst-terminal-backend)

    add_executable(tst-code-editor-backend
        CodeEditorBackend.cpp
        CodeEditorBackend.hpp
        "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/cpp/tst_codeeditorbackend.cpp"
    )
    target_compile_features(tst-code-editor-backend PRIVATE cxx_std_17)
    target_include_directories(tst-code-editor-backend PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(tst-code-editor-backend PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME code-editor-backend COMMAND tst-code-editor-backend)

    add_executable(tst-image-editor-backend
        ImageEditorBackend.cpp
        ImageEditorBackend.hpp
        ImagePreviewProvider.cpp
        ImagePreviewProvider.hpp
        "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/cpp/tst_imageeditorbackend.cpp"
    )
    target_compile_features(tst-image-editor-backend PRIVATE cxx_std_17)
    target_include_directories(tst-image-editor-backend PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(tst-image-editor-backend PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Test)
    add_test(NAME image-editor-backend COMMAND tst-image-editor-backend)

    add_executable(tst-software-center-backend
        SoftwareCenterBackend.cpp
        SoftwareCenterBackend.hpp
        "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/cpp/tst_softwarecenterbackend.cpp"
    )
    target_compile_features(tst-software-center-backend PRIVATE cxx_std_17)
    target_include_directories(tst-software-center-backend PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(tst-software-center-backend PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME software-center-backend COMMAND tst-software-center-backend)

    add_executable(tst-system-monitor-backend
        SystemMonitorBackend.cpp
        SystemMonitorBackend.hpp
        "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/cpp/tst_systemmonitorbackend.cpp"
    )
    target_compile_features(tst-system-monitor-backend PRIVATE cxx_std_17)
    target_include_directories(tst-system-monitor-backend PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(tst-system-monitor-backend PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME system-monitor-backend COMMAND tst-system-monitor-backend)

    add_executable(tst-assistant-backend
        AssistantBackend.cpp
        AssistantBackend.hpp
        "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/cpp/tst_assistantbackend.cpp"
    )
    target_compile_features(tst-assistant-backend PRIVATE cxx_std_17)
    target_include_directories(tst-assistant-backend PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(tst-assistant-backend PRIVATE Qt6::Core Qt6::Network Qt6::Test)
    add_test(NAME assistant-backend COMMAND tst-assistant-backend)
endif()

install(TARGETS nexora-shell
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)
install(FILES NexoraShell.qml WindowCard.qml
    DESTINATION "${CMAKE_INSTALL_DATADIR}/nexora/src/desktop"
)
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../apps/"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/nexora/src/apps"
    FILES_MATCHING PATTERN "*.qml" PATTERN "*.js"
)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../../assets/branding/nexora-grub-mark.png"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/nexora/assets/branding"
)
