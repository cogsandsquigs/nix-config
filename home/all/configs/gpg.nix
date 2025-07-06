{...}: {
    programs.gpg = {
        enable = true;

        settings = {
            use-agent = true;
            no-tty = true;
        };
    };
}
