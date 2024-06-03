# TherapyServer

Some tiny tiny medical chatbots (called TPGs) that can be accessed via TCP. Inspired by ELIZA and the like. They implement very bare bones language parsing (perhaps an overstatement). The UIs, bots and some comments are written in German.

[![asciicast](https://asciinema.org/a/DIFk5j3GX5WH4qsHvJ5i6cyxy.svg)](https://asciinema.org/a/DIFk5j3GX5WH4qsHvJ5i6cyxy)

## Usage
```
# Before all of this, install Elixir

iex -S mix # Fire up, server should start out of the box

# In a different shell:
netcat localhost 1234
```

