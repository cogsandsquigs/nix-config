{ pkgs, ... }: {
    # NOTE: Using LLVM v21 for C/C++ development
    pkgs = with pkgs; [
        bear
        cmake
        llvmPackages_21.clang
        llvmPackages_21.clang-unwrapped.python # git-clang-format and other tools
        llvmPackages_21.clang-tools
        pkg-config
        # valgrind # Memory profiler/debugger -- currently broken
    ];

    lsp = [
        {
            name = "clangd";
            cmd = [ "clangd" ];
        }
    ];

    languages = {
        c.extensions = [ ".c" ];
        cpp.extensions = [
            ".cc"
            ".cpp"
            ".cxx"
            ".c++"
            ".C" # Capitalised variants are distinct extensions, not duplicates of .c/.h
            ".cppm"
            ".cu"
            ".ino"
            ".ii"
            ".ixx"
            ".h" # Ambiguous by nature; helix resolves it to cpp too, and clangd reads both
            ".hh"
            ".hpp"
            ".hxx"
            ".h++"
            ".H"
            ".cuh"
            ".ipp"
            ".tpp"
            ".txx"
            ".inl"
        ];
    };

    # A .clang-format config is waiting in ../_clang-format.yaml. The spec has no way to ship
    # a file into $HOME yet.
}
