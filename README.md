# Dotfiles

## Packages

System initialization begins with package installation.

Differing types of packages are defined in _install_ files, which are simply package names optionally followed by comments beginning with `#`.
Currently, only the following types of packages are supported:

- `install_asdf`: [asdf plugins](https://asdf-vm.com/)
- `install_apt`: Aptitude packages
- `install_cargo`: [Rust Cargo packages](https://crates.io/)
- `install_snap`: [Snap packages](https://snapcraft.io/store)

Beneath the covers, a simple bash function parses these files truncating comments and producing a space seperated string of pacakges.

For example

```shell
# Example install_apt
ansible     # https://www.ansible.com/ Automate deployment, configuration, and upgrading
awscli      # https://aws.amazon.com/cli/ Official Amazon AWS command-line interface
example  --args
...
```

is parsed to

```
 ansible awscli example --args ...
```

## TODO

- Automate [Poetry](https://python-poetry.org/) install

## References

- https://github.com/Airblader/i3
- https://launchpad.net/~kgilmer/+archive/ubuntu/speed-ricer