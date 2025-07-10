{ pkgs, ... }:
{
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

    # NOTE: Necessary for clang-format to always have same config/formatting rules, etc. everywhere
    home.file.".clang-format".text = ''
        BasedOnStyle: LLVM
        UseTab: Never
        IndentWidth: 4
        TabWidth: 4
        BreakBeforeBraces: Attach
        IndentCaseLabels: true
        ColumnLimit: 80
        AccessModifierOffset: -4
        NamespaceIndentation: All
        FixNamespaceComments: false
        PointerAlignment: Left
        AlignConsecutiveAssignments:
          Enabled: true
          AcrossEmptyLines: true
          AcrossComments: false
        AlignConsecutiveBitFields:
          Enabled: true
          AcrossEmptyLines: true
          AcrossComments: false
          AlignCompound: true
        AlignAfterOpenBracket: BlockIndent
        AllowAllArgumentsOnNextLine: false
        AllowAllParametersOfDeclarationOnNextLine: false
        BinPackParameters: false
        AllowShortBlocksOnASingleLine: Empty
        AllowShortCaseExpressionOnASingleLine: true
        AllowShortCompoundRequirementOnASingleLine: true
        AllowShortEnumsOnASingleLine: true
        AllowShortFunctionsOnASingleLine: Empty
        AllowShortIfStatementsOnASingleLine: AllIfsAndElse
        AllowShortLambdasOnASingleLine: All
        AllowShortLoopsOnASingleLine: true
    '';
}
