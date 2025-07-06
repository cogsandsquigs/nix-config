{pkgs, ...}: {
    home.packages = with pkgs; [
        # NOTE: Using LLVM v20 for C/C++ development
        bear
        cmake
        llvmPackages_20.clang
        llvmPackages_20.clang-tools
        clang-analyzer # Not in LLVM pkgs :/
        platformio # hardware stuffs
        pkg-config
        # valgrind # Memory profiler/debugger # NOTE: Currently broken :/
    ];
}
