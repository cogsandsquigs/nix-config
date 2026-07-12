{ pkgs, ... }: {
    lang = [ "c" "cpp" ];

    # NOTE: Using LLVM v21 for C/C++ development
    pkgs = with pkgs; [
        bear
        cmake
        llvmPackages_21.clang
        llvmPackages_21.clang-unwrapped.python # git-clang-format and other tools
        llvmPackages_21.clang-tools
        pkg-config
        # valgrind # Memory profiler/debugger — currently broken
    ];

    # TODO: home.file.".clang-format" — deploy the clang-format config file.
    # Previously in the old-format module; needs a mechanism in the spec (e.g. a `files` field)
    # or a separate home-manager module. Config was:
    #
    #   BasedOnStyle: LLVM
    #   UseTab: Never
    #   IndentWidth: 4
    #   TabWidth: 4
    #   BreakBeforeBraces: Attach
    #   IndentCaseLabels: true
    #   ColumnLimit: 80
    #   AccessModifierOffset: -4
    #   NamespaceIndentation: All
    #   FixNamespaceComments: false
    #   PointerAlignment: Left
    #   AlignConsecutiveAssignments:
    #     Enabled: true
    #     AcrossEmptyLines: true
    #     AcrossComments: false
    #   AlignConsecutiveBitFields:
    #     Enabled: true
    #     AcrossEmptyLines: true
    #     AcrossComments: false
    #     AlignCompound: true
    #   AlignAfterOpenBracket: BlockIndent
    #   AllowAllArgumentsOnNextLine: false
    #   AllowAllParametersOfDeclarationOnNextLine: false
    #   BinPackParameters: false
    #   AllowShortBlocksOnASingleLine: Empty
    #   AllowShortCaseExpressionOnASingleLine: true
    #   AllowShortCompoundRequirementOnASingleLine: true
    #   AllowShortEnumsOnASingleLine: true
    #   AllowShortFunctionsOnASingleLine: Empty
    #   AllowShortIfStatementsOnASingleLine: AllIfsAndElse
    #   AllowShortLambdasOnASingleLine: All
    #   AllowShortLoopsOnASingleLine: true
}
