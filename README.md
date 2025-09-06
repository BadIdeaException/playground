# playground

`playground` is a command-line tool to quickly create and otherwise manage playgrounds - throwaway coding environments to isolate bugs, try proof of concepts, or try out ideas.

## Installation

## Usage

This tool puts all playgrounds into a directory called `playgrounds`, called a _location_. When called, it will look for the nearest location according to the following rules:

- If the current directory is called `playgrounds`, the location is the current directory.
- If the current directory directly contains a directory called `playgrounds`, the location is that directory.
- Otherwise, move up one level and repeat.


### `playground new NAME`

Creates a new playground with the provided name. Playground names must be valid Unix filenames. They must not contain `/`, `?`, `*`, and in addition may not start with a `.`. Playground names may not contain interpolation sequences (`{{ }}`, see below).

Playgrounds are created from templates. During creation, all files in the template's directory are copied into the new playground. Symlinks pointing inside the template directory are changed after copy so they point inside the new playground. If no template is given, the default template is used.

File names and file contents may contain _interpolation sequences_: identifiers enclosed between `{{` and `}}`. There may be an arbitrary amount of whitespace between the double braces and the actual identifier. Identifiers are replaces with values as follows:

Identifier | Value
-|-
`playground` | The name of the new playground
`template` | The name of the template used to create the playground

Options:

Option | Meaning
-|-
`--template=TEMPLATE` (`-t TEMPLATE`) | The name of the template to use. If not given, the default template is used.

### `playground list`

Lists all playgrounds in this location.

Options:

_None_

### `playground raze NAME`

Permanently deletes the playground with the given name.

Options:

_None_

### `playground help COMMAND`

Shows instructions about the use of the specified command. If no command is specified, gives an overview of all commands.

Options: 

_None_