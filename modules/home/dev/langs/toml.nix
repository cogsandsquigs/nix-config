{ pkgs, ... }: {
  lang = [ "toml" ];

  pkgs = with pkgs; [ taplo ];

  fmt = [
    "taplo"
    "fmt"
    "-o=align_entries=true"
    "-o=align-comments"
    "-o=allowed_blank_lines=1"
    "-o=indent_entries=true"
    "-o=indent_tables=true"
    "-o=indent_string=    "
    "-o=reorder_arrays=false"
    "-o=reorder_keys=true"
    "-"
  ];
}
