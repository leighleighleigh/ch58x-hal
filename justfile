#default_example := "embassy-blinky"
default_example := "embassy-gpio"
default_cargo := "run --release --example " + default_example

[positional-arguments]
build:
  #!/usr/bin/env bash
  cargo {{default_cargo}} "$@"
