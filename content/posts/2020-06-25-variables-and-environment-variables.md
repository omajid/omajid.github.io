+++
title = "Variables and Environment Variables In Bash"
date = "2020-06-25T00:58:07-04:00"
categories = [ "unix" ]
tags = [ "linux", "unix", "bash", ]
+++

Most programming languages make heavy use of ordinary variables. They
also (generally) support using environment variables.

Shells like `bash` - also heavily used for writing shell scripts -
have a slightly different audience in mind than normal programming
languages. They make heavy use of environment variables. So much so
that it can sometimes become blurry whether something is a normal
variable or an environment variable.

In this post, I will dig into variables and environment variables in
shell, particularly `bash`, to help you understand how to distinguish
the two and when to use them.

I am going to assume you have a little bit of experience with `bash`
and understand what a basic shell command like `cat file.txt` does.

Lets get started.

## Creating and using variables

Like pretty much any other programming language, shells support
variables. A variable is basically a value that has a name. It is
local to the running program. Variables can be local to `bash`
functions or global to the entire `bash` script.

Defining a variable is easy in `bash`:

```bash
variable=value
```

Leaving out the value defines a variable with a blank value:

```bash
variable=
```

The spacing is very important in defining and setting the values of
variable. `bash` scripts are both scripts but also valid commands for
the shell. Adding a space will result in an error or do something that
you might not expect at first:

```bash
# this runs the program `var` with the argument `=value`
var =value

# this runs the program `var` with 2 arguments: `=` and `value`
var = value

# this will make more sense later, but it runs the program `value`!
var= value
```

To access a variable, use a dollar sign (`$`). `echo` is great for
seeing the result of the variable:

```bash
variable=value
echo $variable
```

You can mix variables and your own text freely:

```bash
name=John
echo Hello $name
```

You can use `${` and `}` to specify where a variable name starts and
ends. For example, lets say you want to show the file `readme_2020.txt`:

```bash
filename=readme
cat ${filename}_2020.txt
```

The underscore (`_`) is a valid part of a variable name. If you were
to write this as `cat $filename_2020.txt`, `bash` would understand
this as a single variable named `filename_2020`. It would treat it as
if you had written `cat ${filename_2020}.txt`.

Using the `${name}` notation also lets us perform a number of actions,
such as doing a regular expression replace. The [Bash Hackers
Wiki](https://wiki.bash-hackers.org/) has [a great reference on what
these difference types of these actions
are](https://wiki.bash-hackers.org/syntax/pe)

The variables you have seen till now have been simple pieces of text.
Both the name and the value were simple text strings. Each variable
had a single value.

`bash` supports additional types of variables, such as array and
integers.

`bash` lets us define arrays using the array notation.

```bash
array=(value1 value2)
```

However, for some other types of variables, such as integers and
read-only (also known as constant) variables, we have to `declare` the
type first.

## Using declare to customize variables

We can also customize the type of a variable using the `declare` built
in. The syntax is `declare [OPTION] variable_name[=value]`, where both
the option and the value are optional.

```bash
# declare a normal variable
declare variable

# declare an array named days_of_week
declare -a days_of_week

# declare that the variable ten has the read-only value 10
declare -r ten=10
```

However, `declare` is often optional. You can just define the value
and `declare` is only needed if the value would normally be understood
as something different.

For example, you can just create an array using the array notation
without having to declare it.

```bash
days_of_week=(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)

echo The first day of the week is ${days_of_week[0]}
```

## Using special and built-in variables

`bash` also has several built-in and special variables. They allow us to
do a few cool things like access the arguments of a running shell
script, the process id of the current script, and access the exit code
of the last command we used. Here are some examples:

```bash
echo The name of this script is $0
echo The process id of this script is $$
```

The [Bash Hackers Wiki has a
great guide covering all the special and built in
variables](https://wiki.bash-hackers.org/syntax/shellvars)

## Understanding, creating and using environment variables

Environment variables are a way to specify the *environment* in which
a program is running. They are useful for providing a way to customize
how a process behaves. For example, [The 12 Factor
App](https://12factor.net/config) guidelines require that all
configuration for a program to be specified via environment variable.

Environment variable are simple key and values containing some data.
It is not possible to have the more complex data types that are
available for normal variables.

Unlike variables which are a part of the currently running shell
script (or program), the environment is part of the process tree. Each
process has its own copy of the environment.

There are some basic properties that define how the environment (and
environment variables) behaves. These properties apply to all
processes, including programs, shell scripts and interactive shell
sessions:

- Each process starts with an environment that is a copy of its parent
  process's environment, by default.

- A parent process can specify and customize the environment of a
  process it is spawning.

- Each process can modify its own environment.

That's about it. There are several implications of these rules:

- No process can modify the environment of any other process after
  that other process has been created.

- The only way a process can modify the environment of another process
  is before creating that other process itself.

- A program created by the shell can not modify the environment of the
  shell.

To make an environment variable in `bash` you have to use the `export`
builtin:

```bash
export ENV_VAR
```

That creates and defines the environment variable `ENV_VAR`.

If you have paid attention to the properties above, you might have
realized to figure out that `export` can't be a separate program that
the shell spawns and runs. If it was, `export` couldn't modify the
environment variables of the process that created it.

`export` is actually a built-in in shells like `bash`. `bash` itself
understands the meaning of `export` and modifies its own environment
variables.

It's common convention to use lowercase for normal variables and
uppercase for environment variables. But it's not required. You can
use uppercase for variables and lowercase for environment variables.

You can give an environment variable a value after defining it:

```bash
export ENV_VAR
ENV_VAR=value
```

You can also create and assign a value at the same time:

```bash
export ENV_VAR=value
```

The only difference in how normal variables and environment variables
are defined is the presence of the `export` keyword.

Environment variables are used exactly like normal variables: via
`$NAME` or `${NAME}`. There's no difference between them. The only way
to find out if a variable is a normal variable or an environment
variable is by checking how it was defined (preferred) or through
specialized command like `env` (not a great idea).

Modifying a variable (if it's not read-only) or environment variable
doesn't change it's type.

Re-`export`ing an environment variable has no impact.

```bash
# PATH and $HOME are common and well known environment variable
export PATH=$PATH:$HOME/bin

# same as above
PATH=$PATH:$HOME/bin
```

This is why you will often see shell configuration asking to add
things to your `~/.profile` file and use snippets like this:

```bash
# PATH is already a well known and already-initialized environment variable
# No need to export it
PATH=$PATH:$HOME/path/where/you/installed/program

# This is a new environment variable
# It needs to be exported
export DOTNET_ROOT=$HOME/path/where/you/installed/program
```

If the `DOTNET_ROOT` environment variable was not `export`ed, it would
be initialized as a normal variable within the shell and not be made
available to other programs that are looking for this environment
variable.

You can also set environment variables for a single command by passing
the environment variable names and values just before the command
name.

```bash
ENV_VAR=VALUE program
```

This sets the environment variable `ENV_VAR` to the value `VALUE` only
for the `program`.

The syntax is like this:

```bash
var1=value1 [var2=value2 var3=value3 ...] command
```

A common style used in compiling code is something like this:

```bash
CC=gcc make
```

This runs `make` with the environment variable `CC` set to the value
`gcc`. In turn, `make` understands this to mean that `make` should use
`gcc` as the c compiler.

Let's go back to the example we saw earlier in the section about
defining variables (not environment variables) with extra spaces.

```bash
var= value
```

You can now see that why this runs the program `value` with the
*environment variable* `var` set to the empty value.

## Summary

You should now have a really good idea about what bash variables and
environment variables are, how they differ, and when you might want to
use them.

This post was inspired by [this StackOverflow
question](https://stackoverflow.com/q/62502977/3561275)
